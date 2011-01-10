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
                -Debug
                ConfigLoader
                Static::Simple
                StackTrace
                I18N
                Unicode::Encoding

                Authentication
                Authorization::Roles

                Session
                Session::State::Cookie
                Session::Store::DBI
               /;
                #I18N::DBIC
our $VERSION = 0.65; # Minimum config file version required
#                Authorization::ACL
#                Session::Store::FastMmap

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
    
    #'I18N::DBIC' => {
    #    lexicon => 'DB::Lexicon',
    #},
);

__PACKAGE__->config->{'Plugin::Authentication'} = {
    default => {
        class         => 'SimpleDB',
        user_model    => 'DB::User',
        password_type => 'self_check',
    },
};

__PACKAGE__->config->{static} = {
    include_path => [ __PACKAGE__->config->{root} . "/Default/static/" ],
};


# Configure session managemnet
__PACKAGE__->config('Plugin::Session' => {
    expires => 3600,
    dbi_dbh => 'DB',
    dbi_table => 'sessions',
    #cookie_name => 'cap_session', # optional: specify a cookie name
});


# Start the application
__PACKAGE__->setup();


=head1 NAME

CAP - Catalyst based application

=head1 SYNOPSIS

    script/cap_server.pl

=head1 DESCRIPTION

This is the Canadiana Access Portal (working title) an application for
searching digital collections and providing content. It support multiple,
independently configurable portals, each of which can reference a defined
subset of the entire collection, and which can have distinct features and
configurations. Multiple interfaces are supported, including an arbitrary
number of human languages for the standard interface, as well as custom
interfaces for, e.g. XML, Json, and so forth.

=head1 METHODS

These methods override those from the superclass.

=cut

=head2 prepare_path( $c, @path )

    Checks $c->config->{prefix} for a key equal to $c->request->{base}. If
    one is found, the corresponding value is prepended to the request
    path. The value should be either a portal name or a portal/iface
    combination.
=cut
#sub prepare_path
#{
#    my($c, @path) = @_;
#    $c->SUPER::prepare_path(@path);
#    if ($c->config->{prefix}->{$c->request->{base}}) {
#        $c->request->path(join('/', $c->config->{prefix}->{$c->request->{base}} , $c->request->path));
#    }
#    return 1;
#}

=head1 SEE ALSO

L<CAP::Controller::Root>, L<Catalyst>

=head1 AUTHOR

William Wueppelmann E<lt>william.wueppelmann@canadiana.caE<gt>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
