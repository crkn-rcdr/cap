package CAP::Controller::Admin;
use Moose;
use namespace::autoclean;

__PACKAGE__->config( map => { 'text/html' => [ 'View', 'Default' ], },);

BEGIN { extends 'Catalyst::Controller::REST'; }

sub auto :Private {
    my($self, $c) = @_;

    # Only allow administrators to access any of these functions. Everyone
    # else gets a 404.
    unless ($c->has_role('administrator')) {
        #$c->session->{login_redirect} = $c->req->uri;
        $c->res->redirect($c->uri_for_action('user/login'));
        $c->detach();
    }

    # stupid Catalyst::Controller::REST hack
    $c->stash->{current_view} = undef;

    return 1;
}

sub index :Path :Args(0) ActionClass('REST') {
    my($self, $c) = @_;
    $c->stash(
        entity => {
            discounts => [$c->model('DB::Discounts')->list],
            institutions => [$c->model('DB::Institution')->list],
            portals => [$c->model('DB::Portal')->list],
            users => [$c->model('DB::User')->filter()],
            user_count => $c->model('DB::User')->search()->count
        }
    );
}

sub index_GET {
    my($self, $c) = @_;
    return 1;
}

sub index_POST {
    my($self, $c) = @_;
    my $submit =  $c->req->body_parameters->{submit} || "";

    if ($submit eq 'users') {
        $c->stash->{entity}->{users} = $c->model('DB::User')->filter($c->req->body_parameters);
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;
