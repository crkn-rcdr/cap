package CAP::Controller::User;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

sub auto :Private {
    my($self, $c) = @_;

    # Require that this portal has user accounts enabled
    if (! $c->stash->{user_accounts}) {
        $c->response->redirect('/index');
        return 0;
    }

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

    $c->stash->{errors}     = {};
    $c->stash->{userinfo}   = {};
    $c->stash->{completed}  = 0;

    # If this is not a form submission, just show the empty form.
    return 1 unless ($submitted);

    $c->stash->{formdata} = {
        username => $username,
        name     => $name,
    };

    # Validate the submitted form data

    # The username must be a valid email address and not be in use.
    my $user_for_username = $c->find_user({ username => $username });
    my $re_username = $c->config->{user}->{fields}->{username};
    if ($user_for_username) {
        $c->stash->{errors}->{username} = 2;
    }
    elsif ($username !~ /$re_username/) {
        $c->stash->{errors}->{username} = 1;
    }

    # Check for minimum name requirements
    my $re_name     = $c->config->{user}->{fields}->{name};
    if ($name !~ /$re_name/) {
        $c->stash->{errors}->{name} = 1;
    }

    # Both passwords must match and meet minimum criteria.
    my $re_password = $c->config->{user}->{fields}->{password};
    if ($password ne $password2) {
        $c->stash->{errors}->{password} = 1;
    }
    elsif ($password !~ /$re_password/) {
        $c->stash->{errors}->{password} = 2;
    }

    # Don't update anything if there were any errors.
    return 1 if (int(keys(%{$c->stash->{errors}})) != 0);

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
    $c->detach('/error', 500) if ($@);

    # Retrieve the record for the newly-created user.
    my $new_user = $c->find_user({ username => $username });

    # Send an activation email
    $c->stash->{confirm_link} = $c->uri_for('/user', 'confirm', $c->model('DB::User')->confirmation_token($new_user->id));
    $c->stash->{mail} = {
        to => $username,
        subject => 'ECO Account Activation',
        template => 'activate.tt'
    };
    $c->forward('sendmail');

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
    $c->stash->{confirm_link} = $c->uri_for('/user', 'confirm', $c->model('DB::User')->confirmation_token($new_user->id));
    $c->stash->{mail} = {
        to => $username,
        subject => 'ECO Account Activation',
        template => 'activate.tt'
    };
    $c->forward('sendmail');
    $c->stash->{completed}  = 1;
    $c->stash->{template} = 'user/create.tt';

    return 1;
}


sub login :Path('login') :Args(0) {
    my ( $self, $c ) = @_;
    my $username    = $c->request->params->{username}   || "";
    my $password    = $c->request->params->{password}   || "";
    my $persistent  = $c->request->params->{persistent} || 0;

    $c->stash->{errors} =  {};
    $c->stash->{formdata} = {
        username => $username,
    };

    if ($c->user_exists()) {
        # User is already logged in, so redirect to the main page.
        $c->response->redirect($c->uri_for('index'));
    }
    elsif ($c->find_user({ username => $username, confirmed => 0 })) {
        $c->stash->{errors}->{confirmed} = 1;
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

            my $redirect = $c->session->{login_redirect}   || $c->uri_for('index');
            delete($c->session->{login_redirect});
            $c->response->redirect($redirect);
        }
        else {
            $c->stash->{errors}->{password} = 1;
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

    return $c->response->redirect($c->uri_for('/index'));
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
        $c->stash->{errors} = {};

        # Check for a new password.
        if ($password) {
            my $re_password = $c->config->{user}->{fields}->{password};
            if ($password ne $password2) {
                $c->stash->{errors}->{password} = 1;
            }
            elsif ($password !~ /$re_password/) {
                $c->stash->{errors}->{password} = 2;
            }
            else {
                # Reset the user's password and log them in.
                my $user_account = $c->find_user({ id => $id });
                eval { $user_account->update({ password => $password }) };
                $c->detach('/error', 500) if ($@);
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

        $c->stash->{mail} = {
            to => $username,
            subject => 'Password reset',
            template => 'reset.tt'
        };
        $c->stash->{confirm_link} = $c->uri_for('/user', 'reset', $c->model('DB::User')->confirmation_token($user_for_username->id));
        $c->forward('sendmail');

        $c->stash->{mail_sent} = $username;
    }

    return 1;
}

sub profile :Path('profile') :Args(0) {
    my($self, $c) = @_;
    my $solr = $c->stash->{solr};

    # Fetch labels for all of the user's documents, skipping the lookup if
    # we already know the label.
    foreach my $book (@{$c->session->{user_bookshelf}}) {
        next if ($book->{label});
        my $record = $solr->document($book->{key});
        $book->{label} = $record->{label};
    }

    ### TEST: retrieve annotations
    #$c->stash->{annotations} = [ $c->model('DB::Annotation')->search({
    #    user_id => $c->user->id,
    #})->all ];
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

    $c->stash->{errors} = {};

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
        $c->stash->{errors}->{auth} = 1;
    }

    # Verify that the new passwords match and are acceptable
    if ($password1 ne $password2) {
        $c->stash->{errors}->{password} = 1;
    }
    elsif ($password1 && $password1 !~ /$re_password/) {
        $c->stash->{errors}->{password} = 2;
    }

    # Username must meet minimum requirements and must not be in use by
    # another account
    my $user_for_username = $c->find_user({ username => $username });
    if ($user_for_username && $user_for_username->id != $c->user->id) {
        $c->stash->{errors}->{username} = 2;
    }
    elsif ($username !~ /$re_username/) {
        $c->stash->{errors}->{username} = 1;
    }

    # Check for minimum name requirements
    if ($name !~ /$re_name/) {
        $c->stash->{errors}->{name} = 1;
    }

    # Don't update anything if there were any errors.
    if (int(keys(%{$c->stash->{errors}})) != 0) {
        return 1;
    }

    # Update the user's profile.
    eval {
        $c->user->update({
            'username' => $username,
            'name'     => $name,
        });
    };
    $c->detach('/error', 500) if ($@);

    # Change the password, if requested.
    if ($password1) {
        eval { $c->user->update({ 'password' => $password1 }); };
        $c->detach('/error', 500) if ($@);
    }

    $c->persist_user();

    return 1;
}

sub sendmail :Private
{
    my($self, $c) = @_;
    $c->stash->{additional_template_paths} = [
        join('/', $c->config->{root}, 'templates', 'Mail', $c->stash->{portal}),
        join('/', $c->config->{root}, 'templates', 'Mail', 'Common')
    ];

    # TODO: what are the failure modes for this action?
    $c->email({
        header => [
            From    => 'info@canadiana.ca',
            To      => $c->stash->{mail}->{to},
            Subject => $c->stash->{mail}->{subject}
        ],
        body => $c->view('Mail')->render($c, $c->stash->{mail}->{template})
    });

    return 1;
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

sub access_level :Private
{
    my($self, $c, $doc) = @_;

    # Always grant access if access control is turned off
    return 1 unless $c->stash->{access_model};

    # Forward to the access control logic for the configured access model
    return $c->forward(join('/', '', 'access', $c->stash->{access_model}, 'access_level'), [$doc]);
}

__PACKAGE__->meta->make_immutable;

