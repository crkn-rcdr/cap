package CAP::Schema::ResultSet::PimgCache;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 get_image

Retrieve a particular image by unique key.

=cut

# Retrieve an image identified by its primary key.
sub get_image
{
    my( $self, $id, $format, $size, $rot ) = @_;
    return $self->search({
        id     => { '=' => $id },
        format => { '=' => $format },
        size   => { '=' => $size },
        rot    => { '=' => $rot },
    });
}


# Delete all derivative images with $id.
sub delete_derivatives
{
    my( $self, $id ) = @_;
    $self->search( { id => { '=' => $id } } )->delete;
    return 1;
}

1;
