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
    $c->stash->{users} = $c->model('DB::User')->count;
    $c->stash->{subscribers} = $c->model('DB::UserSubscription')->active_subscriptions;
    return 1;
}


#
# Everything below here should be moved into an appropriate Admin/X.pm
# controller
#

# Will be moved to Admin/Usage.pm when there are more than a couple of tables to load
sub usage :Path('usage') :Args(0) {
    my($self, $c) = @_;
    $c->stash->{user_requests} = $c->model('DB::User')->requests;
    $c->stash->{institution_requests} = $c->model('DB::Institution')->requests;
    return 1;
}

sub collections :Path('collections') :Args(0) {
    my($self, $c, $id) = @_;

    # Get a list of all collections
    $c->stash->{collections} = [$c->model('DB::Collection')->all];

    return 1;
}

sub create_collection :Path('create_collection') :Args(0) {
    my($self, $c) = @_;
    my $id = $c->req->body_params->{id};
    $c->model('DB::Collection')->find_or_create({ id => $id });
    $c->response->redirect($c->uri_for_action("/admin/collections"));
    return 1;
}

sub promocodes :Path('promocodes') :Args(0) {
    my($self, $c) = @_;

    # TODO: this does not do ANY validity checking...
    if ($c->req->params->{update} eq 'add_promocode') {
        $c->model('DB::Promocode')->create({
            id => $c->req->params->{id},
            expires => $c->req->params->{expires},
            amount => $c->req->params->{amount},
        });

    }

    $c->stash->{promocodes} = [$c->model('DB::Promocode')->all];

    return 1;
}


__PACKAGE__->meta->make_immutable;

