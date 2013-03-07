package CAP::Schema::ResultSet::Titles;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 CAP::Schema::ResultSet::Titles

=head1 Methods

=cut

=head2 unassigned

Returns the set of all titles that are not currently assigned to any portal

=cut
sub unassigned {
    my($self) = @_;
    my $result = $self->search(
        { portal_id => { '=' => undef } },
        { join => 'portals_titles' }
    );
    return $result;
}


1;
