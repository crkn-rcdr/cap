package CAP::Model::Configurator;

=head1 Synopsis

An object for setting per-request configurations based on the portal and the request context. Although methods can be called individually, the standard use case for CAP is to call configAll() near the beginning of a request and stash the result:

$c->stash($c->model('Configurator')->configAll($c->request, $c->config);

=cut

use strictures 2;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

=head1 Methods

=head2 set_lang

$lang = set_lang($request, $config)

=over 4

Set the user interface language based on (in order of preference) the
usrlang request parameter, the usrlang cookie, the browser default, the
portal default and, finally, a hardcoded default of 'en'. Return the
selected language.

=back
=cut

sub set_lang {
  my ( $self, $request, $config ) = @_;

  my $lang;
  my @supported_langs = keys %{ $config->{languages} };

  if ( $request->params->{usrlang} &&
    exists( $config->{languages}->{$request->params->{usrlang} } ) ) {
    $lang = $request->params->{usrlang};
  } elsif (
    $request->cookie( $config->{cookies}->{lang} ) &&
    exists( $config->{languages}->{$request->cookie( $config->{cookies}->{lang} )->value} )
  ) {
    $lang = $request->cookie( $config->{cookies}->{lang} )->value;
  } elsif ( $request->header('Accept-Language') ) {
    foreach my $accept_lang (
      split( /\s*,\s*/, $request->header('Accept-Language') ) ) {
      my ($value) = split( ';q=', $accept_lang );
      if ($value) {
        $value = lc( substr( $value, 0, 2 ) );
        if ( 
          exists( $config->{languages}->{$value} )
        ) {
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

=head2 set_view

$current_view = set_view($request, $config);

=over 4

Set the current view according the request parameters.

=back

=cut

sub set_view {
  my ( $self, $request, $config ) = @_;

  my $fmt = $request->params->{fmt};

  # If a format is defined...
  if ($fmt) {
    my $view = $config->{fmt}->{$fmt};

    # And exists in the config...
    if ($view) {

      # Grab the list of actions that can use this view. Default is
      # * (all actions). If an action matches, use the view
      foreach my $action ( split( /\s+/, $view->{actions} || '*' ) ) {
        if ( $action eq '*' || $action eq $request->action ) {
          return $config->{fmt}->{$fmt}->{view};
        }
      }
    }

    # If the action doesn't match, undefine the format.
    delete( $request->params->{fmt} );
  }

  # In all other cases, use the default view.
  return $config->{fmt}->{default}->{view};
}

=head2 set_content_type

$current_view = set_content_type($request, $config);

=over 4

Set the content-type parameter according to the view type for the request.

=back

=cut

sub set_content_type {
  my ( $self, $request, $config ) = @_;
  if ( $request->params->{fmt} ) {
    my $fmt = $request->params->{fmt};
    if ( $config->{fmt}->{$fmt} ) {
      return $config->{fmt}->{$fmt}->{content_type};
    }
  }

  return 'text/html';
}

=head2 set_cookie_domain

$cookie_domain = set_cookie_domain($request, $config);

=over 4

Sets the domain for cookies to the same one used by the session.

=back

=cut

sub set_cookie_domain {
  my ( $self, $request, $config ) = @_;
  return $config->{cookie_domain};
}

sub set_clearbanner {
  my ( $self, $request, $config ) = @_;

  my $current_banner = $config->{message_banner};
  my $cookie = $request->cookie( $config->{cookies}->{clearbanner} );
  my $cookie_banner = $cookie ? $cookie->value : "0";

  if ($cookie_banner eq $current_banner) {
    return $current_banner;
  } else {
    return 0;
  }
}

=head2 run

%config = run($request, $config)

=over 4

Runs all of the above configurations and returns a hash which can be
passed as an argument to $c->stash() to set all values at once. This is
the standard way to configure CAP for a request.

=back
=cut

sub run {
  my ( $self, $request, $config ) = @_;

  my %config = ();

  $config{lang}          = $self->set_lang( $request, $config );
  $config{current_view}  = $self->set_view( $request, $config );
  $config{content_type}  = $self->set_content_type( $request, $config );
  $config{cookie_domain} = $self->set_cookie_domain( $request, $config );
  $config{clearbanner}   = $self->set_clearbanner( $request, $config );

  return %config;
}

1;
