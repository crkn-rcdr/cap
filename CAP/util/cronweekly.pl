#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use feature qw(switch say);

use FindBin;
use lib "$FindBin::Bin/../lib";

use CAP;
use Date::Manip::Date;

my $scriptname = 'cronweekly';

# Create a CAP object here so that you don't have to do it separately
# for each individual job.
my $c = CAP->new();

# Check to see if previous instance of this script is still running
# my $existing_pid = $c->model('DB::Info')->existing_pid($0);

my  $set_pid = $c->model('DB::Info')->obtain_pid_lock( $scriptname, $$ );



unless (  $set_pid )  {
    $c->model('DB::CronLog')->create(
        {
            action => 'cronweekly',
            ok     => 0,
            message => "$scriptname already running; killing myself as an example to others"
        }
    );
    die "cronweekly.pl: detected another version of myself, dying gracefully\nif the existing process is not responding please kill it and delete the cronweekly.pl row in cap.info";
}


my %actions = (
    compile_portal_stats          => \&compile_portal_stats,
    compile_institution_stats => \&compile_institution_stats,
    status_report                           => \&status_report
);

my $job;

foreach $job ( keys(%actions) ) {

    eval { $actions{$job}->($c) };

    if ($@) {

        $c->model('DB::CronLog')->create(
            {
                action  => 'cronweekly',
                ok      => 0,
                message => "cannot execute $job: $@"
            }
        );

    }

}

my $delete_pid = $c->model('DB::Info')->delete_pid( $scriptname, $$ );

$c->model('DB::CronLog')->create(
    {
        action  => 'cronweekly',
        ok      => 1,
        message => "done"
    }
);

sub compile_portal_stats {

    my $c = shift();

    my $last_update = $c->model('DB::StatsUsagePortal')->last_update()
      || $c->model('DB::Requests')->get_start();

    my $row;
    my $error;

    # Get the current month and the year
    my $end_date           = new Date::Manip::Date;
    my $err                = $end_date->parse('today');
    my $end_year           = $end_date->printf("%Y");
    my $first_of_month_end = $end_date->printf("%Y-%m-01");

    # Parse the start date
    my $start_date  = new Date::Manip::Date;
    my $start_year  = $last_update->{local_c}->{year};
    my $start_month = $last_update->{local_c}->{month};
    my $start_day   = $last_update->{local_c}->{day};

    my $first_of_month_st = join( '-', ( $start_year, $start_month, '1' ) );

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

        $c->model('DB::CronLog')->create(
            {
                action => 'cronweekly->compile_portal_stats',
                ok     => 1,
                message => "compiling for portal $portal, years $start_year through $end_year"
            }
        );

        for ( $year = $start_year ; $year <= $end_year ; $year++ ) {

            # If we're only reporting on this year we don't need to go all the way to December
            my $end_month = ( $year < $end_year ) ? 12 : $end_date->printf("%m");

            # Similarly we don't need to go all the way back to January if we start later
            $start_month = ( $year > $start_year ) ? 1 : $start_month;

            # Iterate through all the months
            for ( $month = $start_month ; $month <= $end_month ; $month++ ) {

                # get the monthly stats from the request log
                $monthly_stats =
                  $c->model('DB::Requests')->get_monthly_portal_stats( $portal, $month, $year );

                # make sure the dates are in the correct format
                $current_date_string = join( '-', ( $year, $month, '1' ) );

                $c->model('DB::CronLog')->create(
                    {
                        action   => 'cronweekly->compile_portal_stats',
                        ok       => 1,
                        message  => "compiling for portal $portal, month starting $current_date_string"
                    }
                );

                $current_date = new Date::Manip::Date;
                $err          = $current_date->parse($current_date_string);
                say $err if $err;
                $first_of_month = $current_date->printf("%Y-%m-01");

                # update or insert as required
                $monthly_stats->{'portal_id'}      = $portal;
                $monthly_stats->{'month_starting'} = $first_of_month;
                $c->model('DB::StatsUsagePortal')->update_monthly_stats($monthly_stats);

            }

        }

    }

    $c->model('DB::CronLog')->create(
        {
            action  => 'cronweekly->compile_portal_stats',
            ok      => 1,
            message => "done compiling portal stats"
        }
    );

    return 1;

}

