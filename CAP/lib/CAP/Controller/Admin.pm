package CAP::Controller::Admin;
use Moose;
use namespace::autoclean;
use Net::IP;
use feature "switch";
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

sub auto :Private {
    my($self, $c) = @_;

    # Only allow administrators to access any of these functions. Everyone
    # else gets a 404.
    unless ($c->has_role('administrator')) {
        $c->session->{login_redirect} = $c->req->uri;
        $c->response->redirect($c->uri_for('/user', 'login'));
        return 0;
    }

    return 1;
}

sub index :Path :Args(0) {
    my($self, $c) = @_;
    $c->stash(
        entity => {
            institutions => [$c->model('DB::Institution')->list],
            portals => [$c->model('DB::Portal')->list]
        }
    );
    return 1;
}

__PACKAGE__->meta->make_immutable;
