#!/usr/bin/perl

# Utility that migrates user data from user table to user_subscription table

use 5.010;
use strict;
use warnings;

use feature qw(switch say);

use lib '../lib';
use CAP;

my $c = CAP->new();

my $result = $c->model('DB::User')->get_all_data();

my $row;
my $error;

my $userid;
my $portalid = ( defined($c->portal) ) ? $c->portal: 'eco';
my $level = 1;
my $permanent;
my $remindersent;
my $expires;
my $class;

# Build a hash to map out the user levels
my %level = (
                'paid'       => 2,
                'basic'      => 0,
                'trial'      => 1,
                'permanent'  => 2,
        
             );

# Iterate through all the user ids and insert new row into user_subscription
foreach $row (@$result){
  
  $userid = $row->id;
  $remindersent = $row->remindersent;

  $expires = ( defined ($row->subexpires) ) ? $row->subexpires : '00-00-00 00:00:00'; 
    
  $class = $row->class;
  $level = ( defined ($level{$class}) ) ? $level{$class} : 0;
  $permanent = ($class eq 'permanent') ? 1 : 0;
  
  $error = $c->model('DB::UserSubscription')->subscribe($userid, $portalid, $level, $expires, $permanent);
}

say "\ndone";