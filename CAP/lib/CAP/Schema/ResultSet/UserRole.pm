package CAP::Schema::ResultSet::UserRole;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub user_has_role {
    my($self, $user, $role) = @_;
    return 1 if ($self->find({ user_id => $user, role_id => $role }));
    return 0;
}

1;
