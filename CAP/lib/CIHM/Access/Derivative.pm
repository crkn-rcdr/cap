package CIHM::Access::Derivative;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/HashRef Str/;
use Crypt::JWT qw/encode_jwt/;
use URI;
use URI::Escape;

has 'endpoint' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

has 'key' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

has 'password' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

has 'config' => (
  is       => 'ro',
  isa      => HashRef,
  required => 1
);

sub item_token {
  my ($self, $item_key, $is_pdf) = @_;
  my $derivative_exp =
    $is_pdf
    ? "$item_key\\/data\\/sip\\/data\\/files\\/.+\\.pdf"
    : "$item_key\\/data\\/sip\\/data\\/files\\/.+\\.(jpg|jp2|tif)";

  return encode_jwt(
    payload => {
      iss               => $self->key,
      'derivativeFiles' => $derivative_exp
    },
    alg          => 'HS256',
    key          => $self->password,
    auto_iat     => 1,
    relative_exp => 86400              # expires in a day
  );
}

sub iiif_template {
  my ($self, $key, $mode) = @_;
  my $uri = join('/',
    $self->iiif_service($key),
    'full', '$SIZE', '$ROTATE', 'default.jpg');
  if ($mode ne "noid") {
    my @qs = ('token=$TOKEN');
    if ($mode eq "pdf") { push @qs, 'page=$SEQ'; }
    return join('?', $uri, join('&', @qs));
  } else {
    return $uri;
  }
}

sub iiif_default {
  my ($self, $key) = @_;
  return
    join('/', $self->iiif_service($key), 'full', 'max', '0', 'default.jpg');
}

sub iiif_service {
  my ($self, $key) = @_;
  return join('/', $self->endpoint, uri_escape($key));
}

1;
