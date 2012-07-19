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

                RequireSSL

                Session
                Session::State::Cookie
                Session::Store::DBI

                MessageStack
               /;

# Configure the application. 
#
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

    'require_ssl' => {
        remain_in_ssl => 0,      # Set to 1 to keep the user in SSL once directed there
        no_cache      => 0,      # Would need to be set if running multiple domains w/wildcard cert.
        detach_on_redirect => 1, # Detach immediately if we redirect
    },

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


# Return true if an authenticated user exists and has the named role.
sub has_role {
    my($c, $role) = @_;
    return 0 unless $c->user_exists;
    return $c->model('DB::UserRole')->user_has_role($c->user->id, $role);
}

sub configure_portal {
    my($c) = @_;
    my $host = substr($c->req->uri->host, 0, index($c->req->uri->host, '.'));
    my $portal =  $c->model('DB::PortalHost')->get_portal($host);
    return $portal;
}

1;
