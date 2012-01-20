package CAP::Solr::Document;
use strict;
use warnings;
use Carp;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;
use WebService::Solr;
use CAP::Auth;
use CAP::Solr::Record;
use Digest::SHA1 qw(sha1_hex);
use URI::Escape;

# Properties from parameters passed to the constructor
has 'key'           => (is => 'ro', isa => 'Str', default => ""); # Document key to retrieve
has 'subset'        => (is => 'ro', isa => 'Str', default => ""); # Document must belong to this subset
has 'server'        => (is => 'ro', isa => 'Str', required => 1);
has 'options'       => (is => 'ro', isa => 'HashRef', default => sub{{}});
has 'doc'           => (is => 'ro', isa => 'WebService::Solr::Document');

# Properties generated at build time
has 'solr'          => (is => 'ro', isa => 'WebService::Solr', documentation => 'Solr webservice object'); 
has 'record'        => (is => 'ro', isa => 'CAP::Solr::Record', documentation => 'Access record fields via this object');
has 'child_count'   => (is => 'ro', isa => 'Int', default => 0, documentation => 'number of child records linked to this record');
has 'sibling_count' => (is => 'ro', isa => 'Int', default => 0, documentation => 'number of child records of the parent record');

# Properties generated by methods
has 'active_child'  => (is => 'ro', isa => 'CAP::Solr::Document');
has 'auth'          => (is => 'rw', isa => 'CAP::Auth');

