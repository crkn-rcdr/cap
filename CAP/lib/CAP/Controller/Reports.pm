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
