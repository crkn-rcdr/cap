package CAP::Schema::ResultSet::MasterImage;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 get_image

Retrieve info for a particular image by document ID.

=cut

sub get_image
{
    my($self, $id) = @_;
    return $self->search({
        id => { '=' => $id },
    });
}

1;
