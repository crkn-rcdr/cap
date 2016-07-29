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

my $scriptname = 'crondaily';

# Create a CAP object here so that you don't have to do it separately
# for each individual job.
my $c = CAP->new();

my $job;

# List of jobs to run. We can move this to the database or config file later.
# To create a new job put it in a sub and add it to this list.
# To disable a job just comment it out
my @actions = (
    [expiring_subscription_reminder => \&expiring_subscription_reminder],
    [remove_unconfirmed             => \&remove_unconfirmed],
    [session                        => \&session],
    [log_expired_accounts           => \&log_expired_accounts]
);
              
foreach (@actions) {
    my ($job, $ref) = @$_;
    eval { $ref->($c) };
    if ($@) {
        print STDERR "could not perform $job:\n$@";
    } else {
        print "performed $job\n";
    }
}

sub expiring_subscription_reminder {
    my $c = shift;
    
    # Generally we don't want to run this subroutine unless we're on a production server
    # or on the workstation of the maintainer
    return 1 unless ( $c->config->{productionflagfile} && -e $c->config->{productionflagfile} );

    my $days = $c->config->{expiring_acct_reminder};  
    $c->stash->{expiring_in} = $days;

    # Get the cutoff date in a format the database understands
    my $date = new Date::Manip::Date;
    my $datestr = "in " . $days . " business days";
    my $err  = $date->parse($datestr);
    my $cutoff_date = $date->printf("%Y-%m-%d %T");

    # Get today's date because we don't want to be sending messages if the account has already expired
    $datestr = "now";
    $err = $date->parse($datestr);
    my $now = $date->printf("%Y-%m-%d %T");
    
    my $expiring = $c->model('DB::UserSubscription')->expiring_subscriptions($cutoff_date, $now);

    # To reduce the risk of sending multiple emails due to a race
    # condition, only process one user at a time. Get the next user who
    # needs a reminder until there are no more.
    my $id;
    my $portal;
    my $user;
    my $username;
    while (my $user_sub = $c->model('DB::UserSubscription')->next_unsent_reminder($cutoff_date, $now)) {
        # Flag the user as having been reminded. We do this here because,
        # in the case of a race or failure, we'd rather send no email than
        # send 2 or more.
        $user_sub->update({ reminder_sent => 1 })->discard_changes();

        $id = $user_sub->user_id->id;
        $portal = $user_sub->portal_id->id;
        $c->stash->{portal} = $portal;


        # Grab the pertinent info from the user table
        $user = $c->model('DB::User')->get_user_info($id);
        $username = $user->username;

        # Verify that we actually set the flag. Abort if not.
        # NOTE: the discard_changes method above is supposed to read back
        # the current row from the database, but it is difficult to test
        # if this is actually the case.
        last unless ($user_sub->reminder_sent);
        
        # Get the expiry dates as strings       
        my $exp_date = build_date_strings($user_sub->expires);

        # call the subscription method directly since we're not handling an http request
        $c->controller('Mail')->subscription_reminder($c, $user, $exp_date);

        $user->log('REMINDER_SENT', "user $username, $portal portal, expires $exp_date->{en}");
    }

    return 1;

}


sub remove_unconfirmed {
    my $c = shift;
    
    my $days = $c->config->{confirm_grace_period};  
    $c->stash->{remove_before} = $days;

    # Get the cutoff date in a format the database understands
    my $date = new Date::Manip::Date;
    my $datestr = $days . " days ago";
    my $err = $date->parse($datestr);
    my $cutoff_date = $date->printf("%Y-%m-%d %T");
    
    my $num_removed = $c->model('DB::User')->delete_unconfirmed($cutoff_date);

    return 1;
}


sub session {
    my $c = shift;
    my $expired = $c->model('DB::Sessions')->remove_expired();
    return $expired;
}


sub log_expired_accounts {
    my $c = shift;
    my $log_expired = $c->model('DB::UserSubscription')->log_expired_subscriptions($c);
}


sub build_date_strings {
    my $expires = shift;

    my $exp_date = {};

    my $date_eng = new Date::Manip::Date;
    $date_eng->config("Language","English","DateFormat","US"); 
    my $err = $date_eng->parse($expires);
    $exp_date->{en} = $date_eng->printf("%A, %B %d, %Y");

    my $date_fre = new Date::Manip::Date;
    $date_fre->config("Language","French","DateFormat","non-US"); 
    $err = $date_fre->parse($expires);
    $exp_date->{fr} = $date_fre->printf("%A, le %d %B, %Y");	

    return $exp_date;
}

