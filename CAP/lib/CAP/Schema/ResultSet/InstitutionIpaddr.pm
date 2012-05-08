package CAP::Schema::ResultSet::InstitutionIpaddr;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Net::IP;

# Add an IP address range to the supplied institution id. If there is a
# conflict (overlap) return 0 and put a message in $conflict.
sub add {
    my($self, $id, $range, $conflict) = @_;
    my $ip_addr = Net::IP->new($range);
    if (! $ip_addr) {
        $$conflict = "Cannot parse this IP address";
        return 0;
    }
    my $cidr = $ip_addr->print();
    my $start = $ip_addr->intip();
    my $end = $ip_addr->last_int();

    my $ip_start = $ip_addr->intip;
    my $ip_end = $ip_addr->last_int;
    my $overlap;

    # Make sure the start of the range does not fall within an existing range
    $overlap = $self->find({start => { '<=', $ip_start }, end => { '>=', $ip_start }});
    if ($overlap) { $$conflict = sprintf("%s (%s)", $overlap->cidr, $overlap->institution_id->name); return 0; }

    # Do the same for the end of the range
    $overlap = $self->find({start => { '<=', $ip_end }, end => { '>=', $ip_end }});
    if ($overlap) { $$conflict = sprintf("%s (%s)", $overlap->cidr, $overlap->institution_id->name); return 0; }
    
    # Make sure no existing range is a subset of the range
    $overlap = $self->find({ start => { '>=', $ip_start, '<=', $ip_end }, end => { '>=', $ip_start, '<=', $ip_end }});
    if ($overlap) { $$conflict = sprintf("%s (%s)", $overlap->cidr, $overlap->institution_id->name); return 0; }
    

    # The above code accomplishes the same thing but much faster.
    # Make sure we don't overlap with an existing range.
    #foreach my $row ($self->all) {
    #    my $db_addr = Net::IP->new($row->cidr);
    #    if ($ip_addr->version eq $db_addr->version) {
    #        if ($ip_addr->overlaps($db_addr) != $IP_NO_OVERLAP) {
    #            $$conflict = $row->cidr;
    #            return 0;
    #        }
    #    }
    #}

    eval {
        $self->create({
            cidr           => $cidr,
            institution_id => $id,
            start          => $start,
            end            => $end,
        })
    };
    return 0 if ($@);
    return 1;
}

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

# Deletes the CIDR ranges specified. $range can be a single address or an
# array reference.
sub delete_address
{
    my($self, $range) = @_;
    my @list;
    if(ref($range) eq 'ARRAY') {
        @list = @{$range};
    }
    else {
        @list = ($range);
    }

    foreach my $cidr (@list) {
        my $record = $self->find({ cidr => $cidr});
        $record->delete if ($record);
    }
}

1;
