package CAP::Model::Configurator;

=head1 Synopsis

An object for setting per-request configurations based on the portal and the request context. Although methods can be called individually, the standard use case for CAP is to call configAll() near the beginning of a request and stash the result:

$c->stash($c->model('Configurator')->configAll($c->portal, $c->request);

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
method setLang ($portal, $request, $config) {
    my $lang;
    if ($request->params->{usrlang} && $portal->supports_lang($request->params->{usrlang})) {
        $lang = $request->params->{usrlang};
    }
    elsif ($request->cookie('usrlang') && $portal->supports_lang($request->cookie($config->{cookies}->{lang})->value)) {
        $lang = $request->cookie($config->{cookies}->{lang})->value;
    }
    elsif ($request->header('Accept-Language')) {
        foreach my $accept_lang (split(/\s*,\s*/, $request->header('Accept-Language'))) {
            my ($value) = split(';q=', $accept_lang);
            if ($value) {
                $value = lc(substr($value, 0, 2));
                if ($portal->supports_lang($value)) {
                    $lang = $value;
                    last;
                }
            }
        }
    }

    # Return the user interface language. If none is set, use the portal
    # default. Failing that, fall back to English.
    return $lang || $portal->default_lang || 'en';
}


=head2 portalName

$portal_name = portalName($portal, $lang)

=over 4

Get the portal's name for the selected language.

=back
=cut
method portalName($portal, $lang) {
    return $portal->get_string('name', $lang) || '[CAP Portal]';
}


=head2 portalId

$portal_id = $portalId($portal)

=over 4

Return the portal id string.

=back

=cut
method portalId($portal) {
    return $portal->id;
}


=head2 searchPlaceholder

$search_bar_placeholder = searchPlaceholder($portal, $lang)

=over 4

Returns the search field placeholder text to display.

=back
=cut
method searchPlaceholder($portal, $lang) {
    return $portal->get_string('search_bar', $lang) || '[Search]';
}

=head2 supportedLangs

$supported_langs = supportedLangs($portal)

=over 4

Gets a list of the languages supported by the portal. Equivalent to
calling $portal->langs, but included here for convenience.

=back 

=cut
method supportedLangs($portal) {
    return $portal->langs;
}

=head2 subscriptionPrice

$subscription_price = subscriptionPrice($portal)

=over 4

Get the subscription price for the portal. This is a temporary function and returns a hard-coded value. It eventually needs to be replaced by something that can handle multiple portals and possibly multiple subscription periods.

=back

=cut
method subscriptionPrice($portal) {
    return 100 if ($portal->id eq 'eco');
    return 0;
}


=head2 setView

$current_view = setView($request);

=over 4

Set the current view according the request parameters.

=back

=cut
method setView($request, $config) {
    if ($request->params->{fmt}) {
        my $fmt = $request->params->{fmt};
        if ($config->{fmt}->{$fmt}) {
            return $config->{fmt}->{$fmt}->{view};
        }
    }
    
    return $config->{default_view} || 'Default';
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

    return 'text/html'
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
method configAll ($portal, $request, $config) {
    my %config = ();

    $config{lang} = $self->setLang($portal, $request, $config);
    $config{portal} = $self->portalId($portal);
    $config{portal_name} = $self->portalName($portal, $config{lang});
    $config{search_bar_placeholder} = $self->searchPlaceholder($portal, $config{lang});
    $config{supported_langs} = $self->supportedLangs($portal);
    $config{subscripton_price} = $self->subscriptionPrice($portal);
    $config{current_view} = $self->setView($request, $config);
    $config{content_type} = $self->setContentType($request, $config);
    $config{cookie_domain} = $self->setCookieDomain($request, $config);

    return %config;
}

1;
