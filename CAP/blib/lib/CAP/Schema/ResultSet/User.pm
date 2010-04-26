package CAP::Schema::ResultSet::User;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 get_user_by_name

Retrieve a user by username

=cut 
sub get_user_by_name
{
    my($self, $username) = @_;
    return $self->find({ username => $username });
}


=head2 user_exists

Returns true if the user name already exists.

=cut
sub user_exists
{
    my($self, $username) = @_;
    return $self->search({ username => { '=' => $username } })->count;
}


1;
