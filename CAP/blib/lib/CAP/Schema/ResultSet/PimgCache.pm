package CAP::Schema::ResultSet::PimgCache;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 get_image

Retrieve a particular image by unique key.

=cut

sub get_image
{
    my($self, $id, $format, $size, $rot) = @_;
    return $self->search({
        id     => { '=' => $id },
        format => { '=' => $format },
        size   => { '=' => $size },
        rot    => { '=' => $rot },
    });
}

1;
