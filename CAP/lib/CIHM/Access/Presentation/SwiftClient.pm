package CIHM::Access::Presentation::SwiftClient;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Str/;
use Crypt::Mac::HMAC qw/hmac_hex/;
use URI;

has 'container_preservation' => (
  is     => 'ro',
  coerce => sub {
    URI->new( $_[0] );
  },
  required => 1
);

has 'container_access' => (
  is     => 'ro',
  coerce => sub {
    URI->new( $_[0] );
  },
  required => 1
);

has 'temp_url_key' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

# Returns a Swift TempURL for the preservation file at $obj_path.
sub preservation_uri {
  my ($self, $obj_path) = @_;
  return $self->_uri($self->container_preservation, $obj_path);
}

# Returns a Swift TempURL for the access file at $obj_path.
sub access_uri {
  my ($self, $obj_path) = @_;
  return $self->_uri($self->container_access, $obj_path);
}

sub _uri {
  my ( $self, $container, $obj_path ) = @_;

  my $expires = time + 86400;    # expires in a day
  my $path      = join( '/', $container->path, $obj_path );
  my $payload   = "GET\n$expires\n$path";
  my $signature = hmac_hex( 'SHA1', $self->temp_url_key, $payload );

  my $uri = URI->new( join( '/', $container->as_string, $obj_path ) );
  $uri->query_form(
    { temp_url_sig => $signature, temp_url_expires => $expires } );
  return $uri->as_string;
}

1;
