package CAP;

use strict;
use warnings;

use Catalyst::Runtime '5.70';
use FindBin;
use Log::Log4perl::Catalyst;

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

                Session
                Session::Store::Redis
                Session::State::Cookie

                MessageStack


                Portal
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
);

if (-e "$FindBin::Bin/../log4perl.conf") {
    __PACKAGE__->log(Log::Log4perl::Catalyst->new("$FindBin::Bin/../log4perl.conf"));
} else {
    __PACKAGE__->log(Log::Log4perl::Catalyst->new());
}

# Start the application
__PACKAGE__->setup();

# see http://www.perlmonks.org/?node_id=915657
# calling this this way because using Moose-esque after declaration doesn't seem to work
__PACKAGE__->components->{'CAP::Model::CMS'}->initialize_after_setup(__PACKAGE__);

sub initialize_session {
    my($c) = @_;

    # No need to do anything if the session exists already.
    return 1 if ($c->sessionid);

    $c->session();
    return 1;
}

sub uri_for_portal_action {
    my($c, $portal, @args) = @_;
    my $uri = $c->uri_for_action(@args);
    my $host = $portal . substr($uri->host, index($uri->host, '.'));
    $uri->host($host);

    # FIXME: do this in conf
    $uri->scheme('http');
    return $uri;
}

=head2 uri_for_portal ($portal_id, $path)

Calls uri_for($path) and then changes the hostname part of the URL
to the canonical hostname for $portal_id. Returns a URI for the current
portal if the requested portal_id cannot be found. Always sets the
protocol to http.

=cut
sub uri_for_portal {
    my ($c, $portal_id, $path) = @_;
    my $uri = $c->uri_for($path);
    my $current_hostname = $uri->host;
    $uri->scheme('http');
    my $portal = $c->model('DB::Portal')->find({id => $portal_id});
    return $uri if (! $portal);
    my $hostname = $portal->canonical_hostname;
    return $uri if (! $hostname);
    $uri->host($hostname . substr($current_hostname, index($current_hostname, '.')));
    return $uri;
}

1;
