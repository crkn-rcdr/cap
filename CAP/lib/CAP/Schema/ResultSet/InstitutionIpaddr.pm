package CAP::Schema::ResultSet::InstitutionIpaddr;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Net::IP;

# Return the group id associated with the ip address, or 0 if none.

# Check whether the supplied IP address belongs to an IP range of a
# registered group. If so, return the corresponding row from the groups
# table. Otherwise return undef.
sub institution_for_ip
{
    my($self, $address) = @_;

    my $ip_addr = Net::IP->new($address);
    my $record = $self->find({
        start => { '<=' => $ip_addr->intip },
        end   => { '>=' => $ip_addr->intip },
    });
    return $record->institution_id if ($record);
    return undef;
}

# Returns a result set of IP addresses for the institution, in address
# order (as an arrayref)
sub ip_for_institution
{
    my($self, $institution_id) = @_;
    return [$self->search({ institution_id => $institution_id }, { order_by => { -asc => 'start' }})->all];
}

# Deletes the CIDR ranges specified, if the exist.
sub delete_address
{
    my($self, @address) = @_;
    foreach my $cidr (@address) {
        my $record = $self->find({ cidr => $cidr});
        $record->delete if ($record);
    }
}

1;
