package CAP::Schema::ResultSet::Roles;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 list

Returns a list of all roles. Will return an array or arryref, depending on the calling context.

=cut
sub list {
    my($self, $lang) = @_;
    my @roles = $self->search({}, { order_by => 'id' } )->all;
    return @roles if (wantarray);
    return \@roles;
}

1;
