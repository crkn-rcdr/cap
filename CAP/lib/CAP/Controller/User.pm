package CAP::Controller::User;
use Moose;
use namespace::autoclean;
use Captcha::reCAPTCHA;

BEGIN {extends 'Catalyst::Controller'; }

sub auto :Private {
    my($self, $c) = @_;

    # Require that this portal has user accounts enabled
    if (! $c->stash->{user_accounts}) {
        $c->response->redirect('/index');
        return 0;
    }

    # Require SSL for all operations
    $c->require_ssl;

    # Actions relating to creating a new account, logging in, or
    # recovering a lost password are only available to anonymous users.
    if (
        $c->action eq 'user/create'    ||
        $c->action eq 'user/confirm'   ||
        $c->action eq 'user/login'     ||
        $c->action eq 'user/reconfirm' ||
        $c->action eq 'user/reset'
    ) {
        if ($c->user_exists()) {
            $c->response->redirect($c->uri_for('/index'));
            return 0;
        }
    }

    # All other requests are limited to logged in users; redirect
    # anonymous requests to the login page.
    elsif (! $c->user_exists()) {
        # Record the current URI in the session so we can redirect thate
        # after login.
        $c->session->{login_redirect} = $c->req->uri;
        $c->response->redirect($c->uri_for('/user', 'login'));
        return 0;
    }

    return 1;
}


# Create a new account
sub create :Path('create') :Args(0) {
    my($self, $c) = @_;
    my $submitted = $c->request->params->{submitted} || 0;
    my $username  = $c->request->params->{username}  || ""; # Username = email address
    my $name      = $c->request->params->{name}      || ""; # Real/display name
    my $password  = $c->request->params->{password}  || ""; # Password
    my $password2 = $c->request->params->{password2} || ""; # Password, re-entered

    # Get keys from config
    # Generated at https://www.google.com/recaptcha/admin/create
    my $capenabled = $c->config->{captcha}->{enabled};
    my $cappub = $c->config->{captcha}->{publickey};
    my $cappriv = $c->config->{captcha}->{privatekey};

    # If the keys are configured, then check -- otherwise no
    my $capsuccess = 0;

    if ($capenabled && $cappub && $cappriv) {
        my $captcha = Captcha::reCAPTCHA->new;
        my $caperror = undef;

        my $rcf = $c->request->params->{recaptcha_challenge_field};
        my $rrf = $c->request->params->{recaptcha_response_field};

        if ($rrf)  {
            my $result = $captcha->check_answer(
                $cappriv, $ENV{'REMOTE_ADDR'},
                $rcf, $rrf);
            if ( $result->{is_valid} ) {
                $capsuccess = 1;
            } else {
                $caperror = $result->{error};
            }
        }
        $c->stash->{captcha} = $captcha->get_html($cappub, $caperror, 1, { theme => 'white' });
    } else {
        # If we aren't checking captcha, give blank html and set success.
        $c->stash->{captcha}="";
        $capsuccess = 1;
    }

    my $error = 0;
    $c->stash->{userinfo}   = {};
    $c->stash->{completed}  = 0;



    # If this is not a form submission, just show the empty form.
    return 1 unless ($submitted);

    $c->stash->{formdata} = {
        username => $username,
        name     => $name,
    };

    # Validate the submitted form data

    if (!$capsuccess) {
        $c->message({ type => "error", message => "captcha" });
        $error = 1;
    }

    # The username must be a valid email address and not be in use.
    my $user_for_username = $c->find_user({ username => $username });
    my $re_username = $c->config->{user}->{fields}->{username};
    if ($user_for_username) {
        $c->message({ type => "error", message => "account_exists" });
        $error = 1;
    }
    elsif ($username !~ /$re_username/) {
        $c->message({ type => "error", message => "email_invalid" });
        $error = 1;
    }

    # Check for minimum name requirements
    my $re_name     = $c->config->{user}->{fields}->{name};
    if ($name !~ /$re_name/) {
        $c->message({ type => "error", message => "name_invalid" });
        $error = 1;
    }

    # Both passwords must match and meet minimum criteria.
    my $re_password = $c->config->{user}->{fields}->{password};
    if ($password ne $password2) {
        $c->message({ type => "error", message => "password_match_failed" });
        $error = 1;
    }
    elsif ($password !~ /$re_password/) {
        $c->message({ type => "error", message => "password_invalid" });
        $error = 1;
    }

    # Don't update anything if there were any errors.
    return 1 if ($error);

    # Create the user
    eval {
        $c->model('DB::User')->create({
            'username'  => $username,
            'name'      => $name,
            'password'  => $password,
            'confirmed' => 0,
            'active'    => 1,
            'lastseen'  => time(),
        });
    };
    $c->detach('/error', [500]) if ($@);

    # If trial subscriptions are turned on, set the user's initial
    # subscription data
    # TODO

    # Retrieve the record for the newly-created user.
    my $new_user = $c->find_user({ username => $username });

    # Send an activation email
    my $confirm_link = $c->uri_for_action('user/confirm', $new_user->confirmation_token);
    $c->forward("/mail/user_activate", [$username, $name, $confirm_link]);

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
    my $username    = $c->request->params->{username}   || "";
    my $password    = $c->request->params->{password}   || "";
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
            if ($persistent) {
                # Set the session to be persistent or a session cookie.
                my $token = $c->model('DB::User')->set_token($c->user->id);
                $c->response->cookies->{persistent} = {
                    value => $token,
                    expires => time() + 7776000 # 90 days TODO: this should be configurable in $portal.conf or cap.conf
                };
            }
            else {
                # Clear any pre-existing persistence cookies and tokens
                $c->model('DB::User')->clear_token($c->user->id);
                $c->response->cookies->{persistent} = { value => '', expires => 0 }
            }

            my $redirect = $c->session->{login_redirect} || $c->uri_for_action('index');
            delete($c->session->{login_redirect});
            $c->message({ type => "success", message => "login_success" });
            $c->response->redirect($redirect);
        }
        else {
            $c->message({ type => "error", message => "auth_failed" });
        }
    }

    # Initialize some session variables
    $c->forward('init');

    # Display the login page
    return 1;
}


