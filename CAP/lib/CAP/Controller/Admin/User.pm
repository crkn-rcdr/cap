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

    my @subscriptions = $c->model('DB::UserSubscription')->active_subscriptions;
    my %sub_hash = ();
    foreach my $s (@subscriptions) {
        my $id = $s->get_column('user_id');
        my $portal = $s->get_column('portal_id');
        $sub_hash{$id} = [] unless $sub_hash{id};
        push(@{$sub_hash{$id}}, $portal);
    }
    $c->stash->{subscriptions} = \%sub_hash;

    # Some aggregate statistics about users
    $c->stash->{stats} = {
        active_subscriptions => $c->model('DB::UserSubscription')->active_subscriptions->count,
        expired_subscriptions => $c->model('DB::UserSubscription')->expired_subscriptions,
        unconfirmed_accounts => $c->model('DB::User')->unconfirmed_accounts,
    };
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

    my @roles = $c->model('DB::Roles')->all();

    # TODO: Determine if we need a different portal feature for subscriptions
    my @s_portals = $c->model("DB::Portal")->with_feature("users")->with_names($c->stash->{lang});
    my %names = $c->model("DB::PortalString")->names($c->stash->{lang});
    my @subscriptions = $user->search_related('user_subscriptions');
    
    $c->stash(
        entity => $self->_build_entity($user),
        roles => \@roles,
        portal_names => \%names,
        s_portals => \@s_portals,
        subscriptions => \@subscriptions,
    );

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

    my $data = $c->request->body_parameters;

    my @errors = ();

    push @errors, $c->model('DB::User')->validate($data,
        $c->config->{user}->{fields},
        validate_password => $data->{password},
        current_user => $user->username);

    foreach my $error (@errors) {
        $c->message({ type => 'error', message => $error });
    }

    if (@errors) {
        $c->response->redirect($c->uri_for_action('/admin/user/edit', $id));
        return 1;
    } else {
        my $update = {
            username => $data->{username},
            name => $data->{name},
            class => $data->{class},
            active => $data->{active} ? 1 : 0,
            confirmed => $data->{confirmed} ? 1 : 0,
        };

        $update->{password} = $data->{password} if $data->{password};

        $user->update($update);
        $user->set_roles($data->{role}, $c->model('DB::Roles')->all());

        $c->message({ type => 'success', message => 'user_updated' });
        $c->response->redirect($c->uri_for_action('/admin/user/index'));
        return 0;
    }
}

sub subscription :Local Path('subscription') Args(1) ActionClass('REST') {
}

sub subscription_GET {
    my($self, $c, $id) = @_;
    my $portal = $c->req->params->{portal};
    my $user = $c->model("DB::User")->find($id);
    if (! $user) {
        $c->message({ type => "error", message => "user_not_found" });
        $self->status_not_found($c, message => "No such user");
        return 1;
    }
    my $entity = $user->subscription($portal);
    $c->stash(entity => $entity);
    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

sub subscription_POST {
    my($self, $c, $id) = @_;
    my $user = $c->model('DB::User')->find({ id => $id });
    if (! $user) {
        $c->message({ type => "error", message => "user_not_found" });
        $self->status_not_found($c, message => "No such user");
        return 1;
    }
    my $data = $c->request->body_parameters;

    if ($data->{expires} !~ /^\d{4}-\d{2}-\d{2}$/) {
        $c->message({ type => 'error', message => 'expiry_date_invalid' });
        $c->response->redirect($c->req->uri);
        return 1;
    } else {
        $user->update_or_create_related("user_subscriptions", {
            portal_id => $data->{portal},
            expires => $data->{expires},
            level => $data->{level},
            reminder_sent => $data->{reminder_sent},
            permanent => $data->{permanent} ? 1 : 0,
        });
        $c->message({ type => 'success', message => 'user_subscription_updated' });
        $c->response->redirect($c->uri_for_action("/admin/user/edit", $id));
        return 1;
    }
}

sub delete_subscription :Path('delete_subscription') Args(1) {
    my($self, $c, $id) = @_;
    my $user = $c->model('DB::User')->find({ id => $id });
    if (! $user) {
        $c->message({ type => "error", message => "user_not_found" });
        $self->status_not_found($c, message => "No such user");
        return 1;
    }

    $user->delete_related('user_subscriptions', { portal_id => $c->req->params->{portal} });
    $c->message({ type => 'success', message => 'subscription_deleted' });
    $c->response->redirect($c->uri_for_action("/admin/user/edit", $id));
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
    my $roles = [];
    foreach my $role ($user->search_related('user_roles')) {
        push @{$roles}, $role->get_column('role_id');
    }

    return {
        id => $user->id,
        username => $user->username,
        name => $user->name,
        token => $user->token,
        confirmed => $user->confirmed,
        active => $user->active,
        lastseen => $user->lastseen,
        class => $user->class,
        subexpires => $user->subexpires . "", # Coerce into an integer
        subscriber => $user->has_active_subscription,
        roles => $roles,
    };
}
__PACKAGE__->meta->make_immutable;

1;
