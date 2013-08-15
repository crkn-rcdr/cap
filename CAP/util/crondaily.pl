#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use feature qw(switch say);

use FindBin;
use lib "$FindBin::Bin/../lib";

use CAP;
use Date::Manip::Date;

my $scriptname = 'crondaily';

# Create a CAP object here so that you don't have to do it separately
# for each individual job.
my $c = CAP->new();


my  $set_pid = $c->model('DB::Info')->obtain_pid_lock( $scriptname, $$ );



unless (  $set_pid )  {
    $c->model('DB::CronLog')->create(
        {
            action     => 'crondaily',
            ok              => 0,
            message => "$scriptname already running; killing myself as an example to others"
        }
    );
    die "crondaily.pl: detected another version of myself, dying gracefully\nif the existing process is not responding please kill it and delete the crondaily.pl row in cap.info";
}

my $job;

# List of jobs to run. We can move this to the database or config file later.
# To create a new job put it in a sub and add it to this list.
# To disable a job just comment it out
my %actions = (
                expiring_subscription_reminder  =>  \&expiring_subscription_reminder,
                remove_unconfirmed              =>  \&remove_unconfirmed,
                session                         =>  \&session,
              );
              
              
foreach $job (keys(%actions)) {

    eval { $actions{$job}->($c) };
    if ( ($@) ) {
        $c->model('DB::CronLog')->create({
                   action      => 'crondaily',
                   ok              => 0,
                   message => "error: $@; could not perform $job"
        });          
    }

}

my $delete_pid = $c->model('DB::Info')->delete_pid($scriptname, $$);

$c->model('DB::CronLog')->create({
               action        => 'crondaily',
               ok                 => 1,
               message   => "done"
});


sub expiring_subscription_reminder {
    
    
    my $c = shift();
    
    # Generally we don't want to run this subroutine unless we're on a production server
    # or on the workstation of the maintainer
    return 1 unless ( $c->config->{productionflagfile} && -e $c->config->{productionflagfile} );
   
    $c->model('DB::CronLog')->create({
               action       => 'crondaily->expiring_subscription_reminder',
               ok               => 0,
               message => "running expiring_trial_reminder"
    }); 
   
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

        # Verify that we actually set the flag. Log an error and abort if not.
        # NOTE: the discard_changes method above is supposed to read back
        # the current row from the database, but it is difficult to test
        # if this is actually the case.
        unless ($user_sub->reminder_sent) {
            $c->model('DB::CronLog')->create({
                action       => 'crondaily->expiring_subscription_reminder',
                ok               => 0,
                message => sprintf("Failed to set remindersent=1 for user %d (%s)", $id, $username)
            });
            last;
        }
        
        # Get the expiry dates as strings       
        my $exp_date = build_date_strings($user_sub->expires);

        # call the subscription method directly since we're not handling an http request
        $c->controller('Mail')->subscription_reminder($c, $user, $exp_date);

        $c->model('DB::CronLog')->create({
                action       => 'crondaily->expiring_subscription_reminder',
                ok               => 1,
                message => sprintf("Reminder sent: user id=%d (%s); %s account expires %s",
                                                             $user->id, $username, $user_sub->level, $user_sub->expires)
        });

        $user->log('REMINDER_SENT', "user $username, $portal portal, expires $exp_date->{en}");

    }

    return 1;

}


sub remove_unconfirmed {
    
    my $c = shift();
    
   
    $c->model('DB::CronLog')->create({
               action       => 'crondaily->remove_unconfirmed',
               ok               => 0,
               message => "running remove_unconfirmed"
    }); 
    
    my $days = $c->config->{confirm_grace_period};  
    $c->stash->{remove_before} = $days;

    # Get the cutoff date in a format the database understands
    my $date = new Date::Manip::Date;
    my $datestr = $days . " days ago";
    my $err = $date->parse($datestr);
    my $cutoff_date = $date->printf("%Y-%m-%d %T");
    
    my $num_removed = $c->model('DB::User')->delete_unconfirmed($cutoff_date);
    $c->model('DB::CronLog')->create({
        action  => 'crondaily->remove_unconfirmed',
        ok      => 1,
        message => "Removed $num_removed unconfirmed users",
    });

    return 1;
}


sub session {

    my $c = shift();
    $c->model('DB::CronLog')->create({
               action  => 'crondaily->session',
               ok      => 0,
               message => "running session"
    }); 
    my $expired = $c->model('DB::Sessions')->remove_expired();
    if ($expired) {
        $c->model('DB::CronLog')->create({
            action  => 'crondaily->session',
            ok      => 1,
            message => "$expired expired sessions removed",
        });
    }
}


sub build_date_strings {
    
        my $expires = shift();

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