sub logout :Path('logout') :Args(0) {
    my($self, $c) = @_;

    # Log out and clear any persistent token and cookie.
    $c->model('DB::User')->clear_token($c->user->id);
    $c->response->cookies->{persistent} = { value => '', expires => 0 };
    $c->logout();
    $c->forward('init'); # Reinitialize after logout to clear current subscription, etc. info

    $c->message({ type => "success", message => "logout_success" });
    return $c->response->redirect($c->uri_for_action('index'));
}


sub confirm :Path('confirm') :Args(1) {
    my($self, $c, $auth) = @_;

    # Either confirm and log in the new user or silently fail. Either way,
    # forward to the main index page.
    my $id = $c->model('DB::User')->confirm_new_user($auth);
    if ($id) {
        $c->set_authenticated($c->find_user({id => $id}));
        $c->persist_user();
    }
    $c->response->redirect('/index');
    return 0;
}

sub reset :Path('reset') :Args() {
    my($self, $c, $key) = @_;
    my $username = $c->request->params->{username}   || ""; # Username/email address
    my $password  = $c->request->params->{password}  || ""; # Password
    my $password2 = $c->request->params->{password2} || ""; # Password, re-entered

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
            if ($password ne $password2) {
                $c->message({ type => "error", message => "password_match_failed" });
            }
            elsif ($password !~ /$re_password/) {
                $c->message({ type => "error", message => "password_invalid" });
            }
            else {
                # Reset the user's password and log them in.
                my $user_account = $c->find_user({ id => $id });
                eval { $user_account->update({ password => $password }) };
                $c->detach('/error', [500]) if ($@);
                $c->set_authenticated($user_account);
                $c->persist_user();
                $c->stash->{password_reset} = 1;
            }
        }
    }
    elsif ($username) {
        # TODO: make sure email is valid
        my $user_for_username = $c->find_user({ username => $username });
        die unless ($user_for_username);

        my $confirm_link = $c->uri_for_action('user/reset', $user_for_username->confirmation_token);
        $c->forward('/mail/user_reset', [$username, $confirm_link]);

        $c->stash->{mail_sent} = $username;
    }

    return 1;
}

sub profile :Path('profile') :Args(0) {
    my($self, $c) = @_;
}


