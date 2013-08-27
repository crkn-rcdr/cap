package CAP::Controller::Reports;
use Moose;
use namespace::autoclean;
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

sub auto :Private {
    my($self, $c) = @_;

    # Users with the admin or reports role may access these functions. Everyone
    # else gets 404ed or redirected to the login page.
    unless ($c->has_role('administrator', 'reports')) {
        #$c->session->{login_redirect} = $c->req->uri;
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
        my($year, $month, $day) = split(/-/, $data->{end});
        $end = DateTime->new({ year => $year, month => $month, day => $day});
    }
    else {
        $end = DateTime->now();
    }

    if ($data->{start}) {
        my($year, $month, $day) = split(/-/, $data->{start});
        $start = DateTime->new({ year => $year, month => $month, day => $day});
    }
    else {
        #$start = $end->clone->subtract(DateTime::Duration->new(days => 30));
        $start = $end->clone;
        $start->subtract(DateTime::Duration->new(days => 30));
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

    return 1;
}

sub index :Path :Args(0) {
    my($self, $c) = @_;
    $c->stash(
        entity => {
            portals => [$c->model('DB::Portal')->list]
        }
    );
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
