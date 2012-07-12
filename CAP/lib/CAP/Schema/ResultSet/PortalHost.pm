package CAP::Schema::ResultSet::PortalHost;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub get_portal {
    my($self, $host) = @_;
    my $row = $self->find({ id => $host });
    return $row->portal_id if ($row);
    return undef;
}

1;


