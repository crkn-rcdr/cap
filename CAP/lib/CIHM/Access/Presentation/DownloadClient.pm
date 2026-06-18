package CIHM::Access::Presentation::DownloadClient;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Int Str/;
use Crypt::Mac::HMAC qw/hmac_hex/;
use URI;
use URI::Escape qw/uri_escape_utf8/;

use constant MAX_TOKEN_TTL => 30 * 60;

has 'endpoint' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

has 'token_secret' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

has 'token_ttl' => (
  is       => 'ro',
  isa      => Int,
  required => 1
);

sub pdf_uri {
  my ($self, $slug, $noid) = @_;
  return $self->item_uri($slug, $noid, 'PDF');
}

sub ocr_uri {
  my ($self, $slug, $noid, @canvas_noids) = @_;
  return $self->item_uri($slug, $noid, 'OCR', @canvas_noids);
}

sub item_uri {
  my ($self, $slug, $noid, $type, @canvas_noids) = @_;

  my $expires = time + $self->_effective_token_ttl;
  my @query = (
    slug => $slug,
    noid => $noid,
    type => uc($type),
  );
  push @query, map { (canvas_noid => $_) } @canvas_noids;
  push @query, (
    expires => $expires,
    sig => $self->_item_signature($slug, $noid, $type, \@canvas_noids, $expires),
  );

  my $uri = URI->new($self->endpoint);
  $uri->query_form(@query);
  return $uri->as_string;
}

sub preservation_uri {
  my ($self, $obj_path, $filename) = @_;
  return $self->object_uri('preservation', $obj_path, $filename);
}

sub access_uri {
  my ($self, $obj_path, $filename) = @_;
  return $self->object_uri('access', $obj_path, $filename);
}

sub object_uri {
  my ($self, $repository, $obj_path, $filename) = @_;

  my $expires = time + $self->_effective_token_ttl;
  my @query = (expires => $expires);
  push @query, filename => $filename if defined $filename && length $filename;
  push @query, sig => $self->_object_signature($repository, $obj_path, $filename // '', $expires);

  my $uri = URI->new($self->_endpoint_path($repository, $obj_path));
  $uri->query_form(@query);
  return $uri->as_string;
}

sub _item_signature {
  my ($self, $slug, $noid, $type, $canvas_noids, $expires) = @_;
  my $payload = join("\n", 'v2', $slug, $noid, uc($type), join("\n", @$canvas_noids), $expires);
  return hmac_hex('SHA256', $self->token_secret, $payload);
}

sub _object_signature {
  my ($self, $repository, $obj_path, $filename, $expires) = @_;
  my $payload = join("\n", 'v1', $repository, $obj_path, $filename, $expires);
  return hmac_hex('SHA256', $self->token_secret, $payload);
}

sub _effective_token_ttl {
  my $self = shift;
  return $self->token_ttl < MAX_TOKEN_TTL ? $self->token_ttl : MAX_TOKEN_TTL;
}

sub _endpoint_path {
  my ($self, $repository, $obj_path) = @_;
  my $endpoint = $self->endpoint;
  $endpoint =~ s{/$}{};

  my @segments = split m{/}, $obj_path;
  my $escaped_path = join('/', map { uri_escape_utf8($_) } @segments);
  return join('/', $endpoint, uri_escape_utf8($repository), $escaped_path);
}

1;
