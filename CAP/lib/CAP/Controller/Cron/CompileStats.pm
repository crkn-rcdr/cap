package CAP::Controller::Cron::CompileStats;
use Moose;
use namespace::autoclean;
use Date::Manip::Date;

BEGIN {extends 'Catalyst::Controller'; }



sub index : Private {

    my($self, $c) = @_;

    # Get the current month and the year
    my $end_date            = new Date::Manip::Date;
    my $err                 = $end_date->parse('today');
    my $end_year            = $end_date->printf("%Y");
    my $first_of_month_end  = $end_date->printf("%Y-%m-01");
    
    # Find the date of the last update or find the first entry in the log table if there is none
    my $last_update = $c->model('DB::StatsUsageInstitution')->last_update() || $c->model('DB::RequestLog')->get_start();

    # Parse the start date    
    my $start_date           = new Date::Manip::Date;
    $err                     = $start_date->parse($last_update);
    my $start_year           = $start_date->printf("%Y");
    my $start_month          = $start_date->printf("%m");
    my $first_of_month_st    = $start_date->printf("%Y-%m-01");
    
    $c->log->error("compiling data from $first_of_month_st to $first_of_month_end");
  
    # Get a list of distinct institutions in the request log
    my $institutions = $c->model('DB::RequestLog')->get_institutions($c);
    
    my $month;
    my $first_of_month;
    my $year;
    my $current_date;
    my $monthly_stats;
    my $inst;
    
    for ($year = $start_year; $year <= $end_year; $year++) {
    
        # If we're only reporting on this year we don't need to go all the way to December
        my $end_month = ($year < $end_year) ? 12 : $end_date->printf("%m");
        
        # Similarly we don't need to go all the way back to January if we start later
        $start_month = ($year > $start_year) ? 1 : $start_month ;        

        # Iterate through all the institutions
        foreach $inst (@$institutions) {

           # Iterate through all the months
           for ($month = $start_month; $month <= $end_month; $month++) {
               
               # get the monthly stats from the request log
               $monthly_stats = $c->model('DB::RequestLog')->get_monthly_stats($inst, $month, $year);
               
               # make sure the dates are in the correct format
               my $current_date  = new Date::Manip::Date;
               my $err           = $current_date->parse_format('%Y\\-%f\\-%e',join ('-',($year,$month,'1')));
               $first_of_month   = $current_date->printf("%Y-%m-01");
    
               # update or insert as required
               $c->model('DB::StatsUsageInstitution')->update_monthly_stats($inst,$first_of_month,$monthly_stats);

           }

       }
        
    }


    return 1;
};


__PACKAGE__->meta->make_immutable;
