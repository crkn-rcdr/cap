#!/usr/bin/perl

# Utility that migrates user data from user table to user_subscription table

use 5.010;
use strict;
# use warnings;
# use diagnostics;
no warnings;


use feature qw(switch say);

use Moose;
use namespace::autoclean;
use Date::Manip::Date;

use lib '../lib';
use CAP;

my $c = CAP->new();

my $last_update = $c->model('DB::StatsUsagePortal')->last_update() || $c->model('DB::RequestLog')->get_start();


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

    my $first_of_month_st =  join ('-',($start_year,$start_month,'1'));
        
    say "compiling data from $first_of_month_st to $first_of_month_end";
    
  
    # Get a list of distinct portals in the request log
    # my $portals = $c->model('DB::RequestLog')->get_portals($c); finds distinct portals in log file
    my $portals = $c->model('DB::Portal')->list_portals();
    my $month;
    my $first_of_month;
    my $year;
    my $current_date;
    my $current_date_string;
    my $monthly_stats;
    my $portal;


    for ($year = $start_year; $year <= $end_year; $year++) {
    
        # If we're only reporting on this year we don't need to go all the way to December
        my $end_month = ($year < $end_year) ? 12 : $end_date->printf("%m");
        
        # Similarly we don't need to go all the way back to January if we start later
        $start_month = ($year > $start_year) ? 1 : $start_month ;        

        # Iterate through all the portals
        foreach $portal (@$portals) {
           


           # Iterate through all the months
           for ($month = $start_month; $month <= $end_month; $month++) {
               
               # get the monthly stats from the request log
               $monthly_stats = $c->model('DB::RequestLog')->get_monthly_portal_stats($portal, $month, $year);
               
               # make sure the dates are in the correct format
               
               $current_date_string = join ('-',($year,$month,'1'));
               

               # say "current date string is $current_date_string";
            
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

# my $portal_list = $c->model('DB::Portal')->list_portals();


say "\ndone";