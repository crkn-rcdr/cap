package CAP::Controller::Search;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Scalar::Util qw/looks_like_number/;
use Types::Standard qw/Int/;
use HTML::Escape qw/escape_html/;

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


  #while (my ($key, $value) = each(%{ $c->req->params })) {
  #  if(index($key, 'q') != -1) {
  #    $c->req->params->{$key} = html_sanitize($value);
  #  }
  #}
  
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
    search_params  => handle_params($c->req->params),
    search_handler => $handler,
    template       => 'search.tt'
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

sub slug_sanitize {
  my ( $text ) = @_;
  if(defined $text) {
    $text =~ s/[^A-Za-z0-9\.]//g;
  } else {
    $text = "";
  }
  return $text;
}

sub make_slug {
  my ($array) = @_;
  my $i = 0;
  foreach ($array) {
    $array->[$i] = slug_sanitize($array->[$i]);
    $i = $i + 1;
  }
  return $array;
}

sub html_sanitize {
  my ( $text ) = @_;
  if(defined $text) {
    $text = escape_html($text);
  } else {
    $text = "";
  }
  return $text;
}

sub make_escaped {
  my ($array) = @_;
  my $i = 0;
  foreach ($array) {
    $array->[$i] = html_sanitize($array->[$i]);
    $i = $i + 1;
  }
  return $array;
}

sub make_singleton {
  my ($ref) = @_;
  if ($ref) {
    if ( ref $ref eq 'ARRAY' ) {
      $ref = $ref->[0];
    }
  } else {
    $ref = '';
  }
  return $ref;
}

sub handle_params {
  my ($params) = @_;
  return {
    pkey  => slug_sanitize(html_sanitize(make_singleton($params->{pkey}))),
    sort  => html_sanitize(make_singleton($params->{so} // "score")),
    df    => html_sanitize(make_singleton($params->{df})),
    dt    => html_sanitize(make_singleton($params->{dt})),
    field => html_sanitize(make_singleton($params->{field})),
    lang  => make_escaped(make_array($params->{lang})),
    depositor    => make_escaped(make_slug(make_array( $params->{depositor}))),
    collection   => make_escaped(make_slug(make_array( $params->{collection}))),
    parl_type    => make_escaped(make_array($params->{type} )),
    parl_chamber => make_escaped(make_array($params->{chamber})),
    parl_session => make_escaped(make_array($params->{session})),
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