sub edit :Path('edit') :Args(0) {
    my($self, $c) = @_;
    my $submitted = $c->request->params->{submitted} || 0;
    my $username  = $c->request->params->{username}  || ""; # Username = email address
    my $name      = $c->request->params->{name}      || ""; # Real/display name
    my $password  = $c->request->params->{password}  || ""; # Current password
    my $password1 = $c->request->params->{password1} || ""; # New password
    my $password2 = $c->request->params->{password2} || ""; # New password, re-entered

    # Load the patterns that we will use to validate each field
    my $re_username = $c->config->{user}->{fields}->{username};
    my $re_name     = $c->config->{user}->{fields}->{name};
    my $re_password = $c->config->{user}->{fields}->{password};

    my $error = 0;

    #  Just show the form if this request isn't a form submission.
    if (! $submitted) {
        $c->stash->{userinfo} = $c->user;
        return 1;
    }
    else {
        $c->stash->{userinfo} = {
            username => $username,
            name     => $name,
        };
    }

    # Verify the user's original password.
    if (! $c->authenticate({ username => $c->user->username, password => $password })) {
        $c->message({ type => "error", message => "password_check_failed" });
        $error = 1;
    }

    # Verify that the new passwords match and are acceptable
    if ($password1 ne $password2) {
        $c->message({ type => "error", message => "password_match_failed" });
        $error = 1;
    }
    elsif ($password1 && $password1 !~ /$re_password/) {
        $c->message({ type => "error", message => "password_invalid" });
        $error = 1;
    }

    # Username must meet minimum requirements and must not be in use by
    # another account
    my $user_for_username = $c->find_user({ username => $username });
    if ($user_for_username && $user_for_username->id != $c->user->id) {
        $c->message({ type => "error", message => "account_exists" });
        $error = 1;
    }
    elsif ($username !~ /$re_username/) {
        $c->message({ type => "error", message => "email_invalid" });
        $error = 1;
    }

    # Check for minimum name requirements
    if ($name !~ /$re_name/) {
        $c->message({ type => "error", message => "name_invalid" });
        $error = 1;
    }

    # Don't update anything if there were any errors.
    if ($error) {
        return 1;
    }

    # Update the user's profile.
    eval {
        $c->user->update({
            'username' => $username,
            'name'     => $name,
        });
    };
    $c->detach('/error', [500]) if ($@);

    # Change the password, if requested.
    if ($password1) {
        eval { $c->user->update({ 'password' => $password1 }); };
        $c->detach('/error', [500]) if ($@);
    }

    $c->message({ type => "success", message => "profile_updated" });
    $c->persist_user();
    $c->response->redirect($c->uri_for_action("user/profile"));

    return 1;
}

# for subscribe GETs.
sub subscribe :Path('subscribe') :Args(0) {
    my($self, $c) = @_;

    # Get the latest incomplete row
    my $incomplete_row = $c->user->subscriptions->search(
        { completed => undef },
        { order_by => { -desc => 'id' } }
    )->first();
    my ($row_name, $row_code) = ('', '');
    if ($incomplete_row) {
        $row_name = $incomplete_row->rcpt_name;
        $row_code = $incomplete_row->promo;
    }

    # Good. Now delete all incomplete rows. Note: delete_all is "safer" than delete, but might not be necessary.
    $c->user->subscriptions->search({ completed => undef })->delete_all();

    my $amount = $c->stash->{subscription_price}; # getting this from the portal config
    my $tax_receipt = $c->stash->{tax_receipt};
    my $donor_name = $c->request->params->{donor_name} || ($row_name || $c->user->name);
    my $promocode = $c->request->params->{promocode} || ($row_code || '');
    my $promo_value = 0;
    my $promo_message = '';

    if ($promocode) {
        my $promo_row = $c->model('DB::Promocode')->find($promocode);
        if ($promo_row) {
            if ($promo_row->expired) {
                $promo_message = 'expired';
            } else {
                $promo_value = int($promo_row->amount);
                $promo_message = 'OK';
            }
        } else {
            $promo_message = 'invalid';
        }
    }

    $c->stash({
        donor_name => $donor_name,
        promocode => $promocode,
        promo_value => $promo_value,
        promo_message => $promo_message,
    });

    return 1;
}

