package CIHM::Access::Presentation::ImageClient;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Str/;
use URI::Escape;

# The IIIF Image API endpoint for which this will generate URLs.
has 'endpoint' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

# Returns a bare IIIF Image URL (i.e. for use within a presentation API 'service' object).
sub bare {
  my ($self, $identifier) = @_;
  return join('/', $self->endpoint, uri_escape($identifier));
}

# Returns a URL for a IIIF Image 'info' request.
sub info {
  my ($self, $identifier) = @_;
  return join('/', $self->bare($identifier), 'info.json');
}

# Returns a URL for a IIIF Image request.
sub image {
  my ($self, $identifier, $region, $size, $rotation, $quality) = @_;
  return join('/', $self->bare($identifier), $region, $size, $rotation, $quality) . '.jpg';
}

# Returns a URL for a IIIF Image request that returns the full image at full size.
sub full {
  my ($self, $identifier) = @_;
  return $self->image($identifier, 'full', 'max', '0', 'default');
}

1;
