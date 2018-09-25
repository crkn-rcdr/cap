package CAP::Controller::User;
use Moose;
use namespace::autoclean;
use Date::Manip::Date;
use Date::Manip::Delta;
use Text::Trim qw/trim/;

# If an action path is in ANONYMOUS_ACTIONS, it can only be accessed by anonymous
# (not logged in) users. Otherwise,  the reverse is true: only logged in
# users can access the function. All other requests are redirected to
# /user/login. The exception is the actions in UNIVERSAL_ACTIONS, which
# are accessible to all.
use constant UNIVERSAL_ACTIONS => qw{ user/subscription/index };
use constant ANONYMOUS_ACTIONS => qw{ user/create user/confirm user/confirmation_required user/login user/reconfirm user/reset user/reset_password };

__PACKAGE__->config( default => 'text/html', map => { 'text/html' => [ 'View', 'Default' ] });


BEGIN { extends 'Catalyst::Controller::REST'; }


sub auto :Private {
    my($self, $c) = @_;

    my $action = $c->action;
    # The subscriptio page is viewable by everyone.
    if (grep(/$action/, UNIVERSAL_ACTIONS)) {
        ;
    }
    # Actions relating to creating a new account, logging in, or
    # recovering a lost password are only available to anonymous users.
    elsif (grep(/$action/, ANONYMOUS_ACTIONS)) {
        if ($c->user_exists) {
            $c->response->redirect($c->uri_for_action('/index'));
            return 0;
        }
    }
    else {
        unless ($c->user_exists) {
            # All other requests are limited to logged in users; redirect
            # anonymous requests to the login page.
            $c->response->redirect($c->uri_for_action('/user/login'));
            return 0;
        }
    }

    # stupid Catalyst::Controller::REST hack
    $c->stash->{current_view} = undef;

    return 1;
}


=head2 profile

Display or edit the user's profile

=cut