method BUILD {
    # Create parent and child caches so we don't have to look up the same
    # record more than once.
    $self->{_parent_cache} = undef;
    $self->{_child_cache}  = {};

    $self->{solr} = new WebService::Solr($self->server);

    # If a document record is supplied, use it. Otherwise, look up the
    # supplied key in the database.
    if ($self->doc) {
        $self->{record} = new CAP::Solr::Record($self->doc);
        $self->{key} = $self->doc->value_for('key');;
    }
    elsif ($self->key) {
        # Fetch the requested document
        my $query = "key: " . $self->key;
        if ($self->subset) {
            $query .= ' AND ' . $self->subset;
        }
        my $response = $self->solr->search($query, $self->options);
        croak("Solr query failure") unless ($response->ok);
        croak("No such document") unless ($#{$response->docs} == 0);

        # This lets us access all fields as $self->record->fieldname.
        $self->{record} = new CAP::Solr::Record($response->docs->[0]);
    }
    else {
        croak("Attempt to create new Solr::Document without supplying a key or document");
    }

    # Count the number of child records. Page records should never have children.
    if ($self->record->type ne 'page') {
        $self->{child_count} = $self->solr->search("pkey:" . $self->key, { rows => 0 })->content->{response}->{numFound};
    }

    # Count the number of sibling records (including this one) if it
    # belongs to a parent record.
    if ($self->record->pkey) {
        $self->{sibling_count} = $self->solr->search("pkey:" . $self->record->pkey, { rows => 0 })->content->{response}->{numFound};
    }

    $self->{auth} = undef;
}

# Return the document for the parent object. Returns undef if
# there is no parent or there is a retrieval failure.
method parent {
    my $doc;
    return undef unless ($self->record->pkey);
    return $self->{_parent_cache} if ($self->{_parent_cache});
    eval { $doc = new CAP::Solr::Document({ key => $self->record->pkey, server => $self->server }) };

    # Check whether we got a value. Ignore parents that are not of the
    # right type for the document. (This will prevent circular references
    # and other invalid structures.)
    return undef if ($@);
    return undef if ($self->type_is('series'));
    return undef if ($self->type_is('document') && ! $doc->type_is('series'));
    return undef if ($self->type_is('page') && ! $doc->type_is('document'));

    return $self->{_parent_cache} = $doc;
}

# Return whether or not the document has a parent. Useful
# primarily for Template Toolkit.
method has_parent {
    return $self->parent() ? 1 : 0;
}

# Return the document for the $seq'th child object. Returns undef if
# there is no such child or there is a retrieval failure.
method child (Int $seq) {
    my $doc;
    return undef if ($seq > $self->child_count);
    return $self->{_child_cache}->{$seq} if ($self->{_child_cache}->{$seq});
    my $response = $self->solr->search("pkey:" . $self->key, { sort => 'seq asc', rows => 1, start => $seq - 1, fl => 'key' });
    eval { $doc = new CAP::Solr::Document({ key => $response->docs->[0]->value_for('key'), server => $self->server }) };

    # Check whether we got a value. Ignore children that are of the wrong
    # type, to prevent circular references and invalid structures.
    return undef if ($@);
    return undef if ($self->type_is('page'));
    return undef if ($self->type_is('document') && ! $doc->type_is('page'));
    return undef if ($self->type_is('series') && ! $doc->type_is('document'));

    return $self->{_child_cache}->{$seq} = $doc;
}

method set_active_child (Int $seq) {
    return $self->{active_child} = $self->child($seq);
}

method set_auth (Str $rules, $user) {
    $self->{auth} = new CAP::Auth(user => $user, rules => $rules, doc => $self);
    return $self->auth;
}

method canonical_label {
    return ($self->parent ? $self->parent->label . " : " : "") . $self->label;
}

method derivative_request (HashRef $content_config, HashRef $derivative_config, Int $seq, Str $filename, Str $size, Str $rotate, Str $format) {
    return [403, "Not authenticated."] unless $self->auth;

    my $child = $self->child($seq);
    return [400, "$self->key does not have page at seq $seq."] unless $child;
    return [403, "Not allowed to view this page."] unless $self->auth->page($seq);
    return [400, "$child->key does not have a canonical master."] unless $child->canonicalMaster;

    my $size_str = $derivative_config->{size}->{$size} || $derivative_config->{default_size};
    return [403, "Not allowed to resize this page."] unless ($size_str eq $derivative_config->{default_size} || $self->auth->resize);
    my $rotate_angle = $derivative_config->{rotate}->{$rotate} || "0";

    my $expires = $self->_expires();
    my $from = $child->canonicalMaster;
    my $signature = $self->_signature($content_config->{password}, $filename, $expires, $from, $size_str, $rotate_angle);

    my $params = [
        $self->_to_query('expires', $expires),
        $self->_to_query('signature', $signature),
        $self->_to_query('key', $content_config->{key}),
        $self->_to_query('from', $from),
        $self->_to_query('format', $format),
        $self->_to_query('size', $size_str),
        $self->_to_query('rotate', $rotate_angle),
    ];

    return [200, $self->_request_uri($content_config->{url}, $filename, $params)];
}

method download_request (HashRef $content_config) {
    return [403, "Not authenticated."] unless $self->auth;
    return [403, "Not allowed to download this resource."] unless $self->auth->download;
    return [400, "Document $self->key does not have a canonical download."] unless $self->canonicalDownload;
    
    my $expires = $self->_expires();
    my $filename = $self->canonicalDownload;
    my $signature = $self->_signature($content_config->{password}, $filename, $expires, "", "", "");

    my $params = [
        $self->_to_query('expires', $expires),
        $self->_to_query('signature', $signature),
        $self->_to_query('key', $content_config->{key}),
        $self->_to_query('file', $filename),
    ];
    
    return [200, $self->_request_uri($content_config->{url}, $filename, $params)];
}

method _expires {
    my $time = time() + 90000; # 25 hours in the future
    $time = $time - ($time % 86400); # normalize the expiry time to the closest 24 hour period
    return $time; # minimum 1 hour from now, maximum 25
}

method _signature (Str $password, Str $filename, Str $expires, Str $from, Str $size, Str $rotate) {
    return sha1_hex("$password\n$filename\n$expires\n$from\n$size\n$rotate");
}

method _to_query (Str $name, $value) {
    return $name . '=' . uri_escape($value);
}

method _request_uri (Str $content_url, Str $filename, ArrayRef $params) {
    return join('?', join('/', $content_url, $filename), join('&', @{$params}))
}

# Convenient accessors for fields used internally by cap so we can
# reference them as $self->fieldname rather than $self->record->fieldname
method canonicalDownload { return $self->record->canonicalDownload; }
method canonicalMaster   { return $self->record->canonicalMaster; }
method canonicalUri      { return $self->record->canonicalUri; }
method contributor       { return $self->record->contributor; }
method label             { return $self->record->label; }
method pkey              { return $self->record->pkey; }
method seq               { return $self->record->seq; }
method record_type       { return $self->record->type; }

method type_is (Str $type) {
    return 1 if ($self->record_type eq $type);
    return 0;
}

__PACKAGE__->meta->make_immutable;
