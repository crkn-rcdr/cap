package CAP::Schema::ResultSet::Sessions;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub count_active
{
    my($self) = @_;
    return $self->search()->count;
}

=over 4

=item remove_expired

Removes all expired sessions from the database.

=back
=cut
sub remove_expired
{
    my($self) = @_;
    my $time = time();

    my $expired = $self->search({ expires => { '<' => $time } });
    my $removed = int($expired);
    $expired->delete;
    return $removed;
}


1;