sub profile : Path('profile') Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub profile_GET {
    my($self, $c) = @_;

    my @subscriptions;
    foreach my $portal ($c->model('DB::Portal')->list_subscribable) {
        my $institutional = 0;
        if ($c->institution) {
            $institutional = $c->institution->subscribes_to($portal);
        }
        push(@subscriptions, {
            portal => $portal,
            active => $c->user->subscription_active($portal), 
            subscription => $c->user->subscription($portal),
            institutional => $institutional
        });
    }

    $c->stash(
        entity => {
            subscriptions => \@subscriptions,
            institutions => [$c->user->managed_institutions],
            history => [$c->user->subscription_history]
        }
    );

    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

sub profile_POST {
    my($self, $c) = @_;
    my $update;

    my $data = $c->request->body_parameters;
    foreach my $k (qw/username password password_check/) { trim $data->{$k}; }

    if (! $c->authenticate({ id => $c->user->id, password => $data->{current_password} })) {
        $update->{valid} = 0;
        $update->{errors} = [  { message => 'invalid_password_check' } ];
    }
    else {
        # The user is only allowed to update certain fields. The others
        # remain unchanged.
        $update = $c->user->update_if_valid(
            {
                username => $data->{username},
                email => $data->{email},
                name => $data->{name},
                password => $data->{password},
                password_check => $data->{password_check},
                active => $c->user->active,
                confirmed => $c->user->confirmed
            },
        );
    }

    if ($update->{valid}) {
        $self->status_ok($c, entity => $c->stash->{entity});
        $c->message({ type => "success", message => "user_account_updated" });
        $c->persist_user();
    }
    else {
        foreach my $error (@{$update->{errors}}) {
            $c->message({ type => "error", %{$error} });
        }
        $self->status_bad_request($c, message => "Input is invalid");
    }
    my $uri = $c->uri_for_action('/user/profile');
    $uri->fragment('tab_account');
    $c->res->redirect($uri);
    $c->detach();

    return 1;
}

sub login :Path('login') Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub login_GET {
    my($self, $c) = @_;
    return 1;
}

sub login_POST {
    my ( $self, $c ) = @_;
    my $data = $c->req->body_parameters;
    $data->{submit} = 'login' unless ($data->{submit});
    foreach my $k (qw/username email password password_check/) { trim($data->{$k}) if (defined($data->{k})) }

    if ($data->{submit} eq 'create') {
        $c->forward('/user/create', [ $data ]);
    }
    else { # Default is "login"
        $c->forward('/user/do_login', [ $data ]);
    }

    return 1;
}

sub do_login :Private {
    my ($self, $c, $data) = @_;
    my $username    = trim($c->request->params->{username})   || "";
    my $password    = trim($c->request->params->{password})   || "";
    my $persistent  = $c->request->params->{persistent} || 0;
    my $user = $c->model('DB::User')->find_user($username);


    if (! $user) { # No account exists
        $c->message({ type => "error", message => "invalid_login" });
    }
    elsif (! $user->active) { # Treat inactive accounts the same as an invalid username
        $c->message({ type => "error", message => "invalid_login" });
    }
    elsif (! $user->confirmed) { # Redirect unconfirmed users to a confirmation required page
        $c->response->redirect($c->uri_for_action('/user/confirmation_required', [$username]));
        $c->detach();
    }
    elsif ($c->authenticate(({ id => $user->id, password => $password }))) { # Correct login credentials
        $c->user->update({ last_login => DateTime->now() });
        $c->user->log('LOGIN', sprintf("from: %s", $c->req->address));
        $c->forward('/user/handle_persistence', [$persistent]);

        $c->update_session(1);

        # If there is an origin URL, return to it. Otherwise, go to the
        # user's profile.
        if ($c->session->{origin} && $c->session->{origin}->{uri}) {
            $c->res->redirect($c->session->{origin}->{uri});
        }
        else {
            $c->res->redirect($c->uri_for_action('/user/profile'));
        }
        $c->detach();
    }
    else { # Incorrect login credentials
        $c->message({ type => "error", message => "invalid_login" });
        $user->log_failed_login();
    }

    # Display the login page
    return 1;
}

# Create a new account
sub create :Private {
    my($self, $c, $data) = @_;
    my @errors = ();

    my $created = $c->model('DB::User')->create_if_valid({
        username => $data->{username},
        email => $data->{email},
        name => $data->{name},
        password => $data->{password},
        password_check => $data->{password_check},
        active => 1,
        confirmed => 0
    });

    if ($created->{user}) {
        $created->{user}->log("CREATED", sprintf("Userid: %s; username: %s", $created->{user}->email, $created->{user}->name));

        # Send the confirmation/activation email
        my $confirm_link = $c->uri_for_action('user/confirm', $created->{user}->confirmation_token);
        $c->model("Mailer")->user_activate($c, $created->{user}->email, $created->{user}->name, $confirm_link);
        $c->response->redirect($c->uri_for_action('/user/confirmation_required', [$created->{user}->email]));
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


sub handle_persistence :Private {
    my($self, $c, $persistent) = @_;
    if ($persistent) {
        # Set the session to be persistent or a session cookie.
        my $token = $c->model('DB::User')->set_token($c->user->id);
        $c->response->cookies->{$c->config->{cookies}->{persist}} = {
            domain => $c->stash->{cookie_domain},
            value => $token,
            expires => time() + 7776000,
            httponly => 1
        };
    }
    else {
        # Clear any pre-existing persistence cookies and tokens
        $c->model('DB::User')->clear_token($c->user->id);
        $c->response->cookies->{$c->config->{cookies}->{persist}} = { 
            domain => $c->stash->{cookie_domain},
            value => '',
            expires => 0,
            httponly => 1
        }
    }
    return 1;
}

sub confirmation_required :Path('confirmation_required') :Args(1) {
    my($self, $c, $username) = @_;
    $c->stash->{username} = $username;
    return 1;
}

sub reconfirm :Path('reconfirm') :Args(1) {
    my($self, $c, $email) = @_;

    # Retrieve the record for the user
    my $new_user = $c->find_user({ email => $email, confirmed => 0 });

    # Make sure the user is valid and not yet confirmed
    if (! $new_user) {
        $c->response->redirect($c->uri_for('/index'));
    }

    $c->stash->{formdata} = {
        username => $email,
        name     => $new_user->name,
    };

    # Resend an activation email
    my $confirm_link = $c->uri_for_action('user/confirm', $new_user->confirmation_token);
    $c->model("Mailer")->user_activate($c, $email, $new_user->name, $confirm_link);

    $c->response->redirect($c->uri_for_action('/user/confirmation_required', [$email]));
    return 1;
}




sub logout :Path('logout') :Args(0) {
    my($self, $c) = @_;

    # Log out and clear any persistent token and cookie.
    $c->model('DB::User')->clear_token($c->user->id);
    $c->response->cookies->{$c->config->{cookies}->{persist}} = {
        domain => $c->stash->{cookie_domain},
        value => '',
        expires => 0,
        httponly => 1
    };
    $c->user->log('LOGOUT');
    $c->logout();
    $c->update_session(1);

    if ($c->session->{origin} && $c->session->{origin}->{uri}) {
        $c->res->redirect($c->session->{origin}->{uri});
    }
    else {
        $c->res->redirect($c->uri_for_action('/user/login'));
    }
    $c->detach();
}


sub confirm :Path('confirm') :Args(1) {
    my($self, $c, $auth) = @_;

    # Either confirm and log in the new user or silently fail. Either way,
    # forward to the main index page, with a message explaining what happened.
    my $id = $c->model('DB::User')->confirm_new_user($auth);
    if ($id) {
        $c->set_authenticated($c->find_user({id => $id}));
        $c->persist_user();
        $c->user->update({ last_login => DateTime->now() });
        $c->user->log('CONFIRMED');
        $c->response->redirect($c->uri_for_action("/user/profile"));
    } else {
        $c->response->redirect($c->uri_for_action('/index'));
    }
    return 0;
}


=head2

Form to send an email to reset a forgotten password.

=cut
sub reset :Path('reset') Args(0) ActionClass('REST') {
    my($self, $c) = @_;
    return 1;
}

sub reset_GET {
    my($self, $c) = @_;
    return 1;
}

sub reset_POST {
    my($self, $c) = @_;
    my $data = $c->request->body_parameters;
    foreach my $k (qw/username/) { trim($data->{$k}) if (defined($data->{k})) }
    my $user = $c->model('DB::User')->find_user($data->{username});
    my $mail_sent = 0;

    if (! $user) {
        $c->message({ type => 'error', message => 'user_not_found' });
        $self->status_not_found($c, message => "No such user");
    }
    else {
        my $confirm_link = $c->uri_for_action('user/reset_password', $user->confirmation_token);
        $c->model('Mailer')->user_reset($c, $user->email, $confirm_link);
        $user->log("RESET_REQUEST", sprintf("from %s", $c->req->address));
    }

    $c->stash(user => $user);
}


=head2

Allow a user to reset their password, if they have a valid reset token.

=cut
sub reset_password :Path('reset_password') Args(1) ActionClass('REST') {
    my($self, $c, $token) = @_;
    return 1;
}

sub reset_password_GET {
    my($self, $c, $token) = @_;

    # Retrieve the user id (if any) associated with this token.
    my $user_id = $c->model('DB::User')->validate_confirmation($token);
    $c->stash(token => $token, user_id => $user_id);

    return 1;
}

sub reset_password_POST {
    my($self, $c, $token) = @_;
    my $data = $c->request->body_parameters;
    foreach my $k (qw/username password password_check/) { trim $data->{$k}; }

    # Retrieve the user id (if any) associated with this token.
    my $user_id = $c->model('DB::User')->validate_confirmation($token);

    # If we got a valid user id, check the supplied passwords. If they are
    # alright, change the user's password and forward to their profile.
    my $user;
    if ($user_id) {
        $user = $c->model('DB::User')->find({ id => $user_id }); # FIXME: the validate_confirmation really should return this in the first palce.
        my $update = $user->update_if_valid({
            username => $user->username,
            email => $user->email,
            name => $user->name,
            password => $data->{password},
            password_check => $data->{password_check},
            active => $user->active,
            confirmed => $user->confirmed
        });

        if ($update->{valid}) {
            $self->status_ok($c, entity => $c->stash->{entity});
            $c->message({ type => "success", message => "user_password_reset" });
            $c->set_authenticated($c->find_user({id => $user_id}));
            $c->persist_user();
            $user->update({ last_login => DateTime->now() });
            $user->log("RESET_REQUEST", sprintf("from %s", $c->req->address));
            $c->res->redirect($c->uri_for_action('/user/profile'));
            $c->detach();
        }
        else {
            foreach my $error (@{$update->{errors}}) {
                $c->message({ type => "error", %{$error} });
            }
            $self->status_bad_request($c, message => "Input is invalid");
        }
    }

    $c->stash(token => $token, user_id => $user_id);
    return 1;
}

sub subscribe_finalize : Private
{
    my($self, $c, $success, $payment_id, $foreign_id) = @_;
    my $subscription = $c->user->retrieve_subscription;
    my $payment = $c->user->retrieve_payment($foreign_id);

    if (!($subscription && $payment)) {
        $c->message({ type => "error", message => "payment_error" });
        $self->status_bad_request($c, message => "Error processing payment");
        $c->res->redirect($c->uri_for_action("/user/profile"));
        $c->detach();
    }

    if (! $success) {
        $c->user->close_subscription($payment);
        $c->message({ type => "error", message => "payment_failed" });
        $self->status_bad_request($c, message => "Your payment was not processed");
        $c->res->redirect($c->uri_for_action("/user/profile"));
        $c->detach();
    }

    $c->log->debug("User/subscribe_finalize: Success:$success; PaymentID: $payment_id; ForeignID:$foreign_id ") if ($c->debug);

    # Finalize the subscription
    $c->user->set_subscription($subscription);
    $subscription = $c->user->close_subscription($payment);
    $c->user->log('SUB_START', sprintf("Subscription to %s: level %d, expiry set to %s",
        $subscription->portal_id->id, $subscription->new_level, $subscription->new_expire->ymd));

    # Notify the user via email of their new/updated subscription
    $c->model("Mailer")->subscription_confirmation($c, $c->user->email, $c->stash->{lang}, $subscription);

    # Send the user to a confirmation page/receipt
    $c->stash->{template} = 'user/subscribe_finalize.tt';
    $c->stash->{subscription} = $subscription;
    return 1;
}

__PACKAGE__->meta->make_immutable;

