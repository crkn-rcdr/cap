package CAP::Controller::Root;
use Moose;
use namespace::autoclean;

use strict;
use warnings;
use utf8;

use JSON qw/encode_json/;

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
# TODO: do we need this, still?
__PACKAGE__->config->{namespace} = '';

BEGIN { extends 'Catalyst::Controller'; }

# Code that runs on every request.
sub auto : Private {
  my ( $self, $c ) = @_;

  # Detect the portal to use based on the subdomain of the incoming request.
  # If the subdomain doesn't apply to a portal, redirect to some default url.
  my $portal =
    $c->model('Portals')->portal_from_host( $c->req->uri->host );
  if ($portal) {
    $c->stash( portal => $portal );
  } 
  # TURNING OFF AUTO REDIRECT TO CANADIANA.CA IF PORTAL NOT FOUND
  # THIS IS USEFUL FOR DEV OPS
  else {
    $portal =
    $c->model('Portals')->portal_from_host( "www.canadiana.ca" );
    if ($portal) {
      $c->stash( portal => $portal );
    } 
  }

  # Set various per-request configuration variables.
  $c->stash( $c->model('Configurator')->run( $c->req, $c->config ) );

  # Set the content type and template paths based on the view and portal.
  $c->response->content_type( $c->stash->{content_type} );
  $c->stash->{additional_template_paths} = [
    join( '/',
      $c->config->{root},        'templates',
      $c->stash->{current_view}, $c->portal_id ),
    join( '/',
      $c->config->{root},
      'templates', $c->stash->{current_view}, 'Common' )
  ];

  # Set a cookie with the user's language preferences.
  $c->res->cookies->{ $c->config->{cookies}->{lang} } = {
    domain   => $c->stash->{cookie_domain},
    value    => $c->stash->{lang},
    expires  => '+3M',
    httponly => 1,
    secure   => 1,
    samesite => 'None'
  };

  # If the user has clicked on the button closing a message banner,
  # save that preference in a cookie.
  if ( exists $c->request->query_params->{clearbanner} ) {
    $c->res->cookies->{ $c->config->{cookies}->{clearbanner} } = {
      domain   => $c->stash->{cookie_domain},
      value    => $c->config->{message_banner},
      expires  => '+1y',
      httponly => 1,
      secure   => 1,
      samesite => 'None'
    };

    $c->res->redirect( $c->req->uri_with( { clearbanner => undef } ) );
    $c->detach();
    return 1;
  }

  # Stash assorted labels.
  # TODO: Look into whether we need to use depositor labels any more.
  $c->stash(
    depositor_labels =>
      $c->model('Depositors')->as_labels( $c->stash->{lang} ),
    language_labels => $c->model('Languages')->as_labels( $c->stash->{lang} )
  );

  # Stash parl-specific labels, and the parliament browse tree.
  # TODO: determine whether you need to stash the browse tree on every request.
  if ( $portal->id eq 'parl' ) {
    $c->stash(
      supported_types => $c->model('Parl')->supported_types,
      type_labels     => $c->model('Parl')->type_labels( $c->stash->{lang} ),
      chamber_labels => $c->model('Parl')->chamber_labels( $c->stash->{lang} ),
      tree           => $c->model('Parl')->tree()
    );
  }

  # If the portal has subcollections (i.e. is 'online'), stash their labels.
  $c->stash(
    subcollection_labels => $portal->subcollection_labels( $c->stash->{lang} )
  ) if $portal->has_subcollections();

  # We used to offer a JSON api through CAP. We don't any more.
  # Detach to an error for those kinds of requests.
  if ( exists $c->request->query_params->{fmt} &&
    lc( $c->request->query_params->{fmt} ) eq 'json' ) {
    $c->detach( '/error', [404, 'API Unavailable -- API non disponible'] );
  }

  return 1;
}

=head2 favicon()

Handle requests for /favicon.ico by redirecting them to /static/favicon.ico

=cut

