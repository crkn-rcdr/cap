package CAP::Schema::ResultSet::UserLog;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Date::Manip::Date;

# Summarize the number of times various user events occurred over the past
# $days.
sub events_report {
    my($self, $days) = @_;
    my $date = new Date::Manip::Date;
    $date->parse(sprintf("%d days ago", $days));

    my $result = $self->search(
        { date => { '>=', $date->printf("%Y-%m-%d %T") }},
        {
            select =>   [ 'event', { count => 'id' } ],
            as     =>   [ 'event', 'event_count' ],
            group_by => [ 'event' ],
            order_by => [ 'event ASC' ],
        }
    );
    return $result;
}

# Summarize the number of actions taken by each user over the past $days,
# ordered according to frequency of use.
sub user_activity_report {
    my($self, $days) = @_;
    my $date = new Date::Manip::Date;
    $date->parse(sprintf("%d days ago", $days));

    my $result = $self->search(
        { date => { '>=', $date->printf("%Y-%m-%d %T") }},
        {
            select =>   [ 'user_id', { count => 'id', -as => 'id_count' } ],
            as     =>   [ 'user_id', 'user_count' ],
            group_by => [ 'user_id' ],
            order_by => [ 'id_count DESC' ],
        }
    );
    return $result;
}

# All log records for $user_id over the past $period days
sub user_log {
    my($self, $user_id, $days) = @_;
    my $date = new Date::Manip::Date;
    $date->parse(sprintf("%d days ago", $days));
    my $result = $self->search(
        { user_id => $user_id, date => { '>=', $date->printf("%Y-%m-%d %T") }},
        { order_by => [ 'date' ] },
    );
    return $result;
}

sub event_log {
    my($self, $event, $days) = @_;
    my $date = new Date::Manip::Date;
    $date->parse(sprintf("%d days ago", $days));
    my $result = $self->search(
        { event => $event, date => { '>=', $date->printf("%Y-%m-%d %T") }},
        { order_by => [ 'date' ] },
    );
    return $result;
}


1;
