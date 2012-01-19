package CAP::Controller::Cron::Session;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub index :Private {
    my($self, $c) = @_;
    my $expired = $c->model('DB::Sessions')->remove_expired();
    if ($expired) {
        $c->model('DB::CronLog')->log(
            action  => 'session_cleanup',
            ok      => 1,
            message => "$expired expired sessions removed",
        );
    }
    return 1;
}


__PACKAGE__->meta->make_immutable;

1;
