package CAP::Portal;

use utf8;
use strictures 2;

use Moose;
use namespace::autoclean;

extends 'CAP::Collection';

has 'search' => (
  is       => 'ro',
  isa      => 'Bool',
  required => 1,
  default  => 1
);

has 'search_schema' => (
  is      => 'ro',
  isa     => 'Str',
  default => 'default'
);

has 'subcollections' => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} },
  writer  => '_set_subcollections'
);

has 'pages' => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { {} }
);

sub has_subcollections {
  my ($self) = @_;
  return scalar keys %{ $self->subcollections };
}

sub subcollection_labels {
  my ( $self, $lang ) = @_;
  return {
    map { $_ => $self->subcollections->{$_}->label->{$lang} }
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

  if ( $mapping->{$lang} ) {
    return { redirect => $mapping->{$lang} };
  } else {
    if ( $mapping->{en} ) {
      return { page => $mapping->{en}, title => $mapping->{title}->{$lang} };
    } else {
      return { page => $key, title => $mapping->{title}->{$lang} };
    }
  }
}

1;
