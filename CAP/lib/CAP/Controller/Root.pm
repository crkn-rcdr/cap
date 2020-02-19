package CAP::Controller::Root;
use Moose;
use namespace::autoclean;

use strict;
use warnings;
use utf8;

use JSON qw/encode_json/;

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
__PACKAGE__->config->{namespace} = '';

BEGIN { extends 'Catalyst::Controller'; }

sub auto : Private {
  my ( $self, $c ) = @_;

  my $portal =
    $c->model('Collections')->portal_from_host( $c->req->uri->host );
  if ($portal) {
    $c->stash( portal => $portal );
  } else {
    $c->res->redirect( $c->config->{default_url} );
    $c->detach();
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

  $c->res->cookies->{ $c->config->{cookies}->{lang} } = {
    domain   => $c->stash->{cookie_domain},
    value    => $c->stash->{lang},
    expires  => time() + 7776000,
    httponly => 1
  };
  $c->stash(
    depositor_labels =>
      $c->model('Depositors')->as_labels( $c->stash->{lang} ),
    language_labels => $c->model('Languages')->as_labels( $c->stash->{lang} )
  );

  if ( $portal->id eq 'parl' ) {
    $c->stash(
      supported_types =>
        ['debates', 'journals', 'committees', 'bills', 'proc', 'sessional'],
      type_labels    => $c->model('Parl')->type_labels( $c->stash->{lang} ),
      chamber_labels => $c->model('Parl')->chamber_labels( $c->stash->{lang} ),
      tree           => $c->model('Parl')->tree()
    );
  }

  $c->stash(
    subcollection_labels => $portal->subcollection_labels( $c->stash->{lang} )
  ) if $portal->has_subcollections();

  # throw JSON requests to error page
  if ( exists $c->request->query_params->{fmt} &&
    lc( $c->request->query_params->{fmt} ) eq 'json' ) {
    $c->detach( '/error', [404, 'API Unavailable -- API non disponible'] );
  }

  # If we got to here, it means we will attempt to actually do
  # something, so increment the request counter and log the request
  $c->forward('CAP::Controller::RequestLogger');

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

# If we don't match anything, we're trying to access a page
sub default : Path {
  my ( $self, $c, @path ) = @_;

  my $path   = join '/', @path;
  my $lookup = $c->stash->{portal}->page_mapping( $c->stash->{lang}, $path );

  $c->detach( 'error', [404, "Failed lookup for $path"] ) unless $lookup;

  if ( $lookup->{redirect} ) {
    $c->response->redirect( '/' . $lookup->{redirect} );
    $c->detach();
  }

  my $page    = $lookup->{page} || '';
  my $include = join( '/', 'pages', $c->stash->{lang}, "$page.html" );
  $c->stash(
    include  => $include,
    template => 'page.tt',
    title    => $lookup->{title}
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
  my $sitemap_uri = $c->uri_for('/sitemap/sitemap.xml');
  my $body        = <<"EOF";
User-agent: *
Disallow: /search
Disallow: /file
Sitemap: $sitemap_uri
EOF
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

__PACKAGE__->meta->make_immutable;

1;

