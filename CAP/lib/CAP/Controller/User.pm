package CAP::Controller::User;
use Moose;
use namespace::autoclean;
use Captcha::reCAPTCHA;
use Date::Manip::Date;
use Date::Manip::Delta;
use Text::Trim qw/trim/;
use parent qw/Catalyst::Controller::ActionRole/;

use constant ANONYMOUS_ACTIONS => qw{ user/create user/confirm user/login user/reconfirm user/reset };

BEGIN {extends 'Catalyst::Controller'; }

sub auto :Private Local Does('RequireSSL') {
    my($self, $c) = @_;

    # Require that this portal has user accounts enabled
    if (! $c->stash->{user_accounts}) {
        $c->response->redirect($c->uri_for_action('/index'));
        return 0;
    }

    # Require SSL for all operations
    # $c->require_ssl;

    # Actions relating to creating a new account, logging in, or
    # recovering a lost password are only available to anonymous users.
    my $action = $c->action;
    if (grep(/$action/, ANONYMOUS_ACTIONS)) {
        if ($c->user_exists) {
            $c->response->redirect($c->uri_for_action('/index'));
            return 0;
        }
    } else {
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
    # forward to the main index page, with a message explaining what happened.
    my $id = $c->model('DB::User')->confirm_new_user($auth);
    if ($id) {
        $c->set_authenticated($c->find_user({id => $id}));
        $c->persist_user();
        $c->message({ type => "success", message => "user_confirm_success" });
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
        } else {
            $c->message({ type => "error", message => "username_not_found" });
        }
    }

    return 1;
}

sub profile :Path('profile') :Args(0) {
    my($self, $c) = @_;
    $c->stash(
        payment_history => $c->model('DB::Subscription')->payment_history($c->user->id),
    );
    return 1;
}


