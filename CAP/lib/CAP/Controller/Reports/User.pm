package CAP::Controller::Reports::User;
use Moose;
use namespace::autoclean;

use DateTime::Format::ISO8601;

BEGIN { extends 'Catalyst::Controller'; }

sub auto :Private {
    my ($self, $c) = @_;

         # The report type is the second argument in the path 
    my  @args = split (/\//,$c->request->path);
    my $report_type = $args[1];    


    # Users with the admin or reports role may access these functions. Everyone
    # else gets 404ed or redirected to the login page.
    # Authorization for institution stats is done further down the food chain
    unless ( ($c->has_role('administrator', 'reports')) || ($report_type eq 'institution') ) {
        $c->response->redirect($c->uri_for('/user', 'login'));
        return 0;
    }
    
    my $data = $c->req->params;
    my $start;
    my $end;
    my $portal;
    my $page = 1;
    
 
    # Set the reporting period. The default end date is now and the
    # default start date is 30 days before the end date.
    if ($data->{end}) {
        $end = DateTime::Format::ISO8601->parse_datetime($data->{end});
    }
    else {
        $end = DateTime->now();
    }

    if ($data->{start}) {
        $start = DateTime::Format::ISO8601->parse_datetime($data->{start});
    }
    else {
        $start = $end->clone->subtract(days => 30);
    }

    # Limit by portal, if one is defined
    if ($data->{portal}) {
        $portal = $c->model('DB::Portal')->find($data->{portal});
    }

    # If results are paged, get the page number
    $page = $data->{page} if ($data->{page} && $data->{page} =~ /^\d+$/);

    $c->stash(
        start => $start,
        end => $end,
        limit_portal => $portal,
        portals => [$c->model('DB::Portal')->list],
        page => $page
    );

}


=head2 subscriptions

Summarize all subscriptions over the reporting period

=cut

sub subscriptions :Path('subscriptions') Args(0) {
    my ( $self, $c ) = @_;
    my $params = {};
    $params->{completed} = { '<=' => $c->stash->{end}->date, '>=' => $c->stash->{start}->date };
    $params->{portal_id} = $c->stash->{limit_portal}->id if ($c->stash->{limit_portal});

    my $entity = $c->model('DB::Subscription')->search($params);
    $c->stash(
        entity => [$entity->all],
        metrics => $c->model('DB::Subscription')->metrics($entity),
    );
    return 1;
}


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
