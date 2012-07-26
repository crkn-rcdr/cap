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

    my $exp_acct;
    my $dest_address;
    my $exp_userid;

    
    foreach $exp_acct (@$expiring) {
        $exp_userid   = $exp_acct->{id};
        $dest_address = $exp_acct->{username};

        
        #get the expiry dates as strings       
        my $expires = $exp_acct->{expires};
        my $exp_date = build_date_strings($expires);

        
        $c->forward("/mail/subscription_reminder", [$exp_acct, $exp_date]);
        $c->model('DB::User')->set_remindersent($exp_userid,1);  
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
        my $err = $date_fre->parse($expires);
        $exp_date->{fr} = $date_fre->printf("%A, le %d %B, %Y");	

        return $exp_date;
}

__PACKAGE__->meta->make_immutable;
