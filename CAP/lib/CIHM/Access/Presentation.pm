package CIHM::Access::Presentation;

use utf8;
use strictures 2;

use Moo;
use List::MoreUtils qw/any/;
use Types::Standard qw/Int Str Enum/;
use CIHM::Access::Presentation::Document;
with 'Role::REST::Client';

has '+type' => ( default => 'application/json' );

has '+persistent_headers' =>
  ( default => sub { return { Accept => 'application/json' }; } );

has 'derivative' => (
  is  => 'ro',
  isa => sub {
    die "$_[0] is not a CIHM::Access::Derivative"
      unless ref( $_[0] ) eq 'CIHM::Access::Derivative';
  },
  required => 1
);

has 'download_mode' => (
  is  => 'ro',
  isa => Enum [qw/swift zfs/]
);

has 'download_swift' => (
  is  => 'ro',
  isa => sub {
    die "$_[0] is not a CIHM::Access::Download::Swift"
      unless ref( $_[0] ) eq 'CIHM::Access::Download::Swift';
  },
  required => 1
);

has 'download_zfs' => (
  is  => 'ro',
  isa => sub {
    die "$_[0] is not a CIHM::Access::Download::ZFS"
      unless ref( $_[0] ) eq 'CIHM::Access::Download::ZFS';
  },
  required => 1
);

has 'prezi_demo_endpoint' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

has 'sitemap_node_limit' => (
  is       => 'ro',
  isa      => Int,
  required => 1
);

# fetch a copresentation document with key $key, which must be in collection $collection
sub fetch {
  my ( $self, $key, $collection ) = @_;

  my $response = $self->get("/$key");
  if ( $response->failed ) {
    my $error = $response->error;
    die "Presentation lookup of key $key failed: $error";
  } else {
    if ( $response->data->{type} eq 'page' ||
      any { $_ eq $collection } @{ $response->data->{collection} } ) {
      my $download = $self->download_mode eq 'swift' ? $self->download_swift :
        $self->download_zfs;
      return CIHM::Access::Presentation::Document->new( {
          record              => $response->data,
          derivative          => $self->derivative,
          download            => $download,
          prezi_demo_endpoint => $self->prezi_demo_endpoint
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
