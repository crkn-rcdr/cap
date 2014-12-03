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

                Email

                Authentication
                Authorization::Roles

                Session
                Session::State::Cookie
                Session::Store::DBI

                MessageStack


                Auth
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

);

# Start the application
__PACKAGE__->setup();


=head2 has_role($role)

If a user exists in the current context, calls $c->user->has_role() for
each role in @roles. Returns true if the user has at least one of the
listed roles, or if the user is an administrator. In all other cases,
returns false.

=cut
sub has_role {
    my($c, @roles) = @_;
    return 0 unless $c->user_exists;
    foreach my $role (@roles) {
        return 1 if $c->user->has_role($role);
    }
    return 0;
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

        if ($institution && $institution->subscriber($c->portal)) {
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

=head2 uri_for_portal_action($portal, @uri_args)

Works just like uri_for_action but takes one additional argument
specifying the name of the portal. Will also automatically set the
protocol to http or https, depending on whether or not $portal is the
secure portal name and whether or not the use of https for the secure
portal is configured in cap.conf.

=cut
sub uri_for_portal_action {
    my($c, $portal, @args) = @_;
    my $uri = $c->uri_for_action(@args);
    my $host = $portal . substr($uri->host, index($uri->host, '.'));
    $uri->host($host);

    my $secure_protocol = $c->config->{secure}->{protocol} || die("In cap.conf: missing protocol directive in <secure>");
    my $secure_host     = $c->config->{secure}->{host} || die("In cap.conf: missing host directive in <secure>");
    if ($uri->host eq $secure_host && ! $c->req->secure) { $uri->scheme($secure_protocol) }
    else { $uri->scheme('http') }

    return $uri;
}

1;
