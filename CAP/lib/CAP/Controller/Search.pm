package CAP::Controller::Search;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Scalar::Util qw/looks_like_number/;
use Types::Standard qw/Int/;

BEGIN { extends 'Catalyst::Controller'; }

# limit to matching page search return count
has 'matching_page_limit' => (
  is       => 'ro',
  isa      => Int,
  required => 1
);

sub index : Path('') {
  my ( $self, $c, $handler, $page ) = @_;
  $page =
    $page && looks_like_number($page) ? $page :
    looks_like_number($handler)       ? $handler :
    1;

  $handler = $handler && !looks_like_number($handler) ? $handler : 'general';
  $c->detach('matching_pages') if ( $handler eq 'page' );

  # Retrieve the first page of results unless otherwise requested.
  $page = 1 unless ( $page > 1 );
  my $offset = ( $page - 1 ) * 10;

  # Run the main search
  my $search;
  eval {
    $search = $c->model('Search')->dispatch(
      $handler,
      {
        root_collection => $c->portal_id,
        schema          => $c->stash->{portal}->search_schema,
        offset          => $offset
      },
      $c->req->params
    );
  };

  $c->detach( '/error', [503, "Solr error: $@"] ) if ($@);
  $c->detach( '/error', [400, "Solr error: " . $search->{error}{msg}] )
    if $search->{error};

  $c->stash(
    error          => $search->{error},
    resultset      => $search->{resultset},
    query          => $search->{query}->to_cap,
    match_pages    => $search->{query}->has_text_terms,
    search_params  => handle_params( $c->req->params ),
    search_handler => $handler,
    template       => 'search.tt',
  );

  return 1;
}

sub matching_pages : Private {
  my ( $self, $c ) = @_;

  my $search;
  eval {
    $search = $c->model('Search')->dispatch(
      'page',
      {
        limit  => $self->matching_page_limit,
        schema => 'default'
      },
      $c->req->params
    );
  };
  $c->detach( '/error', [503, "Solr error: $@"] ) if ($@);

  $c->stash(
    resultset => $search->{resultset},
    query     => $search->{query}->cap_query,
    template  => 'search.tt',
  );

  return 1;
}

sub post : Local {
  my ( $self, $c ) = @_;

  my $params = $c->req->params;
  unless ( exists $params->{handler} ) {
    $params->{handler} = $params->{include_issues} ? 'general' : 'browsable';
  }

  my $get_params = $c->model('Search')
    ->transform_query( $params, $c->stash->{portal}->search_schema );
  my $handler = delete $get_params->{handler};
  $handler = '' if $handler eq 'general';

  $c->response->redirect(
    $c->uri_for_action( '/search/index', $handler, $get_params ) );
  $c->detach();
}

sub handle_params {
  my ($params) = @_;
  return {
    pkey  => $params->{pkey}  // "",
    sort  => $params->{so}    // "score",
    df    => $params->{df}    // "",
    dt    => $params->{dt}    // "",
    field => $params->{field} // "",
    lang  => make_array( $params->{lang} ),
    depositor    => make_array( $params->{depositor} ),
    collection   => make_array( $params->{collection} ),
    parl_type    => make_array( $params->{type} ),
    parl_chamber => make_array( $params->{chamber} ),
    parl_session => make_array( $params->{session} ),
  };
}

sub make_array {
  my ($ref) = @_;
  if ($ref) {
    unless ( ref $ref eq 'ARRAY' ) {
      $ref = [$ref];
    }
  } else {
    $ref = [];
  }
  return $ref;
}
__PACKAGE__->meta->make_immutable;

1;
