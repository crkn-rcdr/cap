package CAP::Schema::ResultSet::GroupsIpaddr;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Net::IP;

# Return the group id associated with the ip address, or 0 if none.

# Check whether the supplied IP address belongs to an IP range of a
# registered group. If so, return the corresponding row from the groups
# table. Otherwise return undef.
sub group_for_ip
{
    my($self, $address) = @_;

    my $ip_addr = Net::IP->new($address);
    my $record = $self->find({
        start => { '<=' => $ip_addr->intip },
        end   => { '>=' => $ip_addr->intip },
    });
    return $record->group_id if ($record);
    return undef;
}

1;
