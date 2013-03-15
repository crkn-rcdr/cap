package CAP::Util;
use strict;
use warnings;
use namespace::autoclean;
use Moose;
use MooseX::Method::Signatures;
use Hash::MoreUtils qw/slice_def/;
use Digest::SHA qw(sha1_hex);
use URI;

has 'c' => (is => 'ro', isa => 'CAP', required => 1);

=head1 CAP::Util - General utility functions

This package is for general utility, helper and macro-type functions.

=head1 Methods

=cut

=head2 build_entity($object)

Build a hashref containing the column names and values of database $object.

=cut
method build_entity ($object) {
    my $entity = {};
    foreach my $column ($object->result_source->columns) {
        $entity->{$column} = $object->get_column($column);
    }
    return $entity;
}

=head2 derivative_request (CAP::Solr::Document $document, Int $seq, Str $filename, Str $size, Str $rotate, Str $format)

Request a derivative URI for COS, for the given $document.

=cut

method derivative_request (CAP::Solr::Document $document, Int $seq, Str $filename, Str $size, Str $rotate, Str $format) {
    my $d_config = $self->c->config->{derivative};
    my $config = $self->c->config->{content};
    my $size_str = $d_config->{size}->{$size} || $d_config->{default_size};
    my $rotate_angle = $d_config->{rotate}->{$rotate} || "0";
    my $response = $document->validate_derivative($seq, $size_str, $d_config->{default_size});
    if ($response->[0] == 200) {
        my $data = {
            expires => $self->_request_expires(),
            file => $filename,
            key => $config->{key},
            password => $config->{password},
            from => $document->child($seq)->canonicalMaster,
            format => $format,
            size => $size_str,
            rotate => $rotate_angle,
        };
        $data->{signature} = $self->_request_signature($data);
        my %query_params = slice_def($data, qw/expires signature key from format size rotate/);
        $response->[1] = $self->_request_uri($config->{url}, $data->{file}, \%query_params);
    }
    return $response;
}

=head2 download_request (CAP::Solr::Document $document)

Request a document download URI for COS, for the given $document.

=cut

method download_request (CAP::Solr::Document $document) {
    my $response = $document->validate_download();
    my $config = $self->c->config->{content};
    if ($response->[0] == 200) {
        my $data = {
            expires => $self->_request_expires(),
            file => $document->canonicalDownload,
            key => $config->{key},
            password => $config->{password},
        };
        $data->{signature} = $self->_request_signature($data);
        my %query_params = slice_def($data, qw/expires signature key file/);
        $response->[1] = $self->_request_uri($config->{url}, $data->{file}, \%query_params);
    }
    return $response;
}

method _request_expires {
    my $time = time() + 90000; # 25 hours in the future
    $time = $time - ($time % 86400); # normalize the expiry time to the closest 24 hour period
    return $time; # minimum 1 hour from now, maximum 25
}

method _request_signature (HashRef $signature_data) {
    my @keys = qw/password file expires from size rotate/;
    return sha1_hex(join("\n", map { defined($_) ? $_ : '' } @{$signature_data}{@keys}));
}

method _request_uri (Str $content_url, Str $filename, HashRef $params) {
    my $uri = URI->new(join("/", ($content_url, $filename)));
    $uri->query_form($params);
    return $uri->as_string;
}

__PACKAGE__->meta->make_immutable;

1;
