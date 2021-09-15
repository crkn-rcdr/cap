package CIHM::Access::Download;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Str/;
use Crypt::Mac::HMAC qw/hmac_hex/;
use URI;

has 'container' => (
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

has 'tempURLKey' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

sub uri {
  my ( $self, $download, $access ) = @_;

  my $container = $access ? $self->container_access : $self->container;

  my $expires = time + 86400;    # expires in a day
  my $path      = join( '/', $container->path, $download );
  my $payload   = "GET\n$expires\n$path";
  my $signature = hmac_hex( 'SHA1', $self->tempURLKey, $payload );

  my $uri = URI->new( join( '/', $container->as_string, $download ) );
  $uri->query_form(
    { temp_url_sig => $signature, temp_url_expires => $expires } );
  return $uri->as_string;
}

1;
