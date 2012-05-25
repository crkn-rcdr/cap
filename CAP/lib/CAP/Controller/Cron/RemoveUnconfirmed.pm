package CAP::Controller::Cron::RemoveUnconfirmed;
use Moose;
use namespace::autoclean;
use Date::Manip::Date;

BEGIN {extends 'Catalyst::Controller'; }



sub index : Private {

    my($self, $c) = @_;

    my $days = $c->config->{confirm_grace_period};  
    $c->stash->{remove_before} = $days;

    # Get the cutoff date in a format the database understands
    my $date = new Date::Manip::Date;
    my $datestr = $days . " days ago";
    my $err = $date->parse($datestr);
    my $cutoff_date = $date->printf("%Y-%m-%d %T");
    
    my $delete = $c->model('DB::User')->delete_unconfirmed($cutoff_date);

    return 1;
}


__PACKAGE__->meta->make_immutable;
