package CIHM::Access::Presentation;

use utf8;
use strictures 2;

use Moo;
use List::MoreUtils qw/any/;
use Types::Standard qw/Int Str Enum/;
use CIHM::Access::Presentation::Document;
use CIHM::Access::Presentation::ImageClient;
use CIHM::Access::Presentation::SwiftClient;
with 'Role::REST::Client';

has '+type' => ( default => 'application/json' );

has '+persistent_headers' =>
  ( default => sub { return { Accept => 'application/json' }; } );

# IIIF Image API service
has 'image_endpoint' => (
  is => 'ro',
  isa => Str,
  required => 1
);

# Preservation swift container. Only in use now for multi-page PDFs, pending new work on that front.
has 'swift_container_preservation' => (
  is => 'ro',
  isa => Str,
  required => 1
);

# Access file container.
has 'swift_container_access' => (
  is => 'ro',
  isa => Str,
  required => 1
);

# Key used to sign Swift temp URLs.
has 'swift_temp_url_key' => (
  is => 'ro',
  isa => Str,
  required => 1
);

# The limit of nodes that can appear in a sitemap page.
has 'sitemap_node_limit' => (
  is       => 'ro',
  isa      => Int,
  required => 1
);

has 'image_client' => (
  is => 'lazy',
  default => sub { return CIHM::Access::Presentation::ImageClient->new({ endpoint => shift->image_endpoint }); }
);

has 'swift_client' => (
  is => 'lazy',
  default => sub {
    my $self = shift;
    return CIHM::Access::Presentation::SwiftClient->new({
      container_preservation => $self->swift_container_preservation,
      container_access => $self->swift_container_access,
      temp_url_key => $self->swift_temp_url_key
    });
  }
);

# fetch a copresentation document with key $key, which must be in collection $collection
# $domain is the host of the incoming request
sub fetch {
  my ( $self, $key, $collection, $domain ) = @_;

  my $response = $self->get("/$key");
  if ( $response->failed ) {
    my $error = $response->error;
    die "Presentation lookup of key $key failed: $error";
  } else {
    if ( $response->data->{type} eq 'page' ||
      any { $_ eq $collection } @{ $response->data->{collection} } ) {
      return CIHM::Access::Presentation::Document->new( {
          record     => $response->data,
          image_client => $self->image_client,
          swift_client => $self->swift_client,
          domain => $domain
        }
      );
    } else {
      die "Document $key not found in $collection collection";
    }
  }
}

# get the number of titles found in a given collection
sub title_count {
  my ( $self, $collection ) = @_;
  my $response = $self->get(
    "/_design/tdr/_view/coltitles",
    {
      startkey => "[\"$collection\"]",
      endkey   => "[\"$collection\", {}]",
      reduce   => "true"
    }
  );
  if ( $response->failed ) {
    my $error = $response->error;
    die "Could not get title_count for $collection: $error";
  } else {
    return $response->data->{rows}[0]{value} || 0;
  }
}

# get a list of titles found in a given collection, paginated according to sitemap_node_limit
sub title_list {
  my ( $self, $collection, $page ) = @_;

  my $response = $self->get(
    "/_design/tdr/_view/coltitles",
    {
      startkey     => "[\"$collection\", {}]",
      endkey       => "[\"$collection\"]",
      reduce       => 'false',
      include_docs => 'false',
      descending   => 'true',
      limit        => $self->sitemap_node_limit,
      skip         => $self->sitemap_node_limit * ( $page - 1 )
    }
  );
  if ( $response->failed ) {
    my $error = $response->error;
    die "Could not get title_list for $collection, page $page: $error";
  } else {
    return [map { { key => $_->{id}, updated => $_->{key}[1] } }
        @{ $response->data->{rows} }];
  }
}

1;