sub edit :Path('edit') :Args(0) {
    my($self, $c) = @_;
    my $data = $c->request->body_parameters;
    trim($data->{username});
    trim($data->{password});
    trim($data->{password_check});

    #  Just show the form if this request isn't a form submission.
    if (! $data->{submitted}) {
        $c->stash->{userinfo} = $c->user;
        return 1;
    }
    else {
        $c->stash->{userinfo} = {
            username => $data->{username},
            name     => $data->{name},
        };
    }

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

    # Don't update anything if there were any errors.
    return 1 if @errors;

    # Update the user's profile.
    eval {
        $c->user->update({
            'username' => $data->{username},
            'name'     => $data->{name},
        });
    };
    $c->detach('/error', [500]) if ($@);

    # Change the password, if requested.
    if ($data->{password}) {
        eval { $c->user->update({ 'password' => $data->{password} }); };
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

    my $amount = $c->stash->{subscription_price}; # getting this from the portal config
    my $wants_tax_receipt = $c->request->params->{wants_tax_receipt} || '';
    my $tax_receipt = ($amount * $c->stash->{tax_rcpt_pct}) / 100;
    my $donor_name = $c->request->params->{donor_name} || $c->user->name;
    my $address = $c->request->params->{address} || '';
    my $address2 = $c->request->params->{address2} || '';
    my $city = $c->request->params->{city} || '';
    my $province = $c->request->params->{province} || '';
    my $pc1 = $c->request->params->{pc1} || '';
    my $pc2 = $c->request->params->{pc2} || '';
    my $promocode = $c->request->params->{promocode} || '';
    my $promo_value = 0;
    my $promo_message = '';

    if ($promocode) {
        my $promo_row = $c->model('DB::Promocode')->find($promocode);
        if ($promo_row) {
            if ($promo_row->expired) {
                $promo_message = 'expired';
            } else {
                $promo_value = int($promo_row->amount);
                # $c->stash->{subscription_price} = $amount - $promo_value;
                $tax_receipt = (($amount - $promo_value) *  $c->stash->{tax_rcpt_pct}) / 100;
                $promo_message = 'OK';
            }
        } else {
            $promo_message = 'invalid';
        }
    }

    $c->stash({
        wants_tax_receipt => $wants_tax_receipt,
        donor_name => $donor_name,
        address => $address,
        address2 => $address2,
        city => $city,
        province => $province,
        pc1 => $pc1,
        pc2 => $pc2,
        promocode => $promocode,
        promo_value => $promo_value,
        promo_message => $promo_message,
        tax_receipt => $tax_receipt
    });

    return 1;
}

# for subscribe POSTs.
sub subscribe_process :Path('subscribe_process') :Args(0) {
    my ($self, $c) = @_;
    my $mode = $c->req->params->{submit} || "";
    my $promocode = $c->req->params->{promocode};
    my $tax_receipt = $c->req->params->{wants_tax_receipt};
    my $donor_name = $c->req->params->{donor_name};
    my $address = $c->req->params->{address};
    my $address2 = $c->req->params->{address2};
    my $city = $c->req->params->{city};
    my $province = $c->req->params->{province};
    my $pc1 = $c->req->params->{pc1};
    my $pc2 = $c->req->params->{pc2};
    my $terms = $c->req->params->{terms};
    my $promo_value = 0;
    my $amount = $c->stash->{subscription_price}; # getting this from the portal config
    # my $tax_receipt_amount = $c->stash->{tax_receipt};

    my $get_vars = {
        promocode => $promocode,
        wants_tax_receipt => $tax_receipt,
        donor_name => $donor_name,
        address => $address,
        address2 => $address2,
        city => $city,
        province => $province,
        pc1 => $pc1,
        pc2 => $pc2,
    };

    if ($mode eq "verify_code") {
        $c->response->redirect($c->uri_for_action("/user/subscribe", $get_vars), 303);
        return 0;
    } elsif ($mode eq "subscribe") {
        my $error = 0;

        # Validate promocode
        if ($promocode) {
            my $promo_row = $c->model('DB::Promocode')->find($promocode);
            if ($promo_row) {
                if ($promo_row->expired) {
                    $c->message({ type => "error", message => "promocode_expired" });
                    $error = 1;
                } else {
                    $promo_value = $promo_row->amount;
                }
            } else {
                $c->message({ type => "error", message => "promocode_invalid" });
                $error = 1;
            }
        }

        # Validate tax receipt
        if (defined($tax_receipt)) {
            my $tx_error = 0;
            unless ($donor_name) {
                $c->message({ type => "error", message => "donor_name_required" });
                $error = 1;
            }
            unless ($address) {
                $c->message({ type => "error", message => "address_required" });
                $error = 1;
            }
            unless ($city) {
                $c->message({ type => "error", message => "city_required" });
                $error = 1;
            }
            unless ($province) {
                $c->message({ type => "error", message => "province_required" });
                $error = 1;
            }
            unless ($pc1 =~ /^[A-Za-z]\d[A-Za-z]$/ && $pc2 =~ /^\d[A-Za-z]\d$/) {
                $c->message({ type => "error", message => "verify_postal_code" });
                $error = 1;
            }
        }

        # Ensure terms checkbox is checked
        unless (defined($terms)) {
            $c->message({ type => "error", message => "terms_required" });
            $error = 1;
        }
        
        if ($error) {
            $c->response->redirect($c->uri_for_action("/user/subscribe", $get_vars), 303);
            return 1;
        };

        my $payment = $amount - $promo_value;
        my $tax_receipt_amount = ($payment *  $c->stash->{tax_rcpt_pct}) / 100;

        # Concatenate address blob
        if ($address2) { $address = join("\n", $address, $address2); }
        my $blob = join("\n", $address, join(" ", $city, $province, "", $pc1, $pc2));

        # Create the subscription row. Delete any current pending
        # subscription transactions for this user first so that we never
        # have more than one active pending subscription per user.
        my $incomplete_transactions = $c->model('DB::Subscription')->search({ user_id => $c->user->id, completed => undef});
        $incomplete_transactions->delete if ($incomplete_transactions);
        my $subscriptionrow = $c->user->add_to_subscriptions(
            {
                completed    => undef,
                promo        => $promocode,
                rcpt_name    => $donor_name,
                rcpt_amt     => $tax_receipt_amount,
                rcpt_address => $blob,
            }
        );
        # TODO Refactor the format_money macro within templates to work here too, or some other solution
        $c->detach('/payment/paypal/pay', [$payment, $c->loc("ECO subscription for \$[_1]", $payment), '/user/subscribe_finalize', $subscriptionrow->id]);
    } else {
        $c->detach("/error", [404, "This is not the page you're looking for."]);
    }

    return 1;
}

sub subscribe_finalize : Private
{
    my($self, $c, $success, $paymentid, $foreignid) = @_;

    my $period = $c->config->{subscription_period}; # replace with expiry dates
    $period = 365 unless ($period);

    $c->log->debug("User/subscribe_finalize: Success:$success , PaymentID: $paymentid ForeignID:$foreignid ") if ($c->debug);

    # Get the matching subscription row
    my $subscriberow = $c->user->subscriptions->find($foreignid);
    my $paymentrow = $c->user->payments->find($paymentid);
    if (!$subscriberow || !$paymentrow) {
	# No matching subscription and unable to create new row?
	$c->detach('/error', [500, "Error finalizing subscription"]);
	return 0;
    }
    my $message = $paymentrow->message;
    my $amount  = $paymentrow->amount;
    my $userid =  $c->user->id;

    ## Date manipulation to set the old and new expiry dates

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
	    subexpires   => $newexpires,
	    class        => 'paid',
        remindersent => 0
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

    # Whether successful or not, record completion and the messages
    # from PayPal
    eval { $subscriberow->update({
	   completed => \'now()', #' Makes Emacs Happy
	   success => $success,
	   payment_id => $paymentid,
	   oldexpire =>   $subexpires,
	   newexpire =>   $newexpires,
           payment_id =>   $paymentid
      				     }) };  


    # Send an email notification to administrators
    if (exists($c->config->{subscription_admins})) {
        $c->forward("/mail/subscription_notice", [$c->config->{subscription_admins}, $success, $subexpires, $newexpires, $message]);
    }


    if ($@) {
	$c->log->debug("User/subscribe_finalize subscriber update:  " .$@) if ($c->debug);
	$c->detach('/error', [500,"subscriber update"]);
    }

    if ($success) {
        $c->message(Message::Stack::Message->new(
                level => "success",
                msgid => "payment_complete",
                params => [$amount]));
        $c->response->redirect("/user/subscribe_confirmed");
    } else {
        $c->message({ type => "error", message => "payment_failed" });
        $c->response->redirect('/user/profile');
    }
    return 0;
}

sub subscribe_confirmed :Path('subscribe_confirmed') :Args(0) {
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

    # Build and populate the $session->{auth} object
    $c->session->{auth} = {
        'user_class'               => 'none',
        'user_expiry_epoch'        => 0,
        'institutional_sub'        => 0    
    };    
   

    # Store the user's IP address.
    $c->session->{address} = $c->request->address;

    # Find the user's subscribing institution, if any
    $c->session->{subscribing_institution} = "";
    my $institution = $c->model('DB::InstitutionIpaddr')->institution_for_ip($c->session->{address});
    if ($institution && $institution->subscriber) {
        $c->session->{subscribing_institution} = $institution->name;
        $c->session->{subscribing_institution_id} = $institution->id;
        $c->session->{auth}->{institution_sub} = 1;
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

        $c->session->{auth}->{user_class} = $c->user->class;
        $c->session->{auth}->{user_expiry_epoch} = $c->user->subexpires->epoch() if $c->user->subexpires;

        # Check the user's subscription status
        $c->session->{is_subscriber} = $c->model('DB::User')->has_active_subscription($c->user->id);



        # The following may be deprecated (or not, but they aren't currently in use)
        #
        # Get a list of individual collection subscriptions
        $c->session->{subscribed_collections} = $c->model('DB::UserCollection')->subscribed_collections($c->user->id);

        # Get a list of purchased documents
        $c->session->{purchased_documents} = $c->model('DB::UserDocument')->purchased_documents($c->user->id);
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

