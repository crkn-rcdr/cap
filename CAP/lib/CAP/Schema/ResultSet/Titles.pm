package CAP::Schema::ResultSet::Titles;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 CAP::Schema::ResultSet::Titles

=head1 Methods

=cut

=head2 unassigned

Returns the set of all titles for the supplied institution that are not assigned to any portal.

=cut
sub unassigned {
    my($self, $institution_id) = @_;
    my $result = $self->search(
        { institution_id => $institution_id, portal_id => { '=' => undef } },
        { join => 'portals_titles' }
    );
    return $result;
}

=head2 count_by_institution

Return a list of institutions that own one or more titles along with the
total number of titles and the number of titles not assigned to any
portals.

[ { institution => $inst, titles => $titles, unassigned => $unassigned }, ... ]

=cut
sub counts_by_institution {
    my($self) = @_;
    my @counts = ();

    # A set of institutions with the corresponding number of titles
    # belonging to them, by title count in descending order.
    my $institutions = $self->search(
        {},
        {
            select => [ 'institution_id', { count => 'id', -as => 'title_count' } ],
            as     => [ 'institution_id', 'title_count' ],
            group_by => [ 'institution_id' ],
            order_by => [ { -desc => 'title_count' } ]
        }
    );

    while (my $i = $institutions->next) {
        push(@counts, {
            institution => $i->institution_id,
            titles => $i->get_column('title_count'),
            unassigned => $self->unassigned($i->institution_id->id)->count
        });
    }

    return \@counts;
}

1;
