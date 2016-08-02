#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use feature qw(switch say);

use lib "/opt/c7a-perl/current/cmd/local/lib/perl5";
use FindBin;
use lib "$FindBin::Bin/../lib";

use CAP;
use Date::Manip::Date;

my $scriptname = 'cronweekly';

# Create a CAP object here so that you don't have to do it separately
# for each individual job.
my $c = CAP->new();

my @actions = (
    [compile_portal_stats      => \&compile_portal_stats],
    [compile_institution_stats => \&compile_institution_stats],
    [status_report             => \&status_report]
);

foreach (@actions) {
    my ($job, $ref) = @$_;
    eval { $ref->($c) };
    if ($@) {
        print STDERR "could not perform $job:\n$@";
    } else {
        # In the future we should log this, but for now we should be silent when not debugging.
        #print "performed $job\n";
    }
}

sub compile_portal_stats {
    my $c = shift;

    my $last_update = $c->model('DB::StatsUsagePortal')->last_update() ||
        $c->model('DB::Requests')->get_start();

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
        for ( $year = $start_year ; $year <= $end_year ; $year++ ) {
            # If we're only reporting on this year we don't need to go all the way to December
            my $end_month = ( $year < $end_year ) ? 12 : $end_date->printf("%m");

            # Similarly we don't need to go all the way back to January if we start later
            $start_month = ( $year > $start_year ) ? 1 : $start_month;

            # Iterate through all the months
            for ( $month = $start_month ; $month <= $end_month ; $month++ ) {
                # get the monthly stats from the request log
                $monthly_stats = $c->model('DB::Requests')->get_monthly_portal_stats($portal, $month, $year);

                # make sure the dates are in the correct format
                $current_date_string = join( '-', ( $year, $month, '1' ) );

                $current_date = new Date::Manip::Date;
                $current_date->parse($current_date_string);
                $first_of_month = $current_date->printf("%Y-%m-01");

                # update or insert as required
                $monthly_stats->{'portal_id'}      = $portal;
                $monthly_stats->{'month_starting'} = $first_of_month;
                $c->model('DB::StatsUsagePortal')->update_monthly_stats($monthly_stats);
            }
        }
    }

    return 1;
}

sub compile_institution_stats {
    my $c = shift;
    
    my $last_update;
    eval {
        $last_update = $c->model('DB::StatsUsageInstitution')->last_update() ||
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
    
                    $current_date = new Date::Manip::Date;
                    $current_date->parse($current_date_string);
                    $first_of_month = $current_date->printf("%Y-%m-01");
    
                    # update or insert as required
                    $monthly_stats->{'institution_id'}      = $institution;
                    $monthly_stats->{'portal_id'}               = $portal;
                    $monthly_stats->{'month_starting'} = $first_of_month;
                    $c->model('DB::StatsUsageInstitution')->update_monthly_stats($monthly_stats);
                }
            }
        }
    }

    return 1;
}


# Compile a system status report and send it to designated users
sub status_report {
    my $c = shift;

    # We need something in the portal ID field so that Mail won't
    # complain. FIXME: this is not a great solution.
    $c->stash(portal => 'Default');


    # If there is no one to send a status report to, then don't bother
    # doing any work.
    my $recipients =$c->config->{mailinglist}->{status_report};
    return 1 unless ($recipients);

    $c->controller('Mail')->status_report($c, $recipients,
        portal_stats_current => [$c->model('DB::StatsUsagePortal')->stats_for_month()],
        portal_stats_previous => [$c->model('DB::StatsUsagePortal')->stats_for_month(1)],
        user_subscriptions => [$c->model('DB::UserSubscription')->active_by_portal()]
    );

    return 1;
}
