package CAP::Controller::User;
use Moose;
use namespace::autoclean;
use Captcha::reCAPTCHA;
use Date::Manip::Date;
use Date::Manip::Delta;
use Text::Trim qw/trim/;

use constant ANONYMOUS_ACTIONS => qw{ user/create user/confirm user/login user/reconfirm user/reset };

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



# Create a new account
sub create :Path('create') :Args(0) {
    my($self, $c) = @_;
    my $data = $c->request->body_parameters;
    trim($data->{username});
    trim($data->{password});
    trim($data->{password_check});
    my $captcha_info = $c->config->{captcha};

    # If the keys are configured, then check -- otherwise no
    my $captcha_success = 0;

    if ($captcha_info->{enabled} && $captcha_info->{publickey} && $captcha_info->{privatekey}) {
        my $captcha = Captcha::reCAPTCHA->new;
        my $captcha_error = undef;

        my $rcf = $c->request->params->{recaptcha_challenge_field};
        my $rrf = $c->request->params->{recaptcha_response_field};

        if ($data->{recaptcha_response_field})  {
            my $captcha_result = $captcha->check_answer(
                $captcha_info->{privatekey},
                $ENV{'REMOTE_ADDR'},
                $data->{recaptcha_challenge_field},
                $data->{recaptcha_response_field});
            if ( $captcha_result->{is_valid} ) {
                $captcha_success = 1;
            } else {
                $captcha_error = $captcha_result->{error};
            }
        }
        $c->stash->{captcha} = $captcha->get_html($captcha_info->{publickey}, $captcha_error, 1, { theme => 'clean', lang => $c->stash->{lang} });
    } else {
        # If we aren't checking captcha, give blank html and set success.
        $c->stash->{captcha}="";
        $captcha_success = 1;
    }

    $c->stash->{completed} = 0;

    # If this is not a form submission, just show the empty form.
    return 1 unless ($data->{submitted});

    # BEGIN POST

    $c->stash->{formdata} = {
        username => $data->{username},
        name     => $data->{name},
    };

    # Validate the submitted form data
    my @errors = ();

    if (!$captcha_success) {
        push @errors, 'captcha';
    }

    push @errors, $c->model('DB::User')->validate(
        $data, $c->config->{user}->{fields}, validate_password => 1);

    # Ensure terms checkbox is checked
    unless ($data->{terms}) {
        push @errors, 'terms_required';
    }

    foreach my $error (@errors) {
        $c->message({ type => 'error', message => $error });
    }

    # Don't update anything if there were any errors.
    return 1 if @errors;
 
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

    #Create row in subscription table
    my $new_user_subscription;
    my $new_user_id = $c->model('DB::User')->get_user_id($data->{username});
    my $portal_id = defined($c->portal->id) ? $c->portal->id : 'eco';
    my $level = (int($c->config->{subscription_trial}) > 0) ? 1 : 0;
    #eval {
    #   $new_user_subscription = $c->model('DB::UserSubscription')->subscribe($new_user_id, $portal_id, 1, "0000-00-00 00:00:00", 0);
    #};
    $c->detach('/error', [500]) if ($@);
    $new_user->log("CREATED", sprintf("Userid: %s; username: %s", $new_user->username, $new_user->name));

    # If trial subscriptions are turned on, set the user's initial
    # subscription data
    if (int($c->config->{subscription_trial}) > 0) {
        my $datetoday = new Date::Manip::Date;
        $datetoday->parse("today");
        my $deltaexpire = new Date::Manip::Delta;
        my $err = $deltaexpire->parse(sprintf("%d days", $c->config->{subscription_trial}));
        if ($err) {
        # If I was passed in a bad period, then what?
        ## TODO: localize
        $c->detach('/error', [500, "Subscription period invalid"]);
            return 0;
        }
        my $datenew = $datetoday->calc($deltaexpire);
        my $newexpires = $datenew->printf("%Y-%m-%d");

        $new_user->update({
            subexpires => $newexpires,
            class => 'trial',
        });

        #update user_subscription table for trial subscriptions
        $c->model('DB::UserSubscription')->subscribe($new_user_id, $portal_id, 1, $newexpires, 0);

        $new_user->log('TRIAL_START', "expires: $newexpires");

    }


    # Send an activation email
    my $confirm_link = $c->uri_for_action('user/confirm', $new_user->confirmation_token);
    $c->forward("/mail/user_activate", [$data->{username}, $data->{name}, $confirm_link]);

    $c->stash->{completed}  = 1;

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


sub login :Path('login') :Args(0) {
    my ( $self, $c ) = @_;
    my $username    = trim($c->request->params->{username})   || "";
    my $password    = trim($c->request->params->{password})   || "";
    my $persistent  = $c->request->params->{persistent} || 0;

    $c->stash->{formdata} = {
        username => $username,
    };

    if ($c->user_exists()) {
        # User is already logged in, so redirect to the main page.
        $c->response->redirect($c->uri_for('index'));
    }
    elsif ($c->find_user({ username => $username, confirmed => 0 })) {
        $c->stash->{needs_to_confirm} = 1;
    }
    elsif ($username) {
        if ($c->authenticate(({ username => $username, password => $password, confirmed => 1, active => 1 }))) {
            $c->user->log('LOGIN', sprintf("from: %s", $c->req->address));
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

            my $redirect = $c->session->{login_redirect} || $c->uri_for_action('index');
            delete($c->session->{login_redirect});
            $c->message({ type => "success", message => "login_success" });
            $c->response->redirect($redirect);
        }
        else {
            my $user = $c->find_user({ username =>  $username});
            if ($user) {
                my $reason;
                if (! $user->active) { $reason = 'not active'; }
                elsif (! $user->confirmed) { $reason = 'not confirmed'; }
                else { $reason = 'bad password'; }
                $user->log("LOGIN_FAILED", $reason);
            }
            $c->message({ type => "error", message => "auth_failed" });
        }
    }

    # Initialize some session variables
    #$c->forward('init');
    $c->update_session(1);

    # Display the login page
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

    $c->message({ type => "success", message => "logout_success" });
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

