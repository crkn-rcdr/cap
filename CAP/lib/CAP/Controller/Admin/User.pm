package CAP::Controller::Admin::User;
use Moose;
use namespace::autoclean;

__PACKAGE__->config( map => { 'text/html' => [ 'View', 'Default' ], } );

BEGIN {extends 'Catalyst::Controller::REST'; }


sub base : Chained('/') PathPart('admin/user') CaptureArgs(1) {
    my($self, $c, $user_id) = @_;

    # Get the user to view/edit
    my $user = $c->model('DB::User')->find({ id => $user_id });
    if (! $user) {
        $c->message({ type => "error", message => "invalid_user" });
        $self->status_not_found($c, message => "No such user");
        $c->res->redirect($c->uri_for_action("/admin/index"));
        $c->detach();
    }

    $c->stash(entity => {
        user => $user
    });

    return 1;
}

=head2 index

View or edit a user's profile

=cut
sub index : Chained('base') PathPart('') Args(0) ActionClass('REST') {
    my($self, $c, $id) = @_;
}

sub index_GET {
    my($self, $c) = @_;
    my $user = $c->stash->{entity}->{user};
    my @subscriptions = ();

    foreach my $portal ($c->model('DB::Portal')->list_subscribable) {
        push(@subscriptions, {
            portal => $portal,
            active => $user->subscription_active($portal),
            subscription => $user->subscription($portal)
        });
    }

    $c->stash->{entity}->{roles} = [$c->model('DB::Roles')->list];
    $c->stash->{entity}->{subscriptions} = \@subscriptions;
    $c->stash->{entity}->{institutions} = [$c->model('DB::Institution')->list];
    $c->stash->{entity}->{managed_institutions} = [$user->managed_institutions];

    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

sub index_POST {
    my($self, $c) = @_;
    my $user = $c->stash->{entity}->{user};
    my $data = $c->request->body_parameters;

    my $action = $data->{update};

    if (! $action) {
        warn "No action";
    }
    elsif ($action eq 'account') {
        $c->stash(update => $user->update_if_valid($data));
        $c->detach('/admin/user/updated', ['tab_account']);
    }
    elsif ($action eq 'roles') {
        $c->stash(update => $user->update_roles_if_valid($data));
        $c->detach('/admin/user/updated', ['tab_roles']);
    }
    else {
        warn "Unspecified action";
    }
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
    $c->response->redirect($c->uri_for_action("/admin/user/index", [$user->get_column('id')]));
    return 1;
}

sub subscription :Local Path('subscription') Args(1) ActionClass('REST') {
    my($self, $c, $id) = @_;
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
        $c->response->redirect($c->uri_for_action('/admin/user/index', [$id]));
        $c->detach();
    } else {
        $user->update_or_create_related("user_subscriptions", {
            portal_id => $data->{portal},
            expires => $data->{expires},
            level => $data->{level},
            reminder_sent => $data->{reminder_sent} ? 1 : 0,
            permanent => $data->{permanent} ? 1 : 0,
        });
        my $uri = $c->uri_for_action("/admin/user/index", [$id]);
        $uri->fragment('#tab_subscriptions');
        $c->response->redirect($uri);
        return 1;
    }
}

sub delete_subscription :Path('delete_subscription') Args(1) {
    my($self, $c, $id) = @_;
    my $user = $c->model('DB::User')->find({ id => $id });
    if (! $user) {
        $c->message({ type => "error", message => "user_not_found" });
        $self->status_not_found($c, message => "No such user");
        $c->response->redirect($c->uri_for_action('/admin/user/index'));
        $c->detach();
    }

    $user->delete_related('user_subscriptions', { portal_id => $c->req->params->{portal} });
    my $uri = $c->uri_for_action("/admin/user/index", [$id]);
    $uri->fragment('tab_subscriptions');
    $c->response->redirect($uri);
    return 1;
}

sub add_institution :Path('add_institution') Args(1) {
    my($self, $c, $id) = @_;
    my $user = $c->model('DB::User')->find({ id => $id });
    if (! $user) {
        $c->message({ type => "error", message => "user_not_found" });
        $self->status_not_found($c, message => "No such user");
        $c->response->redirect($c->uri_for_action('/admin/user/index'));
        $c->detach();
    }

    my $institution = $c->model('DB::Institution')->find({ id => $c->req->params->{institution_id} });
    if (! $institution) {
        $c->message({ type => "error", message => "institution_not_found" });
        $self->status_not_found($c, message => "No such institution");
        $c->response->redirect($c->uri_for_action('/admin/user/index', [$user->id]));
        $c->detach();
    }

    $c->model('DB::InstitutionMgmt')->update_or_create({ user_id => $user->id, institution_id => $institution->id });
    my $uri = $c->uri_for_action('/admin/user/index', [$user->id]);
    $uri->fragment('tab_institutions');
    $c->response->redirect($uri);
    $c->detach();
}

sub remove_institution :Path('remove_institution') Args(1) {
    my($self, $c, $id) = @_;
    my $user = $c->model('DB::User')->find({ id => $id });
    if (! $user) {
        $c->message({ type => "error", message => "user_not_found" });
        $self->status_not_found($c, message => "No such user");
        $c->response->redirect($c->uri_for_action('/admin/user/index'));
        $c->detach();
    }

    my $institution = $c->model('DB::Institution')->find({ id => $c->req->params->{institution_id} });
    if (! $institution) {
        $c->message({ type => "error", message => "institution_not_found" });
        $self->status_not_found($c, message => "No such institution");
        $c->response->redirect($c->uri_for_action('/admin/user/index', $user->id));
        $c->detach();
    }
    my $link = $c->model('DB::InstitutionMgmt')->find({ user_id => $user->id, institution_id => $institution->id });
    $link->delete if ($link);
    my $uri = $c->uri_for_action('/admin/user/index', [$user->id]);
    $uri->fragment('tab_institutions');
    $c->response->redirect($uri);
    $c->detach();
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


=head2 updated

Methods that update an institution detach to here to check for success and to genereate messages.

=cut
sub updated :Private {
    my($self, $c, $fragment) = @_;
    my $update = $c->stash->{update};
    my $user = $c->stash->{entity}->{user};

    if ($update->{valid}) {
        $self->status_ok($c, entity => $c->stash->{entity});
    }
    else {
        foreach my $error (@{$update->{errors}}) {
            $c->message({ type => "error", %{$error} });
        }
        $self->status_bad_request($c, message => "Input is invalid");
    }

    $c->message({ type => "success", message => "admin_updated_entity", params => [ $user->username ] });
    my $uri = $c->uri_for_action('/admin/user/index', [$user->id]);
    $uri->fragment($fragment) if ($fragment);
    $c->res->redirect($uri);
    $c->detach();
}

__PACKAGE__->meta->make_immutable;

1;
