package CAP::Model::Configurator;

=head1 Synopsis

An object for setting per-request configurations based on the portal and the request context. Although methods can be called individually, the standard use case for CAP is to call configAll() near the beginning of a request and stash the result:

$c->stash($c->model('Configurator')->configAll($c->request, $c->config);

=cut

use strict;
use warnings;
use Moose;
use MooseX::Method::Signatures;
use namespace::autoclean;
extends 'Catalyst::Model';


=head1 Methods

=head2 setLang

$lang = setLang($portal, $request)

=over 4

Set the user interface language based on (in order of preference) the
usrlang request parameter, the usrlang cookie, the browser default, the
portal default and, finally, a hardcoded default of 'en'. Return the
selected language.

=back
=cut
method setLang ($request, $config) {
    my $lang;
    my @supported_langs = keys %{ $config->{languages} };
    if ($request->params->{usrlang} && grep($request->params->{usrlang}, @supported_langs)) {
        $lang = $request->params->{usrlang};
    }
    elsif ($request->cookie($config->{cookies}->{lang}) && grep($request->cookie($config->{cookies}->{lang})->value, @supported_langs)) {
        $lang = $request->cookie($config->{cookies}->{lang})->value;
    }
    elsif ($request->header('Accept-Language')) {
        foreach my $accept_lang (split(/\s*,\s*/, $request->header('Accept-Language'))) {
            my ($value) = split(';q=', $accept_lang);
            if ($value) {
                $value = lc(substr($value, 0, 2));
                if (grep $value, @supported_langs) {
                    $lang = $value;
                    last;
                }
            }
        }
    }

    # Return the user interface language. If none is set, use the portal
    # default. Failing that, fall back to English.
    return $lang || 'en';
}


=head2 setView

$current_view = setView($request);

=over 4

Set the current view according the request parameters.

=back

=cut
method setView($request, $config) {
    #warn $request->action;
    my $fmt = $request->params->{fmt};

    # If a format is defined...
    if ($fmt) {
        my $view = $config->{fmt}->{$fmt};
        
        # And exists in the config...
        if ($view) {

            # Grab the list of actions that can use this view. Default is
            # * (all actions). If an action matches, use the view
            foreach my $action (split(/\s+/, $view->{actions} || '*')) {
                if ($action eq '*' || $action eq $request->action) {
                    return $config->{fmt}->{$fmt}->{view};
                }
            }
        }

        # If the action doesn't match, undefine the format.
        delete($request->params->{fmt});
    }
    
    # In all other cases, use the default view.
    return $config->{fmt}->{default}->{view};
}


=head2 setView

$current_view = setView($request);

=over 4

Set the content-type parameter according to the view type for the request.

=back

=cut
method setContentType($request, $config) {
    if ($request->params->{fmt}) {
        my $fmt = $request->params->{fmt};
        if ($config->{fmt}->{$fmt}) {
            return $config->{fmt}->{$fmt}->{content_type};
        }
    }

    return 'text/html';
}

=head2 setCookieDomain

$cookie_domain = setCookieDomain($request, $config);

=over 4

Sets the domain for cookies to the same one used by the session.

=back

=cut
method setCookieDomain($request, $config) {
    my $domain;
    if ($config->{'Plugin::Session'} && $config->{'Plugin::Session'}->{cookie_domain}) {
        $domain = $config->{'Plugin::Session'}->{cookie_domain};
    }
    else {
        $domain = $request->uri->host;
    }
    return $domain;
}


=head2 configAll

%config = configAll($portal, $request)

=over 4

Runs all of the above configurations and returns a hash which can be
passed as an argument to $c->stash() to set all values at once. This is
the standard way to configure CAP for a request.

=back
=cut
method configAll ($request, $config) {
    my %config = ();

    $config{lang} = $self->setLang($request, $config);
    $config{current_view} = $self->setView($request, $config);
    $config{content_type} = $self->setContentType($request, $config);
    $config{cookie_domain} = $self->setCookieDomain($request, $config);

    return %config;
}

1;
