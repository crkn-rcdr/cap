#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use feature qw(switch say);

use lib '../lib';
use CAP;
use Date::Manip::Date;


# Create a CAP object here so that you don't have to do it separately
# for each individual job.
my $c = CAP->new();

# Check to see if previous instance of this script is still running
my $existing_pid = $c->model('DB::Info')->existing_pid($0);

if ( defined ($existing_pid) ) {
   $c->model('DB::CronLog')->create({
               action  => 'cronweekly',
               ok      => 0,
               message => "$0 already running; killing myself as an example to others"
    });    
    die "script already running with PID $existing_pid\n";
}

my $set_pid = $c->model('DB::Info')->set_pid($0, $$);



# List of jobs to run. We can move this to the database or config file later.
# To create a new job put it in a sub and add it to this list.
# To disable a job just comment it out
my %actions = (
                compile_portal_stats       =>  \&compile_portal_stats,
                compile_institution_stats  =>  \&compile_institution_stats
              );

my $job;      
              
foreach $job (keys(%actions)) {

    eval { $actions{$job}->($c) };

    if ( $@ ) {

           $c->model('DB::CronLog')->create({
                      action  => 'cronweekly',
                      ok      => 0,
                      message => "cannot execute $job: $@"
           });    

    }

}

my $delete_pid = $c->model('DB::Info')->delete_pid($0, $$);

$c->model('DB::CronLog')->create({
               action  => 'cronweekly',
               ok      => 1,
               message => "done"
});


sub compile_portal_stats {
    
    my $c = shift();
    

    my $last_update = $c->model('DB::StatsUsagePortal')->last_update() || $c->model('DB::Requests')->get_start();


    my $row;
    my $error;

    # Get the current month and the year
    my $end_date            = new Date::Manip::Date;
    my $err                 = $end_date->parse('today');
    my $end_year            = $end_date->printf("%Y");
    my $first_of_month_end  = $end_date->printf("%Y-%m-01");



    # Parse the start date    
    my $start_date             = new Date::Manip::Date;
    my $start_year = $last_update->{local_c}->{year};
    my $start_month = $last_update->{local_c}->{month};
    my $start_day = $last_update->{local_c}->{day};

    my $first_of_month_st =  join ('-',($start_year,$start_month,'1'));
             
    # Get a list of distinct portals from the portals table
    my $portals = $c->model('DB::Portal')->list_portals();
    my $month;
    my $first_of_month;
    my $year;
    my $current_date;
    my $current_date_string;
    my $monthly_stats;
    my $portal;


    # Iterate through all the portals
    foreach $portal (@$portals) {


        $c->model('DB::CronLog')->create({
                    action  => 'cronweekly',
                    ok      => 1,
                    message => "compiling for portal $portal, years $start_year through $end_year"
        });

        for ($year = $start_year; $year <= $end_year; $year++) {
        
            # If we're only reporting on this year we don't need to go all the way to December
            my $end_month = ($year < $end_year) ? 12 : $end_date->printf("%m");
           
            # Similarly we don't need to go all the way back to January if we start later
            $start_month = ($year > $start_year) ? 1 : $start_month ;

            # Iterate through all the months
            for ($month = $start_month; $month <= $end_month; $month++) {
                   
                # get the monthly stats from the request log
                $monthly_stats = $c->model('DB::Requests')->get_monthly_portal_stats($portal, $month, $year);
     
                # make sure the dates are in the correct format
                $current_date_string = join ('-',($year,$month,'1'));

                $c->model('DB::CronLog')->create({
                    action  => 'cronweekly',
                    ok      => 1,
                    message => "compiling for portal $portal, month starting $current_date_string"
                });

                $current_date  = new Date::Manip::Date;
                $err           = $current_date->parse($current_date_string);
                say $err if $err;
                $first_of_month   = $current_date->printf("%Y-%m-01");

                # update or insert as required
                $monthly_stats->{'portal_id'} = $portal;               
                $monthly_stats->{'month_starting'} = $first_of_month;              
                $c->model('DB::StatsUsagePortal')->update_monthly_stats($monthly_stats);

           }

       }
           
    }

    
    $c->model('DB::CronLog')->create({
                    action  => 'cronweekly',
                    ok      => 1,
                    message => "done compiling portal stats"
    });

    return 1;

}


sub compile_institution_stats {
    
    my $c = shift();

    my $last_update = $c->model('DB::StatsUsageInstitution')->last_update() || $c->model('DB::Requests')->get_start();


    my $row;
    my $error;

    # Get the current month and the year
    my $end_date            = new Date::Manip::Date;
    my $err                 = $end_date->parse('today');
    my $end_year            = $end_date->printf("%Y");
    my $first_of_month_end  = $end_date->printf("%Y-%m-01");



    # Parse the start date    
    my $start_date   = new Date::Manip::Date;
    my $start_year   = $last_update->{local_c}->{year};
    my $start_month  = $last_update->{local_c}->{month};
    my $start_day    = $last_update->{local_c}->{day};

    my $first_of_month_st =  join ('-',($start_year,$start_month,'1'));
             
    # Get a list of distinct institutions from the institutions table
    my $institutions = $c->model('DB::Requests')->get_institutions($c);
    my $month;
    my $first_of_month;
    my $year;
    my $current_date;
    my $current_date_string;
    my $monthly_stats;
    my $institution;


    # Iterate through all the institutions
    foreach $institution (@$institutions) {

        $c->model('DB::CronLog')->create({
                    action  => 'cronweekly',
                    ok      => 1,
                    message => "compiling for institution $institution, years $start_year through $end_year"
        });

        for ($year = $start_year; $year <= $end_year; $year++) {
        
            # If we're only reporting on this year we don't need to go all the way to December
            my $end_month = ($year < $end_year) ? 12 : $end_date->printf("%m");
           
            # Similarly we don't need to go all the way back to January if we start later
            $start_month = ($year > $start_year) ? 1 : $start_month ;

            # Iterate through all the months
            for ($month = $start_month; $month <= $end_month; $month++) {
                   
                # get the monthly stats from the request log
                $monthly_stats = $c->model('DB::Requests')->get_monthly_inst_stats($institution, $month, $year);
     
                # make sure the dates are in the correct format
                $current_date_string = join ('-',($year,$month,'1'));               
                
                $c->model('DB::CronLog')->create({
                    action  => 'cronweekly',
                    ok      => 1,
                    message => "compiling for institution $institution, month starting $current_date_string"
                });

                
                $current_date  = new Date::Manip::Date;
                $err           = $current_date->parse($current_date_string);
                say $err if $err;
                $first_of_month   = $current_date->printf("%Y-%m-01");

                # update or insert as required
                $monthly_stats->{'institution_id'} = $institution;               
                $monthly_stats->{'month_starting'} = $first_of_month;              
                $c->model('DB::StatsUsageInstitution')->update_monthly_stats($monthly_stats);

           }

       }
           
    }

    $c->model('DB::CronLog')->create({
                    action  => 'cronweekly',
                    ok      => 1,
                    message => "done compiling institution stats"
    });

    return 1;
}
