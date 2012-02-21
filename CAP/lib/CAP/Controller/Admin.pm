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
# Institution functions
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

sub user :Path('user') :Args(1) {
    my ($self, $c, $id) = @_;
    given($c->request->method) {
        when ("GET") {
            if ($id eq 'new') {
                $c->stash->{template} = "admin/user_new.tt";
            } else {
                my $user = $c->model('DB::User')->find({ id => $id });
                $c->detach($c->uri_for_action("error"), [404, "No user with id #" . $id]) if (!$user);
                $c->stash->{user} = $user;
            }
        } when ("POST") {
            if ($id eq 'new') {
                #$c->model('DB::User')->create($c->forward("user_attributes_from_params"));
                $c->message({ type => "error", message => "Would have created a new user, but I'm not sure how to go about doing this just yet." });
                $c->response->redirect($c->uri_for_action("admin/users"));
            } else { # would love to use PUT here but we need Catalyst::Action::REST for that
                my $user = $c->model('DB::User')->find({ id => $id });
                $c->detach($c->uri_for_action("error"), [404, "No user with id #" . $id]) if (!$user);
                $user->update($c->forward("user_attributes_from_params"));
                $c->response->redirect($c->uri_for_action("admin/users"));
            }
        } default {
            $c->detach($c->uri_for_action("error"), [404, "Invalid admin/user request"]);
        }
    }

    return 1;
}

sub user_attributes_from_params :Private {
    my ($self, $c) = @_;
    my $attributes = {
        username    => $c->request->params->{username},
        name        => $c->request->params->{name},
        confirmed   => ($c->request->params->{confirmed} ? 1 : 0),
        active      => ($c->request->params->{active} ? 1 : 0),
        admin       => ($c->request->params->{admin} ? 1 : 0),
    };
    $attributes->{subexpires} = join(" ", $c->request->params->{subexpires}, "00:00:00") if ($c->request->params->{subscriber});
    return $attributes;
}

sub users :Path('users') :Args(0) {
    my ($self, $c, $id) = @_;
    my $rs = $c->model('DB::User');
    $c->stash->{users} = [$rs->all];
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

