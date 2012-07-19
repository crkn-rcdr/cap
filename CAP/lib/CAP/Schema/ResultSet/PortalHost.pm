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

sub validate {
    my($self, $host) = @_;
    my $result = {};
    if ($host !~ /^[a-z\d]+(-[a-z\d]+)*$/i) {
        $result->{valid} = 0;
        $result->{error} = "invalid_subdomain";
    } elsif ($self->find({ id => $host })) {
        $result->{valid} = 0;
        $result->{error} = "subdomain_taken";
    } else {
        $result->{valid} = 1;
    }
    return $result;
}

1;


