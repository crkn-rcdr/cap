package CAP::Controller::Admin;
use Moose;
use namespace::autoclean;
use Net::IP;
use feature "switch";

BEGIN {extends 'Catalyst::Controller'; }


sub auto :Private {
    my($self, $c) = @_;

    # Require SSL for all operations
    $c->require_ssl;

    # Only allow administrators to access any of these functions. Everyone
    # else gets a 404.
    unless ($c->user_exists && $c->user->admin) {
        $c->session->{login_redirect} = $c->req->uri;
        $c->response->redirect($c->uri_for('/user', 'login'));
        return 0;
    }

    return 1;
}

sub index :Path :Args(0) {
    my($self, $c) = @_;
    $c->stash->{users} = $c->model('DB::User')->count;
    $c->stash->{subscribers} = $c->model('DB::User')->subscribers;
    return 1;
}


#
# Everything below here should be moved into an appropriate Admin/X.pm
# controller
#




sub collections :Path('collections') :Args(0) {
    my($self, $c, $id) = @_;

    if ($c->request->params->{update}) {
        if ($c->request->params->{update} eq 'collection') {
            my $collection = $c->model('DB::Collection')->find({ id => $c->request->params->{id} });
            if ($collection) {
                $collection->update({
                    price => $c->request->params->{price},
                });
            }
        }
        elsif ($c->request->params->{update} eq 'add_collection') {
            $c->model('DB::Collection')->create({
                id    => $c->req->params->{id},
                price => $c->req->params->{price},
            });
        }
    }

    # Get a list of all collections
    $c->stash->{collections} = [$c->model('DB::Collection')->all];

    return 1;
}

sub promocodes :Path('promocodes') :Args(0) {
    my($self, $c) = @_;

    # TODO: this does not do ANY validity checking...
    if ($c->req->params->{action} eq 'add') {
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

