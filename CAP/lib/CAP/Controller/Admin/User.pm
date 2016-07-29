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

    $c->stash->{entity}->{roles} = $c->config->{user_roles};
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
        my $valid_roles = $c->config->{user_roles};
        $c->stash(update => $user->update_roles_if_valid($data, $valid_roles));
        $c->detach('/admin/user/updated', ['tab_roles']);
    }
    else {
        warn "Unspecified action";
    }
    return 1;
}


=head2

Create a new user administratively.

=cut
sub create :Local :Path('create') ActionClass('REST') {
    my($self, $c) = @_;
}

sub create_GET {
    my($self, $c) = @_;
    return 1;
}

sub create_POST {
    my($self, $c) = @_;
    my $data = $c->req->body_parameters;
    my @errors = ();

    foreach my $k (qw/username email password password_check/) { trim($data->{$k}) if (defined($data->{k})) }

    my $created = $c->model('DB::User')->create_if_valid({
        username => $data->{username},
        email => $data->{email},
        name => $data->{name},
        password => $data->{password},
        password_check => $data->{password_check},
        active => 1,
        confirmed => 1
    });

    if ($created->{user}) {
        $c->res->redirect($c->uri_for_action('/admin/user/index', [ $created->{user}->id ]));
        $c->detach();
    }
    else {
        foreach my $error (@{$created->{errors}}) {
            $c->message({ type => "error", %{$error} });
        }
        $self->status_bad_request($c, message => "Input is invalid");
        return 1;
    }
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

Methods that update a user detach to here to check for success and to genereate messages.

=cut
sub updated :Private {
    my($self, $c, $fragment) = @_;
    my $update = $c->stash->{update};
    my $user = $c->stash->{entity}->{user};

    if ($update->{valid}) {
        $self->status_ok($c, entity => $c->stash->{entity});
        $c->message({ type => "success", message => "admin_updated_entity", params => [ $user->username ] });
    }
    else {
        foreach my $error (@{$update->{errors}}) {
            $c->message({ type => "error", %{$error} });
        }
        $self->status_bad_request($c, message => "Input is invalid");
    }

    my $uri = $c->uri_for_action('/admin/user/index', [$user->id]);
    $uri->fragment($fragment) if ($fragment);
    $c->res->redirect($uri);
    $c->detach();
}

__PACKAGE__->meta->make_immutable;

1;