# for subscribe POSTs.
sub subscribe_process :Path('subscribe_process') :Args(0) {
    my ($self, $c) = @_;
    my $mode = $c->req->params->{submit};
    my $promocode = $c->req->params->{promocode};
    my $donor_name = $c->req->params->{donor_name};
    my $terms = $c->req->params->{terms};
    my $promo_value = 0;
    my $amount = $c->stash->{subscription_price}; # getting this from the portal config
    my $tax_receipt = $c->stash->{tax_receipt};

    if ($mode eq "verify_code") {
        $c->response->redirect($c->uri_for_action("/user/subscribe", { promocode => $promocode, donor_name => $donor_name }), 303);
        return 0;
    } elsif ($mode eq "subscribe") {
        # Validate promocode
        if ($promocode) {
            my $promo_row = $c->model('DB::Promocode')->find($promocode);
            if ($promo_row) {
                if ($promo_row->expired) {
                    $c->message({ type => "error", message => "promocode_expired" });
                    $c->response->redirect($c->uri_for_action("/user/subscribe", { donor_name => $donor_name }), 303);
                    return 1;
                } else {
                    $promo_value = $promo_row->amount;
                }
            } else {
                $c->message({ type => "error", message => "promocode_invalid" });
                $c->response->redirect($c->uri_for_action("/user/subscribe", { donor_name => $donor_name }), 303);
                return 1;
            }
        }

        # Validate name
        unless ($donor_name) {
            $c->message({ type => "error", message => "donor_name_required" });
            $c->response->redirect($c->uri_for_action("/user/subscribe", { promocode => $promocode }), 303);
            return 1;
        }

        # Ensure terms checkbox is checked
        unless (defined($terms)) {
            $c->message({ type => "error", message => "terms_required" });
            $c->response->redirect($c->uri_for_action("/user/subscribe", { promocode => $promocode, donor_name => $donor_name }), 303);
            return 1;
        }

        my $payment = $amount - $promo_value;

        # TODO Ensure this does the right thing
        # Create the subscription row
        $c->user->add_to_subscriptions(
            {
                completed => undef,
                promo     => $promocode,
                amount    => $payment,
                rcpt_name => $donor_name,
                rcpt_amt  => $tax_receipt,
                processor => "paypal",
            }
        );
        # TODO Refactor the format_money macro within templates to work here too, or some other solution
        $c->detach('/payment/paypal/pay', [$payment, $c->loc("ECO subscription for \$[_1]", $payment), '/user/subscribe_finalize']);
    } else {
        $c->detach("/error", [404, "This is not the page you're looking for."]);
    }

    return 1;
}

sub subscribe_finalize : Private
{
    my($self, $c, $success, $message, $amount, $processor) = @_;

    my $period = $c->config->{subscription_period}; # replace with expiry dates
    $period = 365 unless ($period);

    $c->log->debug("User/subscribe_finalize: Success:$success , Message:$message") if ($c->debug);

    # Get the latest incomplete row
    my $subscriberow = $c->user->subscriptions->search(
        { completed => undef },
        { order_by => { -desc => 'id' } }
    )->first();
    if (!$subscriberow) {
        $c->user->add_to_subscriptions(
            {
                amount    => $amount,
            }
        );
	my $subscriberow = $c->user->subscriptions->search(
	    { completed => undef },
	    { order_by => { -desc => 'id' } }
	)->first();
    }
    if (!$subscriberow) {
	# No pending subscription and unable to create new row?
	$c->detach('/error', [500, "Error finalizing subscription"]);
	return 0;
    }

    my $userid =  $c->user->id;
    my $orderTotal = $subscriberow->amount;

    ## Date manipulation to set the old and new expiry dates
    use Date::Manip::Date;
    use Date::Manip::Delta;

    my $subexpires = $c->user->subexpires;

    my $dateexp = new Date::Manip::Date;
    my $err = $dateexp->parse($subexpires);

    my $datetoday = new Date::Manip::Date;
    $datetoday->parse("today");

   # If we couldn't parse expiry date (likely null), or expired in past.
    if ($err || (($dateexp->cmp($datetoday)) <= 0)) {
        # The new expiry date is built from today
	$dateexp=$datetoday;
    }

    # Create a delta based on the period we were passed in.
    my $deltaexpire = new Date::Manip::Delta;
    $err = $deltaexpire->parse($period . " days");

    if ($err) {
	# If I was passed in a bad period, then what?
	## TODO: localize
	$c->detach('/error', [500, "Subscription period invalid"]);
	return 0;
    }
    my $datenew = $dateexp->calc($deltaexpire);
    my $newexpires = $datenew->printf("%Y-%m-%d");
    ## END date manipulation

    if ($success) {
	my $user_account = $c->find_user({ id => $userid });

	eval { $user_account->update({
	    subexpires => $newexpires
				     }) };
	if ($@) {
	    $c->log->debug("User/subscribe_finalize: user account:  " .$@) if ($c->debug);
	    $c->detach('/error', [500,"user account"]);
	}

	# Update current session. User may have become subscriber.
	$c->forward('/user/init');
    } else {
	undef $newexpires;
    }

    # Send an email notification to administrators
    if (exists($c->config->{subscription_admins})) {
        $c->forward("/mail/subscription_notice", [$c->config->{subscription_admins}, $success, $subexpires, $newexpires, $message]);
    }


    # Whether successful or not, record completion and the messages
    # from PayPal
    eval { $subscriberow->update({
	   completed => \'now()', #' Makes Emacs Happy
	   success => $success,
	   message => $message,
	   oldexpire =>   $subexpires,
	   newexpire =>   $newexpires,
           processor =>   $processor
      				     }) };  
    if ($@) {
	$c->log->debug("User/subscribe_finalize subscriber update:  " .$@) if ($c->debug);
	$c->detach('/error', [500,"subscriber update"]);
    }

    if ($success) {
	$c->message(Message::Stack::Message->new(
			level => "success",
			msgid => "payment_complete",
			params => [$orderTotal]));
    } else {
	$c->message({ type => "error", message => "payment_failed" });
    }
    # TODO: $success boolean may suggest different place to redirect.
    $c->response->redirect('/user/profile');
    return 0;
}

