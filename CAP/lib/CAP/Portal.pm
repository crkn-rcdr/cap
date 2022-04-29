package CAP::Portal;

use utf8;
use strictures 2;

use Moose;
use namespace::autoclean;

has 'id' => (
    is => 'ro',
    required => 1,
    isa => 'Str'
);

has 'label' => (
    is => 'ro',
    required => 1,
    isa => 'HashRef[Str]'
);

# Font that the portal uses
has 'font' => (
  is      => 'ro',
  isa     => 'Str',
  default => 'Roboto'
);

# In search results, allows the user to expand a result to show the full
# document record
has 'sr_record' => (
  is      => 'ro',
  isa     => 'Bool',
  default => 1
);

# The schema used when searching using the portal.
# Available schemas: general, parl
has 'search_schema' => (
  is      => 'ro',
  isa     => 'Str',
  default => 'default'
);

# The slugs and labels of subcollections found in this portal.
# Used to facet search results.
has 'subcollections' => (
  is      => 'ro',
  isa     => 'HashRef[HashRef[HashRef[Str]]]',
  default => sub { {} },
  writer  => '_set_subcollections'
);

# For portals that have a "first-party" theme, references to each banner
# potentially displayed on the front page.
has 'banners' => (
  is      => 'ro',
  isa     => 'HashRef[Str]',
  default => sub { {} }
);

# Static pages supported on the portal, found at https://PORTAL/page-name
# Note the somewhat confusing data structure, e.g.:
# 
# "search-tips": {
#   "en": { "title": "Search Tips" },
#   "fr": { "redirect": "conseils-de-recherche" }
# }
# 
# means that the page at https://PORTAL/search-tips displays with an English
# title of "Search Tips", and redirects to the page at
# https://PORTAL/conseils-de-recherche if the site language is set to French.
has 'pages' => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} }
);

# Like pages, but redirects to the given URL instead
has 'redirects' => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} }
);

# Google Analytics id
has 'ga_id' => (
  is  => 'ro',
  isa => 'Str'
);

sub has_banners {
  my ($self) = @_;
  return scalar keys %{ $self->banners };
}

sub has_subcollections {
  my ($self) = @_;
  return scalar keys %{ $self->subcollections };
}

sub subcollection_labels {
  my ( $self, $lang ) = @_;
  return {
    map { $_ => $self->subcollections->{$_}->{label}->{$lang} }
      keys %{ $self->subcollections }
  };
}

sub sorted_subcollection_keys {
  my ( $self, $lang ) = @_;
  my $labels = $self->subcollection_labels($lang);
  return [sort { $labels->{$a} cmp $labels->{$b} } keys %$labels];
}

sub page_mapping {
  my ( $self, $lang, $key ) = @_;
  my $mapping = $self->pages->{$key};
  return undef if !$mapping;
  return $mapping->{$lang};
}

sub redirect {
  my ( $self, $lang, $key ) = @_;
  my $redirect = $self->redirects->{$key};
  if ( $redirect && $redirect->{$lang} ) {
    return $redirect->{$lang};
  } else {
    return undef;
  }
}

1;
