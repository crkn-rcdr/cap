package CAP::Schema::ResultSet::PortalsTitles;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 CAP::Schema::ResultSet::PortalsTitles

=head1 Methods

=cut


=head2 by_portal

=cut

sub counts_by_portal {
    my($self) = @_;
    my @portals = ();

    my $result = $self->search(
        {},
        {
            select   => [ { distinct => 'portal_id', }, { count => 'title_id' } ],
            as       => [ 'portal_id', 'titles' ],
            group_by => [ 'portal_id' ],
            order_by => [ 'portal_id' ]
        }
    );

    while (my $result = $result->next) {
        push(@portals, {
            portal => $result->portal_id,
            titles => $result->get_column('titles')
        });
    }

    return @portals;
}

1;
