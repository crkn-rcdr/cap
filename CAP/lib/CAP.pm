package CAP;

use strict;
use warnings;

use Catalyst::Runtime '5.70';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory

use parent qw/Catalyst/;
use Catalyst qw/
                ConfigLoader
                Static::Simple
                StackTrace
                I18N
                Unicode::Encoding

                Email

                Authentication
                Authorization::Roles

                Session
                Session::State::Cookie
                Session::Store::DBI

                MessageStack


                Portal
                Institution
               /;

# Configure the application. 
# Note that settings in cap.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
    name => 'CAP',

    'Plugin::ConfigLoader' => {
        driver => {
            General => {
                -AutoTrue => 1,  # treat 1/yes/on/true == true; 0/no/off/false == false
                -UTF8 => 1,      # Enable support for UTF8 strings in the config file
            }, 
        },
    },

    'Plugin::Authentication' => {
        default => {
            class         => 'SimpleDB',
            user_model    => 'DB::User',
            password_type => 'self_check',
        },
    },

    #'require_ssl' => {
    #    remain_in_ssl => 0,      # Set to 1 to keep the user in SSL once directed there
    #    no_cache      => 0,      # Would need to be set if running multiple domains w/wildcard cert.
    #    detach_on_redirect => 1, # Detach immediately if we redirect
    #},

    'Plugin::Session' => {
        cookie_expires => 0, # session cookie
        expires => 7200,     # 2 hours
        dbi_dbh => 'DB',
        dbi_table => 'sessions',
        cookie_name => 'cap_session'
    },

    'Plugin::Static::Simple' => {
        include_path => [ __PACKAGE__->config->{root} . "/Default/static/" ],
    },
);

# Start the application
__PACKAGE__->setup();


# Return true if an authenticated user exists and has at least one of the
# named roles
sub has_role {
    my($c, @roles) = @_;
    return 0 unless $c->user_exists;
    foreach my $role (@roles) {
        return 1 if $c->model('DB::UserRole')->user_has_role($c->user->id, $role);
    }
    return 0;
}

# Retrieve the Solr search subset
# TODO: replace this with a $c->portal->search_subset call + update refs
# in the controllers.
sub search_subset {
    my($c) = @_;
    my $subset = $c->model('DB::PortalCollection')->search_subset($c->portal->id);
    return $subset;
}

# TODO: some of this can be moved into the model.
# This function creates and/or updates the user's session info.
sub update_session {
    my($c, $force_refresh) = @_;
    $c->log->debug("Running update_session") if ($c->debug);

    # Expire the current session, if requested.
    if ($c->req->params->{expiresession}) {
        $c->log->debug(sprintf("Invalidating existing session %s", $c->sessionid)) if ($c->debug);
        $c->delete_session("expiresession parameter used");
    }

    # If there is no session, create one.
    if (! $c->sessionid) {
        $c->session();
        $c->session->{count} = 0;
        $c->log->debug(sprintf("Created new session", $c->sessionid)) if ($c->debug);
    }

    # Initialize the session counter, if it is not already.
    if (! $c->session->{count}) {
        $c->session->{count} = 0;
    }

    # Refresh the session data if this is a new session, if the refresh
    # inrerval has been reached, or on request.
    if ($c->session->{count} % $c->config->{session_refresh_interval} == 0 || $force_refresh) {
        $c->log->debug("Doing refresh of session information") if ($c->debug);

        # Initialize authorization structure
        $c->session->{auth} = {
            'user_class'               => 'none',
            'user_expiry_epoch'        => 0,
            'institutional_sub'        => 0    
        };    

        # Find the user's subscribing institution, if any
        $c->session->{subscribing_institution} = 0;
        my $institution = $c->model('DB::InstitutionIpaddr')->institution_for_ip($c->req->address);

        if ($institution && $institution->is_subscriber($c->portal)) {
                $c->session->{subscribing_institution} = $institution->name;
                $c->session->{subscribing_institution_id} = $institution->id;
                $c->session->{auth}->{institution_sub} = 1;
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

        }

    }
}

1;
