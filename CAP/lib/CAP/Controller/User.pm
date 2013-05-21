package CAP::Controller::User;
use Moose;
use namespace::autoclean;
use Captcha::reCAPTCHA;
use Date::Manip::Date;
use Date::Manip::Delta;
use Text::Trim qw/trim/;

use constant ANONYMOUS_ACTIONS => qw{ user/create user/confirm user/confirmation_required user/login user/reconfirm user/reset };

__PACKAGE__->config( map => { 'text/html' => [ 'View', 'Default' ] } );

BEGIN { extends 'Catalyst::Controller::REST'; }


sub auto :Private {
    my($self, $c) = @_;

    # Actions relating to creating a new account, logging in, or
    # recovering a lost password are only available to anonymous users.
    my $action = $c->action;
    if (grep(/$action/, ANONYMOUS_ACTIONS)) {
        if ($c->user_exists) {
            $c->response->redirect($c->uri_for_action('/index'));
            return 0;
        }
    }
    else {
        unless ($c->user_exists) {
            # All other requests are limited to logged in users; redirect
            # anonymous requests to the login page.
            # Record the current URI in the session so we can redirect there
            # after login.
            $c->session->{login_redirect} = $c->req->uri;
            $c->response->redirect($c->uri_for_action('/user/login'));
            return 0;
        }
    }

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
    my $data = $c->request->body_parameters;
    foreach my $k (qw/username password password_check/) { trim $data->{$k}; }

    my @errors = ();

    if (!$c->authenticate({ username => $c->user->username, password => $data->{current_password} })) {
        push @errors, 'password_check_failed';
    } else {
        push @errors, $c->model('DB::User')->validate(
            $data, $c->config->{user}->{fields}, validate_password => $data->{password}, current_user => $c->user->username);
    }

    foreach my $error (@errors) {
        $c->message({ type => 'error', message => $error });
    }

    unless (@errors) {
        eval { $c->user->update_account_information($data); };
        $c->detach('/error', [500]) if ($@);    
        $c->message({ type => "success", message => "profile_updated" });
        $c->persist_user();
    }

    $c->response->redirect($c->uri_for_action("/user/profile"));
    $c->detach();

    return 1;
}

