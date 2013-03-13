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
                Util
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

    # This needs to be re-defined in cap.conf or cap_local.conf anyway, so
    # maybe it can be removed from here at some point.
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


=head2 has_role($role)

If a user exists in the current context, calls $c->user->has_role($role)
and returns the value. If no user exists, it returns false. 

=cut
sub has_role {
    my($c, $role) = @_;
    return 0 unless $c->user_exists;
    return $c->user->has_role($role);
}

sub initialize_session {
    my($c) = @_;

    # No need to do anything if the session exists already.
    return 1 if ($c->sessionid);

    $c->session();
    $c->session->{count} = 0;
    $c->log->debug(sprintf("Created new session", $c->sessionid)) if ($c->debug);
    return 1;
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

    $c->session->{count} = 0 unless ($c->session->{count});
    $c->session->{$c->portal->id} = {} unless defined($c->session->{$c->portal->id});

    # Refresh the session data if this is a new session, if the refresh
    # inrerval has been reached, or on request.
    if ($c->session->{count} % $c->config->{session_refresh_interval} == 0 || $force_refresh) {
        $c->log->debug("Doing refresh of session information") if ($c->debug);

        # Find the user's subscribing institution, if any
        $c->session->{$c->portal->id}->{subscribing_institution} = undef;
        my $institution = $c->model('DB::InstitutionIpaddr')->institution_for_ip($c->req->address);

        if ($institution && $institution->is_subscriber($c->portal)) {
            $c->session->{$c->portal->id}->{subscribing_institution} = {id => $institution->id, name => $institution->name };
        }


        if ($c->user_exists) {

            # Update the user information to reflect any background changes
            # (e.g. expired subscriptions) that might have taken place.
            # TODO: this might not be necessary, but it's probably a good
            # sanity check anyway; need to consider further.
            $c->set_authenticated($c->find_user({ id => $c->user->id }));
            $c->persist_user();
        }

    }
}

1;
