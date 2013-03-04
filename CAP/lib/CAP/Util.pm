package CAP::Util;
use strict;
use warnings;


=head1 CAP::Util - General utility functions

This package is for general utility, helper and macro-type functions.

=head1 Methods

=cut

=head2 build_entity($object)

Build a hashrefh containing the column names and values of database $object.

=cut
sub build_entity {
    my($object) = @_;
    my $entity = {};
    foreach my $column ($object->result_source->columns) {
        $entity->{$column} = $object->get_column($column);
    }
    return $entity;
}

1;
