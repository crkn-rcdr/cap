package CAP::Controller::Cron::ExpiringTrialReminder;
use Moose;
use namespace::autoclean;
use Date::Manip::Date;

BEGIN {extends 'Catalyst::Controller'; }



sub index : Private {

    my($self, $c) = @_;

    my $days = $c->config->{expiring_acct_reminder};  
    $c->stash->{expiring_in} = $days;

    # Get the cutoff date in a format the database understands
    my $date = new Date::Manip::Date;
    my $datestr = "in " . $days . " business days";
    my $err = $date->parse($datestr);
    my $cutoff_date = $date->printf("%Y-%m-%d %T");

    # Get today's date because we don't want to be sending messages if the account has already expired
    $datestr = "now";
    $err = $date->parse($datestr);
    my $now = $date->printf("%Y-%m-%d %T");
    
    
    my $expiring = $c->model('DB::User')->expiring_subscriptions($cutoff_date, $now);

    # To reduce the risk of sending multiple emails due to a race
    # condition, only process one user at a time. Get the next user who
    # needs a reminder until there are no more.
    while (my $user = $c->model('DB::User')->next_unsent_reminder($cutoff_date, $now)) {

        # Flag the user as having been reminded. We do this here because,
        # in the case of a race or failure, we'd rather send no email than
        # send 2 or more.
        $user->update({ remindersent => 1 })->discard_changes();

        # Verify that we actually set the flag. Log an error and abort if not.
        # NOTE: the discard_changes method above is supposed to read back
        # the current row from the database, but it is difficult to test
        # if this is actually the case.
        unless ($user->remindersent) {
            $c->model('DB::CronLog')->create({
                action  => 'reminder_notice',
                ok      => 0,
                message => sprintf("Failed to set reminderset=1 for user %d (%s)", $user->id, $user->username)
            });
            last;
        }

        # Get the expiry dates as strings       
        my $exp_date = build_date_strings($user->subexpires);

        $c->forward("/mail/subscription_reminder", [$user, $exp_date]);

        $c->model('DB::CronLog')->create({
                action  => 'reminder_notice',
                ok      => 1,
                message => sprintf("Reminder sent: id=%d (%s); %s account expires %s",
                    $user->id, $user->username, $user->class, $user->subexpires)
        });
        $user->log('REMINDER_SENT');

    }

    return 1;
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

__PACKAGE__->meta->make_immutable;
