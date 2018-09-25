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

__PACKAGE__->meta->make_immutable;

1;
