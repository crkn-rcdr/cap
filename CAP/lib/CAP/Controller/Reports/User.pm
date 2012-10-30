package CAP::Controller::Reports::User;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

# Summary of user activity on the portal over the past $period days.
sub index :Args(0) {
    my($self, $c) = @_;
    my $period = 30;
    if ($c->req->params->{period}) {
        $period = int($c->req->params->{period});
    }
    $c->stash(
        period        => $period,
        events_report => $c->model('DB::UserLog')->events_report($period),
        user_report   => $c->model('DB::UserLog')->user_activity_report($period),
    );
    return 1;
}

# Summary of a user's activity over the past $period days.
sub event :Path('event') :Args(1) {
    my($self, $c, $event) = @_;
    my $period = 30;
    if ($c->req->params->{period}) {
        $period = int($c->req->params->{period});
    }
    $c->stash(
        period       => $period,
        event_report => $c->model('DB::UserLog')->event_log($event, $period),
        event        => $event
    );
    return 1;
}


# Summary of a user's activity over the past $period days.
sub log :Path('log') :Args(1) {
    my($self, $c, $user_id) = @_;
    my $period = 30;
    if ($c->req->params->{period}) {
        $period = int($c->req->params->{period});
    }
    $c->stash(
        period      => $period,
        user_report => $c->model('DB::UserLog')->user_log($user_id, $period),
        user        => $c->model('DB::User')->find({ id => $user_id }),
    );
    return 1;
}


__PACKAGE__->meta->make_immutable;

1;