sub favicon : Path('favicon.ico') {
  my ( $self, $c ) = @_;
  $c->res->redirect( $c->uri_for_action( '/static', 'favicon.ico' ) );
  $c->detach();
}

# Code that runs if the request does not match an existing route.
# If we don't match anything, we're trying to access a page
sub default : Path {
  my ( $self, $c, @path ) = @_;

  my $path = join '/', @path;
  my $page_lookup =
    $c->stash->{portal}->page_mapping( $c->stash->{lang}, $path );
  my $redirect_lookup =
    $c->stash->{portal}->redirect( $c->stash->{lang}, $path );

  $c->detach( 'error', [404, "Failed lookup for $path"] )
    unless ( $page_lookup || $redirect_lookup );

  if ($redirect_lookup) {
    $c->response->redirect($redirect_lookup);
    $c->detach();
  }

  if ( $page_lookup->{redirect} ) {
    $c->response->redirect( '/' . $page_lookup->{redirect} );
    $c->detach();
  }

  # We should only arrive here if the portal has a page $path in the current
  # language. TODO: We should ensure this isn't some kind of security issue.
  my $include = join( '/', 'pages', $c->stash->{lang}, "$path.html" );
  $c->stash(
    include  => $include,
    template => 'page.tt',
    title    => $page_lookup->{title}
  );

}

sub end : ActionClass('RenderView') {
  my ( $self, $c ) = @_;

  # Don't cache anything except for static resources
  if ( $c->action eq 'static' ) {
    $c->res->header( 'Cache-Control' => 'max-age=3600' );
  } else {
    $c->res->header( 'Cache-Control' => 'no-cache' );
  }

  return 1;
}

sub error : Private {
  my ( $self, $c, $error, $error_message ) = @_;
  $error_message = "" unless ($error_message);
  $c->response->status($error);
  $c->stash->{error}    = $error_message;
  $c->stash->{status}   = $error;
  $c->stash->{template} = "error.tt";
  return 1;
}

sub index : Path('') Args(0) {
  my ( $self, $c ) = @_;

  if ( $c->stash->{portal}->has_banners ) {
    my $banners = $c->stash->{portal}->banners;
    my @list    = keys %$banners;
    my $i       = int( rand( scalar @list ) );
    my $banner  = $list[$i];
    $c->stash->{banner} = {
      image => "/static/images/banners/" . $list[$i] . ".jpg",
      title => $banners->{ $list[$i] },
      url   => $c->uri_for( "/view/" . $list[$i] =~ s/@/\//r )->as_string
    };
  }

  $c->stash->{template} = "index.tt";
}

sub robots : Path('robots.txt') {
  my ( $self, $c ) = @_;
  $c->res->header( 'Content-Type', 'text/plain' );
  my $body = "";

  # If Demo or Test environment, send nothing
  if ( $c->config->{environment} ne 'production' ) {
    $body = <<"ENDTEXT";
User-agent: *
Disallow: /
ENDTEXT
  } else {
    # Else - regular site should be indexed 
    my $sitemap_uri = $c->uri_for('/sitemap/sitemap.xml');
    $body = <<"EOF";
User-agent: *
Disallow: /search
Allow: /search-tips
Disallow: /file
Sitemap: $sitemap_uri
EOF
  }
  $c->res->body($body);
  return 1;
}

sub test_error : Path('error') Args(1) {
  my ( $self, $c, $error ) = @_;
  $c->detach( 'error', [$error, 'Test error'] );
}

# Serve a file in the static directory under root. In production, requests
# for /static should be intercepted and handled by the web server.
sub static : Path('static') : Args() {
  my ( $self, $c, @path ) = @_;
  my $file = join( '/', $c->config->{root}, 'static', @path );

  if ( -f $file ) {
    $c->serve_static_file($file);
  } else {
    $c->detach( 'error', [404, $file] );
  }
  return 1;
}

sub version : Path('version') : Args() {
  my ( $self, $c ) = @_;
  $c->stash->{template} = "version.tt";
  return 1;
}

__PACKAGE__->meta->make_immutable;

1;

