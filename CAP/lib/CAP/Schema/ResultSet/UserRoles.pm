package CAP::Schema::ResultSet::UserRoles;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 set_roles ($user, @roles)

Delete any existing roles for $user and replace them with @roles.

=cut
sub set_roles {
    my($self, $user, @roles) = @_;

    # Clear out all existing roles
    my $result = $self->search({ user_id => $user->id });
    while (my $row = $result->next) {
        $row->delete;
    }

    # Set the new roles
    foreach my $role (@roles) {
        $self->create({ user_id => $user->id, role_id => $role });
    }

    return 1;
}

1;
