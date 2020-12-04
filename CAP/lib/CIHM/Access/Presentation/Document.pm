package CIHM::Access::Presentation::Document;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/HashRef ArrayRef/;
use List::Util qw/min/;
use List::MoreUtils qw/any/;

has 'record' => (
  is       => 'ro',
  isa      => HashRef,
  required => 1
);

has 'derivative' => (
  is  => 'ro',
  isa => sub {
    die "$_[0] is not a CIHM::Access::Derivative"
      unless ref( $_[0] ) eq 'CIHM::Access::Derivative';
  },
  required => 1
);

has 'download' => (
  is  => 'ro',
  isa => sub {
    die "$_[0] is not a valid object"
      unless ref( $_[0] ) eq 'CIHM::Access::Download';
  },
  required => 1
);

has 'items' => (
  is  => 'lazy',
  isa => ArrayRef
);

sub BUILD {
  my ( $self, $args ) = @_;

  # handle date tags correctly
  my $dates = $args->{record}{tagDate};
  if ( defined $dates ) {
    my @date_tags = ();
    foreach my $date_str (@$dates) {
      my $tag = '';
      if ( $date_str =~ /\[(.+) TO (.+)\]/ ) {
        my ( $date1, $date2 ) = ( _format_date($1), _format_date($2) );
        $tag = $date1 && $date2 ? "$date1 – $date2" : '';
      } else {
        $tag = _format_date($date_str);
      }
      push( @date_tags, $tag ) if $tag;
    }
    $args->{record}{tagDate} = \@date_tags;
  }
}

sub _build_items {
  my ($self) = @_;
  if ( $self->is_type("series") ) {
    return [map { $self->record->{items}{$_} } @{ $self->record->{order} }];
  }
  if ( $self->is_type("document") ) {
    return [
      map {
        my $seq              = $_;
        my $page_slug        = $self->record->{order}[$seq - 1];
        my $component_record = $self->record->{components}{$page_slug};
        my $image_source =
          $self->is_born_digital_pdf ? $self->record->{canonicalDownload} :
          $component_record->{noid};

        my $uri = $self->derivative->iiif_template( $image_source,
          $self->is_born_digital_pdf );
        $uri =~ s/\$SEQ/$seq/g;

        my $r = {
          %{$component_record},
          key => $page_slug,
          seq => $seq,
          uri => $uri
        };

        if ( !$self->is_born_digital_pdf ) {
          $r->{iiif_default} =
            $self->derivative->iiif_default( $component_record->{noid} );
          $r->{iiif_service} =
            $self->derivative->iiif_service( $component_record->{noid} );
        }

        if ( $component_record->{canonicalDownload} ) {
          $r->{download_uri} =
            $self->download->uri( $component_record->{canonicalDownload} );
        }

        $r;
      } 1 .. @{ $self->record->{order} }
    ];
  }
  return [];
}

sub _slug {
  my ($self) = @_;
  return $self->record->{_id};
}

sub _format_date {
  my ($date) = @_;
  $date =~ /^(\d{4})-(\d{2})-(\d{2}).+/;
  return $2 == 1 && $3 == 1 || $2 == 12 && $3 == 31 ? $1 : "$1-$2-$3";
}

sub is_type {
  my ( $self, $type ) = @_;
  return $self->record->{type} eq $type;
}

sub is_born_digital_pdf {
  my ($self) = @_;
  return $self->is_type("document") &&
    !$self->record->{components}{ $self->record->{order}[0] }{canonicalMaster};
}

sub is_in_collection {
  my ( $self, $collection ) = @_;
  return any { $_ eq $collection } @{ $self->record->{collection} };
}

sub has_children {
  my ($self) = @_;
  return scalar( @{ $self->record->{order} } );
}

sub child_count { return shift->has_children() }

sub has_child {
  my ( $self, $seq ) = @_;
  return !!$self->record->{order}[$seq - 1];
}

sub has_parent {
  my ($self) = @_;
  return !!$self->record->{pkey};
}

sub item {
  my ( $self, $seq ) = @_;
  return $self->items->[$seq - 1];
}

sub component {
  my ( $self, $seq ) = @_;
  return $self->item($seq);
}

sub first_component_seq {
  my ($self) = @_;
  return 1 unless $self->is_type('document');

  my $limit = min 10, scalar( @{ $self->record->{order} } );
  foreach my $seq ( 1 .. $limit ) {
    foreach my $test ( 'cover', 'title page', 'table of contents', 'p\.' ) {
      return $seq if ( $self->component($seq)->{label} =~ /$test/i );
    }
  }

  return 1;
}

sub canonical_label {
  my ($self) = @_;
  return ( $self->record->{plabel} ? $self->record->{plabel} . " : " : "" ) .
    $self->record->{label};
}

sub item_download {
  my ($self) = @_;
  my $item_download = $self->record->{canonicalDownload};
  return $item_download ? $self->download->uri($item_download) : undef;
}

sub token {
  my ($self) = @_;
  my $is_pdf = $self->component(1)->{canonicalMaster} ? 0 : 1;
  return $self->derivative->item_token( $self->record->{key}, $is_pdf );
}

1;
