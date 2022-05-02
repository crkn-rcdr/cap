package CIHM::Access::Derivative;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Str/;
use URI::Escape;

has 'endpoint' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

sub iiif_default {
  my ($self, $key) = @_;
  return
    join('/', $self->iiif_service($key), 'full', 'max', '0', 'default.jpg');
}

sub iiif_info {
  my ($self, $key) = @_;
  return join('/', $self->iiif_service($key), 'info.json');
}

sub iiif_service {
  my ($self, $key) = @_;
  return join('/', $self->endpoint, uri_escape($key));
}

1;