sub compile_institution_stats {

    my $c = shift();
    
    my $last_update;

    eval { $last_update = $c->model('DB::StatsUsageInstitution')->last_update()
                                                                           ||
                                              $c->model('DB::Requests')->get_start();
    };
    die $@ if $@;
    my $row;
    my $error;

    # Get the current month and the year
    my $end_date           = new Date::Manip::Date;
    my $err                = $end_date->parse('today');
    my $end_year           = $end_date->printf("%Y");
    my $first_of_month_end = $end_date->printf("%Y-%m-01");

    # Parse the start date
    my $start_date  = new Date::Manip::Date;
    my $start_year  = $last_update->{local_c}->{year};
    my $start_month = $last_update->{local_c}->{month};
    my $start_day   = $last_update->{local_c}->{day};

    my $first_of_month_st = join( '-', ( $start_year, $start_month, '1' ) );

    # Get a list of distinct institutions from the institutions table
    my $institutions = $c->model('DB::Institution')->list_ids();
   #     my $institutions = $c->model('DB::Requests')->get_institutions($c);
    my $portals = $c->model('DB::Portal')->list_inst_portals();
    my $portal;
    my $month;
    my $first_of_month;
    my $year;
    my $current_date;
    my $current_date_string;
    my $monthly_stats;
    my $institution;

    # Iterate through all the institutions
    foreach $institution ( @$institutions ) {

        foreach $portal (@$portals) {

            $c->model('DB::CronLog')->create(
                {
                    action => 'cronweekly->compile_institution_stats',
                    ok     => 1,
                    message => "compiling for institution $institution, years $start_year through $end_year"
                }
            );
    
            for ( $year = $start_year ; $year <= $end_year ; $year++ ) {
    
                # If we're only reporting on this year we don't need to go all the way to December
                my $end_month = ( $year < $end_year ) ? 12 : $end_date->printf("%m");
    
                # Similarly we don't need to go all the way back to January if we start later
                $start_month = ( $year > $start_year ) ? 1 : $start_month;
    
                # Iterate through all the months
                for ( $month = $start_month ; $month <= $end_month ; $month++ ) {
    
                    # get the monthly stats from the request log
                    $monthly_stats = $c->model('DB::Requests')->get_monthly_inst_stats( $institution, $month, $year );
    
                    # make sure the dates are in the correct format
                    $current_date_string = join( '-', ( $year, $month, '1' ) );
    
                    $c->model('DB::CronLog')->create(
                        {
                            action => 'cronweekly->compile_institution_stats',
                            ok     => 1,
                            message => "compiling for institution $institution, month starting $current_date_string"
                        }
                    );
    
                    $current_date = new Date::Manip::Date;
                    eval { $current_date->parse($current_date_string); };
                    die $@ if $@;
                    $first_of_month = $current_date->printf("%Y-%m-01");
    
                    # update or insert as required
                    $monthly_stats->{'institution_id'}      = $institution;
                    $monthly_stats->{'portal_id'}               = $portal;
                    $monthly_stats->{'month_starting'} = $first_of_month;
                    eval { $c->model('DB::StatsUsageInstitution')->update_monthly_stats($monthly_stats); };
                    if ($@ ) {
                        $c->model('DB::CronLog')->create(
                            {
                                action => 'cronweekly->compile_institution_stats',
                                ok     => 1,
                                message => "received error message $@"
                            }
                        );
                       die $@;
                   };
                   
                   $c->model('DB::CronLog')->create(
                        {
                            action => 'cronweekly->compile_institution_stats',
                            ok     => 1,
                            message => "done inserting stats for institution $institution, month starting $current_date_string"
                        }
                   );   
                }
    
            }

        }
    }

    $c->model('DB::CronLog')->create(
        {
            action  => 'cronweekly->compile_institution_stats',
            ok      => 1,
            message => "done compiling institution stats"
        }
    );

    return 1;
}


# Compile a system status report and send it to designated users
sub status_report {
    my $c = shift();

    # We need something in the portal ID field so that Mail won't
    # complain. FIXME: this is not a great solution.
    $c->stash(portal => 'Default');


    # If there is no one to send a status report to, then don't bother
    # doing any work.
    unless ($c->config->{mailinglist}->{status_report}) {
        $c->model('DB::CronLog')->create({
            action => 'cronweekly->status_report',
            ok => 0,
            message => "No mailing list configured in config->{mailinglist}->{status_report}"
        });
        return 1;
    }

    my $recipients =$c->config->{mailinglist}->{status_report};

    $c->controller('Mail')->status_report($c, $recipients,
        portal_stats_current => [$c->model('DB::StatsUsagePortal')->stats_for_month()],
        portal_stats_previous => [$c->model('DB::StatsUsagePortal')->stats_for_month(1)],
        user_subscriptions => [$c->model('DB::UserSubscription')->active_by_portal()]
    );

    $c->model('DB::CronLog')->create({
        action => 'status_report',
        ok => 1,
        message => "Mailed status report to: $recipients"
    });

    return 1;
}