# This should be called at login and when a new session is established,
# whether or not the requester is an authenticated user. It also needs to
# be called when a user's subscriptions, group memberships, etc. change.
# TODO: it may be a good idea to call this every X requests to ensure that
# changes are reflected in long-running sessions.
sub init :Private
{
    my($self, $c) = @_;

    # Store the user's IP address.
    $c->session->{address} = $c->request->address;

    # Find the user's subscribing institution, if any
    my $institution = $c->model('DB::InstitutionIpaddr')->institution_for_ip($c->session->{address});
    if ($institution && $institution->subscriber) {
        $c->session->{subscribing_institution} = $institution->name;
        $c->session->{has_institutional_subscription} = 1;
    }
    else {
        $c->session->{subscribing_institution} = "";
        $c->session->{has_institutional_subscription} = 0;
    }

    # Build a table of sponsored collections, mapped to the sponsor name
    $c->session->{sponsored_collections} = {};
    foreach my $collection ($c->model('DB::InstitutionCollection')->all) {
        $c->session->{sponsored_collections}->{$collection->collection_id->id} = $collection->institution_id->name;
    }

    $c->session->{is_subscriber} = 0;
    if ($c->user_exists) {

        # Update the user information to reflect any background changes
        # (e.g. expired subscriptions) that might have taken place.
        # TODO: this might not be necessary, but it's probably a good
        # sanity check anyway; need to consider further.
        $c->set_authenticated($c->find_user({ id => $c->user->id }));
        $c->persist_user();

        # Check the user's subscription status
        $c->session->{is_subscriber} = $c->model('DB::User')->has_active_subscription($c->user->id);

        # Get a list of individual collection subscriptions
        $c->session->{subscribed_collections} = $c->model('DB::UserCollection')->subscribed_collections($c->user->id);

        # Get a list of purchased documents
        $c->session->{purchased_documents} = $c->model('DB::UserDocument')->purchased_documents($c->user->id);
    }

    return 1;
}


# These are wrappers for calling the like-named methods in the appropriate
# Access module.

#sub has_access :Private
#{
#    my($self, $c, $doc, $key, $resource_type, $size) = @_;

    # Forward to the access control logic for the configured access model
#    return $c->forward(join('/', '', 'access', $c->stash->{access_model}, 'has_access'), [$doc, $key, $resource_type, $size]);
#}

#sub access_level :Private
#{
#    my($self, $c, $doc) = @_;

    # Forward to the access control logic for the configured access model
#    return $c->forward(join('/', '', 'access', $c->stash->{access_model}, 'access_level'), [$doc]);
#}

#sub credit_cost :Private
#{
#    my($self, $c, $doc) = @_;

    # Forward to the credit cost control logic for the configured access model
#    return $c->forward(join('/', '', 'access', $c->stash->{access_model}, 'credit_cost'), [$doc]);
#}

__PACKAGE__->meta->make_immutable;

