package CAP::Schema::ResultSet::OutboundLink;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Date::Manip::Date;

sub referral_report {
    my($self, $days) = @_;
    my $date = new Date::Manip::Date;
    $date->parse(sprintf("%d days ago", $days));

    my $result = $self->search(
        { time => { '>=', $date->printf("%Y-%m-%d %T") }},
        {
            select =>   [ 'contributor', { count => 'id', -as => 'link_count' } ],
            as     =>   [ 'contributor', 'link_count' ],
            group_by => [ 'contributor' ],
            order_by => [ 'link_count DESC' ],
        }
    );
    return $result;
}

1;
