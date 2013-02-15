package CAP::Schema::ResultSet::StatsUsagePortal;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub update_monthly_stats {

    
    my ( $self, $stats ) = @_;

    
    # first check to see if there is an existing row with up-to-date data
    my $search = $self->search(
       {%$stats}
    );

    unless ( $search->count ) {

        # we want to reset the timestamp
        $stats->{'last_updated'} = undef;
        
        # insert or update monthly stats depending on whether the row exists
        my $err = $self->update_or_create(
    
           {%$stats},
           {key => 'primary'}
    
       );

    }

    return 1;

}


sub last_update {
    my $self = shift();
    my $row = $self->search( {}, { order_by => { -desc => 'last_updated' } } )->first;

    # return 0 if the database is empty;
    my $last_update = defined($row) ? $row->month_starting : 0;
    return $last_update;

}


sub first_month {

    # returns the month of the first entry
    my $self = shift();
    my $row = $self->search( {}, { order_by => { -asc => 'month_starting' } } )->first;

    # return 0 if the database is empty;
    my $first_month = defined($row) ? $row->month_starting : 0;
    return $first_month;

}

sub get_stats {
    my ( $self, $portal, $month ) = @_;

    my $row = $self->find(
        {
            'month_starting' => $month,
            'portal_id' => $portal
        }

    );

    my $stats;

    if ( defined($row) ) {

        $stats = {
            portal_id      => $row->portal_id,
            searches       => $row->searches,
            views          => $row->page_views,
            sessions       => $row->sessions,
            requests       => $row->requests
        };
    }

    # If you don't get a row just set everything to 0
    else {

        $stats = {
            portal_id      => $portal,
            searches       => 0,
            views          => 0,
            sessions       => 0,
            requests       => 0
          }

    }

    return $stats;
}

1;
