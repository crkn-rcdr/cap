package CAP::Solr::Document;
use strict;
use warnings;
use Carp;
use Moose;
use Moose::Util::TypeConstraints;
#use MooseX::Method::Signatures;
use namespace::autoclean;
use WebService::Solr;
use CAP::Solr::Record;

# Properties from parameters passed to the constructor
has 'key'           => (is => 'ro', isa => 'Str', required => 1);
has 'server'        => (is => 'ro', isa => 'Str', required => 1);

# Properties generated at build time
has 'solr'          => (is => 'ro', isa => 'WebService::Solr', documentation => 'Solr webservice object'); 
has 'record'        => (is => 'ro', isa => 'CAP::Solr::Record', documentation => 'Access record fields via this object');
has 'child_count'   => (is => 'ro', isa => 'Int', default => 0, documentation => 'number of child records linked to this record');
has 'sibling_count' => (is => 'ro', isa => 'Int', default => 0, documentation => 'number of child records of the parent record');
has 'struct'        => (is => 'ro', isa => 'HashRef', documentation => 'deserialized Perl hashref struct of the record; same info as in record');

# Settable properties
has 'active_child'  => (is => 'rw', isa => 'Int', default => 0);

sub BUILD {
    my $self = shift;

    # Create parent and child caches so we don't have to look up the same
    # record more than once.
    $self->{_parent_cache} = undef;
    $self->{_child_cache}  = {};

    $self->{_active_child} = undef;

    # Fetch the requested document
    $self->{solr} = new WebService::Solr($self->server);
    my $response = $self->solr->search("key:" . $self->key);
    croak("Solr query failure") unless ($response->ok);
    croak("No such document") unless ($#{$response->docs} == 0);

    # Stash the raw data structure away.
    $self->{struct} = $response->content->{response}->{docs}->[0];

    # This lets us access all fields as $self->record->fieldname.
    $self->{record} = new CAP::Solr::Record($response->docs->[0]);

    # Count the number of child records. Page records should never have children.
    if ($self->record->type ne 'page') {
        $self->{child_count} = $self->solr->search("pkey:" . $self->key, { rows => 0 })->content->{response}->{numFound};
    }

    # Count the number of sibling records (including this one) if it
    # belongs to a parent record.
    if ($self->record->pkey) {
        $self->{sibling_count} = $self->solr->search("pkey:" . $self->record->pkey, { rows => 0 })->content->{response}->{numFound};
    }
}

# Return the document for the parent object. Returns undef if
# there is no parent or there is a retrieval failure.
sub parent {
    my $self = shift;
    my $doc;
    return undef unless ($self->record->pkey);
    return $self->{_parent_cache} if ($self->{_parent_cache});
    eval { $doc = new CAP::Solr::Document({ key => $self->record->pkey, server => $self->server }) };

    ## TODO: check that the child is the right type.

    $@ ? return undef : return $self->{_parent_cache} = $doc;
}

# Return the document for the $seq'th child object. Returns undef if
# there is no such child or there is a retrieval failure.
sub child {
    my($self, $seq) = @_;
#method child (Int $seq) {
    my $doc;
    return undef if ($seq > $self->child_count);
    return $self->{_child_cache}->{$seq} if ($self->{_child_cache}->{$seq});
    my $response = $self->solr->search("pkey:" . $self->key, { so => 'seq asc', rows => 1, start => $seq - 1 });
    eval { $doc = new CAP::Solr::Document({ key => $response->docs->[0]->value_for('key'), server => $self->server }) };

    ## TODO: check that the child is the right type.

    $@ ? return undef : return $self->{_child_cache}->{$seq} = $doc;
}


# Convenient accessors for fields used internally by cap so we can
# reference them as $self->fieldname rather than $self->record->fieldname
sub canonicalUri { my $self = shift; return $self->record->canonicalUri; }
sub contributor  { my $self = shift; return $self->record->contributor; }
sub label        { my $self = shift; return $self->record->label; }
sub pkey         { my $self = shift; return $self->record->pkey; }
sub seq          { my $self = shift; return $self->record->seq; }

sub type_is {
    my($self, $type) = @_;
    return 1 if ($self->record->type eq $type);
    return 0;
}

__PACKAGE__->meta->make_immutable;
