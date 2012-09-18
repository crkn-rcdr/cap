package CAP::Schema::ResultSet::StatsUsageInstitution;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';


sub update_monthly_stats {
    
    # inserts or updates monthly stats depending on whether the row exists
    my ($self, $inst, $month, $stats) = @_;

    my $row = $self->find(

            {
                institution_id    =>   $inst,
                month_starting    =>   $month
            }
            

    );

    if (defined($row)) {       
        $row->update($stats);
    }
    
    else {
       $stats->{'institution_id'} = $inst;
       $stats->{'month_starting'} = $month;
       $self->create($stats);   
    }

    return 1;

}

sub last_update {
    my $self = shift();
    my $row = $self->find(
          {},
          {
              order_by => { -desc => 'last_updated' }
          }
    );
    
    # return 0 if the database is empty;
    my $last_update = defined($row) ? $row->last_updated : 0;
    return $last_update;

}

sub first_month {
    # returns the month of the first entry
    my $self = shift();
    my $row = $self->find(
          {},
          {
              order_by => { -asc => 'month_starting' }
          }
    );
    
    # return 0 if the database is empty;
    my $first_month = defined($row) ? $row->month_starting : 0;
    return $first_month;

}


sub get_stats {
    my ($self, $inst, $month) = @_;

    my $row = $self->find(
          {
            'month_starting'  => $month,
            'institution_id'  => $inst
          }

      );
    
    my $stats;
    
    if (defined($row)) {

        $stats = { 
                      institution_id => $row->institution_id,
                      searches       => $row->searches,
                      views          => $row->page_views,
                      sessions       => $row->sessions,
                      requests       => $row->requests                  
        };
    }

    # If you don't get a row just set everything to 0
    else {

        $stats = { 
                      institution_id => $inst,
                      searches       => 0,
                      views          => 0,
                      sessions       => 0,
                      requests       => 0
        }
        
    }
    
    return $stats;
}

1;

