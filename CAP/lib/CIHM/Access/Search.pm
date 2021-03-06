package CIHM::Access::Search;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Str/;
with 'Role::REST::Client';

use CIHM::Access::Search::Query;
use CIHM::Access::Search::ResultSet;
use CIHM::Access::Search::Schema;
use CIHM::Access::Search::Schema::Parl;

has '+type' => ( default => 'application/json' );

has 'schemas' => (
  is      => 'ro',
  default => sub {
    return {
      default => CIHM::Access::Search::Schema->new(),
      parl    => CIHM::Access::Search::Schema::Parl->new()
    };
  }
);

sub schema {
  my ( $self, $schema_key ) = @_;
  return $self->schemas->{ $schema_key || 'default' };
}

# is your handler a string? you're in luck
sub dispatch {
  my ( $self, $handler, $options, $params ) = @_;
  if ( my $func = $self->can($handler) ) {
    return $func->( $self, $options, $params );
  } else {
    die "Unknown handler: $handler";
  }
}

# HANDLERS
sub general {
  my ( $self, $options, $params ) = @_;

  %$options = (
    %$options,
    facet      => 1,
    date_stats => 1,
    so         => $params->{so}
  );

  return $self->_request( '/search/general', $options, $params );
}

sub page {
  my ( $self, $options, $params ) = @_;
  die "Params did not contain pkey" unless defined $params->{pkey};
  foreach
    my $filter ( keys %{ $self->schema( $options->{schema} )->filters } ) {
    delete $params->{$filter} unless $filter eq 'pkey';
  }

  %$options = ( %$options, text_only => 1 );

  return $self->_request( '/search/page', $options, $params );
}

sub browsable {
  my ( $self, $options, $params ) = @_;

  %$options = (
    %$options,
    facet      => 1,
    date_stats => 1,
    so         => $params->{so}
  );

  return $self->_request( '/search/browsable', $options, $params );
}

sub random_document {
  my ( $self, $options ) = @_;

  %$options = ( %$options, so => 'random' );

  return $self->_request( '/search/randomDocument', $options, {} );
}

# options can include:
# root_collection: filter on a portal-esque collection
# sort: sort order as defined by CIHM::Access::Search::Schema
# offset: row to start search on (0-index)
# limit: number of rows to return
# facet: flag for turning on faceted results, with fields based on Schema
# date_stats: flag for turning on pubmin/pubmax
# text_only: search text fields only
# schema: search schema (default or parl)
sub _request {
  my ( $self, $handler, $options, $params ) = @_;

  my $field_key = $options->{text_only} ? 'text' : 'general';
  my $query     = $self->query( $params, $field_key, $options->{schema} );
  my $search    = { query => $query };

  my $resultset = $self->_resultset( $handler, $options, $query );

  if ( ref $resultset eq 'CIHM::Access::Search::ResultSet' ) {
    $search->{resultset} = $resultset;
  } else {
    $search->{error} = $resultset->{error};
  }

  return $search;
}

sub _resultset {
  my ( $self, $handler, $options, $query ) = @_;

  my $data = {};
  $data->{query}  = $query->to_solr->{q};
  $data->{filter} = $query->to_solr->{fq};

  if ( $options->{root_collection} ) {
    push @{ $data->{filter} }, 'collection:' . $options->{root_collection};
  }

  my $sort = $self->_get_sort( $options->{so}, $options->{schema} );
  $data->{sort} = $sort if ($sort);

  $data->{offset} = $options->{offset} || 0;
  $data->{limit}  = $options->{limit} if ( defined $options->{limit} );
  $data->{fields} = $options->{fields} if ( defined $options->{fields} );

  $data->{params} = {};
  $data->{params}{'facet.field'} =
    [map { "{!ex=$_}$_" } @{ $self->schema( $options->{schema} )->facets }]
    if $options->{facet};

  if ( $options->{date_stats} ) {
    $data->{params}{stats} = 'true';
    $data->{params}{'stats.field'} =
      ['{!min=true}pubmin', '{!max=true}pubmax'];
  }

  my $output = $self->post( $handler, $data )->data;
  if ( exists $output->{responseHeader} &&
    exists $output->{responseHeader}{status} &&
    $output->{responseHeader}{status} == 0 ) {
    return CIHM::Access::Search::ResultSet->new($output);
  } else {
    return $output;
  }
}

sub _get_sort {
  my ( $self, $so, $schema_key ) = @_;
  if ( defined $so && exists $self->schema($schema_key)->sorting->{$so} ) {
    my $def = $self->schema($schema_key)->sorting->{$so};
    return ref($def) eq 'CODE' ? &$def : $def;
  }
  return undef;
}

# builds a CIHM::Access::Search::Query using the local schema
sub query {
  my ( $self, $params, $field_key, $schema_key ) = @_;
  my $args = { schema => $self->schema($schema_key), params => $params };
  $args->{field_key} = $field_key if $field_key;
  return CIHM::Access::Search::Query->new($args);
}

# transforms a posted search into terms to redirect to
sub transform_query {
  my ( $self, $post_params, $schema_key ) = @_;
  my $get_params = {};

  # copy over filter parameters, search handler, and requested return format
  for ( keys %{ $self->schema($schema_key)->filters }, 'handler', 'fmt' ) {
    $get_params->{$_} = $post_params->{$_} if exists $post_params->{$_};
  }

  # "Search in:" parameter
  my $base_field = $post_params->{field};
  $base_field = ''
    unless ( $base_field &&
    exists $self->schema($schema_key)->fields->{general}{$base_field} );

  my @pointer = ( 0, 0 );
  my $or      = 0;
  while (
    ( $post_params->{q} || '' ) =~ /
		(-)?+				# negation
		(?:([a-z]+):)?+		# field_modifier
		(
			[^\s\"]+ |		# word
			\"[^\"]+\"		# phrase
		)    
    /gx
  ) {
    my ( $negation, $field_modifier, $token ) =
      ( $1 || '', $2 || '', $3 || '' );

    # we have an OR. the pointer's y-value should change, not the x-value
    if ( $negation eq '' && $field_modifier eq '' && $token eq '|' ) {

      # only OR if there's something to OR with
      if ( $get_params->{ _term_key( $pointer[0] - 1, $pointer[1] ) } ) {
        $pointer[0] -= 1;
        $pointer[1] += 1;
        $or = 1;
      }

      next;
    }

    $pointer[1] = 0 unless $or;

    $field_modifier = $field_modifier || $base_field;
    $field_modifier .= ':' if $field_modifier;
    $get_params->{ _term_key(@pointer) } = "$negation$field_modifier$token";

    $pointer[0] += 1;
    $or = 0;
  }

  return $get_params;
}

sub _term_key {
  my ( $x, $y ) = @_;
  return "q$x.$y";
}

1;
