package CAP::Controller::Cron;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ($self, $c) = @_;

    # Call various cron events
    $c->forward('session_cleanup');

    # Return an empty document
    $c->res->status(200);
    $c->res->body("");
    return 1;
}


# Remove stale or expired sessions.
sub session_cleanup :Private {
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
