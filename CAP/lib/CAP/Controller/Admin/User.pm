package CAP::Controller::Admin::User;
use Moose;
use namespace::autoclean;

__PACKAGE__->config(
    map => {
        'text/html' => [ 'View', 'Default' ],
    },
);

BEGIN {extends 'Catalyst::Controller::REST'; }

#
# Index: list users
#

sub index :Path :Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub index_GET {
    my($self, $c) = @_;
    my $list  = {};
    my $users = [$c->model('DB::User')->all];
    $c->stash->{users} = $users;
    foreach my $user (@{$users}) {
        $list->{$user->id} = {
            username => $user->username,
            name     => $user->name,
        };
    }
    $self->status_ok($c, entity => $list);
    return 1;
}

#
# Create: add a new user
#

sub create :Local :Path('create') ActionClass('REST') {
    my($self, $c) = @_;
}

sub create_GET {
}

sub create_POST {
    my($self, $c) = @_;
    my %data;
    foreach my $key (keys %{$c->req->body_parameters}) {
        $data{$key} = $c->req->body_parameters->{$key} if $c->req->body_parameters->{$key};
    }

    my $re_username = $c->config->{user}->{fields}->{username};
    my $re_name     = $c->config->{user}->{fields}->{name};
    my $re_password = $c->config->{user}->{fields}->{password};

    my $error = 0;

    # Validate username
    if ($c->find_user({ username => $data{username} })) {
        $c->message({ type => "error", message => "account_exists" });
        $error = 1;
    } elsif ($data{username} !~ /$re_username/) {
        $c->message({ type => "error", message => "email_invalid" });
        $error = 1;
    }

    # Validate name
    if ($data{name} !~ /$re_name/) {
        $c->message({ type => "error", message => "name_invalid" });
        $error = 1;
    }

    # Validate password
    if ($data{password} ne $data{password2}) {
        $c->message({ type => "error", message => "password_match_failed" });
        $error = 1;
    } elsif ($data{password} !~ /$re_password/) {
        $c->message({ type => "error", message => "password_invalid" });
        $error = 1;
    }
    # won't be needing you anymore
    delete $data{password2};

    if ($error) {
        delete $data{password};
        $c->response->redirect($c->uri_for_action("/admin/user/create", \%data), 303);
        return 1;
    }

    $data{confirmed} = 1;
    $data{active} = 1;
    my $user = $c->model('DB::User')->create(\%data);
    $c->message({ type => "success", message => "user_created" });
    $c->response->redirect($c->uri_for_action("/admin/user/edit", $user->get_column('id')));
    return 1;
}

#
# Edit: edit an existing user
#

sub edit :Local Path('edit') Args(1) ActionClass('REST') {
    my($self, $c, $id) = @_;
}

sub edit_GET {
    my($self, $c, $id) = @_;
    my $user = $c->model('DB::User')->find({ id => $id });
    if (! $user) {
        $c->message({ type => "error", message => "user_not_found" });
        $self->status_not_found($c, message => "No such user");
        return 1;
    }
    $c->stash(entity => $self->_build_entity($user));
    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

sub edit_POST {
    my($self, $c, $id) = @_;
    my $user = $c->model('DB::User')->find({ id => $id });
    if (! $user) {
        $c->message({ type => "error", message => "user_not_found" });
        $self->status_not_found($c, message => "No such user");
        return 1;
    }

    my %data = (%{$c->req->params}); # FIXME: The docs seem to say $c->req->data should work, but it doesn't get defined anywhere

    # Normalize parameters and set defaults
    $data{username} = $user->username unless (defined($data{username}));
    $data{name} = $user->name unless (defined($data{name}));
    $data{class} = $user->class unless (defined($data{class}));
    # ... TODO: more checking

    # Update the user record
    $user->update({
        username => $data{username},
        name => $data{name},
        class => $data{class},
        # ... TODO: more values
    });

    # Set/change the user's password
    if ($data{password}) {
        $user->update({ password => $data{password} });
        $c->message({ type => "success", message => "password_changed" });
    }

    # Set/change the user's subscription expiry date
    if ($data{subexpires}) {
        $user->update({ subexpires => $data{subexpires} });
    }

    # Re-read the user to make sure we have the latest changes.
    # (Otherwise, it seems that the subexpires change doesn't show.)
    $user = $c->model('DB::User')->find({ id => $id });
    
    # Create a response entity
    $c->stash(entity => $self->_build_entity($user));
    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

#
# Delete: remove a user
#

sub delete :Path('delete') Args(1) {
    my($self, $c, $id) = @_;
    my $user = $c->model('DB::User')->find({ id => $id });
    if ($user) {
        $user->delete;
        $c->message({ type => "success", message => "user_deleted" });
    }
    else {
        $c->message({ type => "error", message => "user_not_found" });
    }
    $c->res->redirect($c->uri_for_action('admin/user/index'));
    return 1;
}

#
# Build the user entity
#

sub _build_entity {
    my($self, $user) = @_;
    return {
        id => $user->id,
        username => $user->username,
        name => $user->name,
        token => $user->token,
        confirmed => $user->confirmed,
        active => $user->active,
        admin => $user->admin,
        lastseen => $user->lastseen,
        class => $user->class,
        subexpires => $user->subexpires . "", # Coerce into an integer
        subscriber => $user->has_active_subscription,
    };
}
__PACKAGE__->meta->make_immutable;

1;
