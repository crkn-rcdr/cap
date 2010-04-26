package CAP::Schema::ResultSet::UserRole;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub roles_for_user
{
    my($self, $user_id) = @_;
    return $self->search({ user_id => { '=' => $user_id } });
}

sub set_roles
{
    my($self, $user_id, @roles) = @_;
    $self->search({ user_id => { '=' => $user_id } })->delete;
    foreach my $role_id (@roles) {
        $self->create({ user_id => $user_id, role_id => $role_id });
    }
}

sub delete_roles
{
    my($self, $user_id) = @_;
    $self->search({ user_id => { '=' => $user_id } })->delete;
}

1;
