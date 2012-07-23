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
    
    my $expiring = $c->model('DB::User')->expiring_subscriptions($cutoff_date);

    my $exp_acct;
    my $dest_address;
    my $exp_userid;
    foreach $exp_acct (@$expiring) {
        $exp_userid   = $exp_acct->{id};
        $dest_address = $exp_acct->{username};
        # $c->log->error("destination address is $dest_address");
        $c->forward("/mail/subscription_reminder", [$exp_acct, $dest_address]);
        $c->model('DB::User')->set_remindersent($exp_userid,1);  
    }

    return 1;
}


__PACKAGE__->meta->make_immutable;