sub login :Path('login') :Args(0) {
    my ( $self, $c ) = @_;
    my $username    = trim($c->request->params->{username})   || "";
    my $password    = trim($c->request->params->{password})   || "";
    my $persistent  = $c->request->params->{persistent} || 0;

    my($captcha_success, $captcha_output) = $c->cap->generate_captcha();
    $c->stash->{captcha} = $captcha_output;

    if ($c->find_user({ username => $username, confirmed => 0 })) {
        $c->response->redirect($c->uri_for_action('/user/confirmation_required', [$username]));
        $c->detach();
        return 1;
    }
    elsif ($username) {
        if ($c->authenticate(({ username => $username, password => $password, confirmed => 1, active => 1 }))) {
            $c->user->log('LOGIN', sprintf("from: %s", $c->req->address));
            $c->forward('/user/handle_persistence', [$persistent]);

            my $redirect = $c->session->{login_redirect} || $c->uri_for_action('index');
            delete($c->session->{login_redirect});
            $c->response->redirect($redirect);
        }
        else {
            my $user = $c->find_user({ username =>  $username});
            if ($user) { $user->log_failed_login(); }
            $c->message({ type => "error", message => "auth_failed" });
        }
    }

    # Initialize some session variables
    #$c->forward('init');
    $c->update_session(1);

    # Display the login page
    return 1;
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

# Create a new account
sub create :Path('create') :Args(0) {
    my($self, $c) = @_;
    my $data = $c->request->body_parameters;
    foreach my $k (qw/username password password_check/) { trim $data->{$k}; }

    my($captcha_success, $captcha_output) = $c->cap->generate_captcha();

    # Validate the submitted form data
    my @errors = ();

    if (!$captcha_success) {
        push @errors, 'captcha';
    }

    push @errors, $c->model('DB::User')->validate(
        $data, $c->config->{user}->{fields}, validate_password => 1);

    foreach my $error (@errors) {
        $c->message({ type => 'error', message => $error });
    }

    # Don't update anything if there were any errors.
    if (@errors) {
        $c->stash->{template} = 'user/login.tt';
        $c->detach('/user/login');
        return 1;
    }
 
    # Create the user
    my $new_user;
    eval {
        $new_user = $c->model('DB::User')->create({
            'username'  => $data->{username},
            'name'      => $data->{name},
            'password'  => $data->{password},
            'confirmed' => 0,
            'active'    => 1,
            'lastseen'  => time(),
        });
    };
    $c->detach('/error', [500]) if ($@);    
    $new_user->log("CREATED", sprintf("Userid: %s; username: %s", $new_user->username, $new_user->name));

    # Send an activation email
    my $confirm_link = $c->uri_for_action('user/confirm', $new_user->confirmation_token);
    $c->forward("/mail/user_activate", [$data->{username}, $data->{name}, $confirm_link]);

    $c->response->redirect($c->uri_for_action('/user/confirmation_required', [$data->{username}]));
    $c->detach();
    return 1;
}

sub confirmation_required :Path('confirmation_required') :Args(1) {
    my($self, $c, $username) = @_;
    $c->stash->{username} = $username;
    return 1;
}

sub reconfirm :Path('reconfirm') :Args(1) {
    my($self, $c, $username) = @_;

    # Retrieve the record for the user
    my $new_user = $c->find_user({ username => $username, confirmed => 0 });

    # Make sure the user is valid and not yet confirmed
    if (! $new_user) {
        $c->response->redirect($c->uri_for('/index'));
    }

    $c->stash->{formdata} = {
        username => $username,
        name     => $new_user->name,
    };

    # Resend an activation email
    my $confirm_link = $c->uri_for_action('user/confirm', $new_user->confirmation_token);
    $c->forward("/mail/user_activate", [$username, $new_user->name, $confirm_link]);

    $c->stash->{completed}  = 1;
    $c->stash->{template} = 'user/create.tt';

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
    #$c->forward('init'); # Reinitialize after logout to clear current subscription, etc. info
    $c->update_session(1);

    return $c->response->redirect($c->uri_for_action('index'));
}


sub confirm :Path('confirm') :Args(1) {
    my($self, $c, $auth) = @_;

    # Either confirm and log in the new user or silently fail. Either way,
    # forward to the main index page, with a message explaining what happened.
    my $id = $c->model('DB::User')->confirm_new_user($auth);
    if ($id) {
        $c->set_authenticated($c->find_user({id => $id}));
        $c->persist_user();
        $c->message({ type => "success", message => "user_confirm_success" });
        $c->user->log('CONFIRMED');
        $c->response->redirect($c->uri_for_action("/user/confirmed"));
    } else {
        $c->response->redirect($c->uri_for_action('/index'));
    }
    return 0;
}

sub confirmed :Path('confirmed') :Args(0) {
    my($self, $c) = @_;
    $c->stash->{portals} = [$c->model("DB::Portal")->list];
    return 0;
}

sub reset :Path('reset') :Args() {
    my($self, $c, $key) = @_;
    my $username = trim($c->request->params->{username})             || ""; # Username/email address
    my $password  = trim($c->request->params->{password})            || ""; # Password
    my $password_check = trim($c->request->params->{password_check}) || ""; # Password, re-entered

    if ($c->request->params->{key}) {
        $key = $c->req->params->{key};
    }

    if ($key) {
        # Check whether the key is valid.
        my $id = $c->model('DB::User')->validate_confirmation($key);
        if (! $id) {
            $c->response->redirect('/index');
            return 0;
        }
        $c->stash->{key} = $key;

        # Check for a new password.
        if ($password) {
            my $re_password = $c->config->{user}->{fields}->{password};
            my @errors = $c->model("DB::User")->validate_password($password, $password_check, $re_password);

            foreach my $error (@errors) {
                $c->message({ type => 'error', message => $error });
            }

            unless (@errors) {
                # Reset the user's password and log them in.
                my $user_account = $c->find_user({ id => $id });
                eval { $user_account->update({ password => $password }) };
                $c->detach('/error', [500]) if ($@);
                $c->set_authenticated($user_account);
                $c->persist_user();
                $c->user->log('PASSWORD_CHANGED', "from password reset");
                $c->stash->{password_reset} = 1;
            }
        }
    }
    elsif ($username) {
        my $user_for_username = $c->find_user({ username => $username });

        if ($user_for_username) {
            my $confirm_link = $c->uri_for_action('user/reset', $user_for_username->confirmation_token);
            $c->forward('/mail/user_reset', [$username, $confirm_link]);
            $c->stash->{mail_sent} = $username;
            $user_for_username->log("RESET_REQUEST", sprintf("from %s", $c->req->address));
        } else {
            $c->message({ type => "error", message => "username_not_found" });
        }
    }

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

    # Send an email notification to administrators
    if (exists($c->config->{subscription_admins})) {
        $c->forward("/mail/subscription_notice",
            [$c->config->{subscription_admins}, $success, $subscription->old_expire, $subscription->new_expire, $payment->message]
        );
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
    $c->forward('/mail/subscription_confirmation', [ $subscription ]);

    # Send the user to a confirmation page/receipt
    $c->stash->{template} = 'user/subscribe_finalize.tt';
    return 1;
}

__PACKAGE__->meta->make_immutable;

