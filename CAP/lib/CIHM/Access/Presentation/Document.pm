package CIHM::Access::Presentation::Document;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/HashRef ArrayRef Str/;
use List::Util qw/min max/;
use POSIX qw/ceil/;
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
      unless ref($_[0]) eq 'CIHM::Access::Derivative';
  },
  required => 1
);

has 'download' => (
  is  => 'ro',
  isa => sub {
    die "$_[0] is not a valid object"
      unless ref($_[0]) eq 'CIHM::Access::Download';
  },
  required => 1
);

# host of the incoming request
has 'domain' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

has 'item_mode' => (
  is  => 'lazy',
  isa => Str
);

has 'items' => (
  is  => 'lazy',
  isa => ArrayRef
);

sub BUILD {
  my ($self, $args) = @_;

  # handle date tags correctly
  my $dates = $args->{record}{tagDate};
  if (defined $dates) {
    my @date_tags = ();
    foreach my $date_str (@$dates) {
      my $tag = '';
      if ($date_str =~ /\[(.+) TO (.+)\]/) {
        my ($date1, $date2) =
          (_format_date($1), _format_date($2));
        $tag = $date1 && $date2 ? "$date1 – $date2" : '';
      } else {
        $tag = _format_date($date_str);
      }
      push(@date_tags, $tag) if $tag;
    }
    $args->{record}{tagDate} = \@date_tags;
  }
}

sub _build_item_mode {
  my ($self) = @_;
  if ($self->is_type("document")) {
    my $component_record =
      $self->record->{components}{$self->record->{order}[0]};

    if ($component_record->{canonicalMaster}) {
      return $component_record->{noid}
        ? "noid"
        : "path";
    } else {
      return "pdf";
    }
  } else {
    return "";
  }
}

sub _build_items {
  my ($self) = @_;
  if ($self->is_type("series")) {
    return [ map { {key => $_, %{$self->record->{items}{$_}}} }
        @{$self->record->{order}} ];
  }
  if ($self->is_type("document")) {
    return [
      map {
        my $seq              = $_;
        my $page_slug        = $self->record->{order}[ $seq - 1 ];
        my $component_record = $self->record->{components}{$page_slug};
        my $item_mode        = $self->item_mode;
        my $image_source     = $self->image_source($component_record);

        my $uri = $self->derivative->iiif_template($image_source, $item_mode);
        $uri =~ s/\$SEQ/$seq/g;

        my $r = {
          %{$component_record},
          key => $page_slug,
          seq => $seq,
          uri => $uri
        };

        if ($item_mode eq "noid") {
          $r->{iiif_default} =
            $self->derivative->iiif_default($component_record->{noid});
          $r->{iiif_service} =
            $self->derivative->iiif_service($component_record->{noid});
        }

        if ($component_record->{canonicalDownload}) {
          $r->{download_uri} =
            $self->download->uri($component_record->{canonicalDownload});
        }

        $r;
      } 1 .. @{$self->record->{order}} ];
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
  my ($self, $type) = @_;
  return $self->record->{type} eq $type;
}

sub image_source {
  my ($self, $component_record) = @_;
  if ($self->item_mode) {
    if ($self->item_mode eq "noid") {
      return $component_record->{noid};
    }

    if ($self->item_mode eq "path") {
      return $component_record->{canonicalMaster};
    }

    if ($self->item_mode eq "pdf") {
      return $self->record->{canonicalDownload};
    }
  }
  return undef;
}

sub is_in_collection {
  my ($self, $collection) = @_;
  return any { $_ eq $collection } @{$self->record->{collection}};
}

sub has_children {
  my ($self) = @_;
  return scalar(@{$self->record->{order}});
}

sub child_count { return shift->has_children() }

sub has_child {
  my ($self, $seq) = @_;
  return !!$self->record->{order}[ $seq - 1 ];
}

sub has_parent {
  my ($self) = @_;
  return !!$self->record->{pkey};
}

sub item {
  my ($self, $seq) = @_;
  return $self->items->[ $seq - 1 ];
}

sub component {
  my ($self, $seq) = @_;
  return $self->item($seq);
}

sub first_component_seq {
  my ($self) = @_;
  return 1 unless $self->is_type('document');

  my $limit = min 10, scalar(@{$self->record->{order}});
  foreach my $seq (1 .. $limit) {
    foreach my $test ('cover', 'title page', 'table of contents', 'p\.') {
      return $seq if ($self->component($seq)->{label} =~ /$test/i);
    }
  }

  return 1;
}

sub canonical_label {
  my ($self) = @_;
  return ($self->record->{plabel} ? $self->record->{plabel} . " : " : "")
    . $self->record->{label};
}

sub item_download {
  my ($self) = @_;
  my $item_download = $self->record->{canonicalDownload};
  return $item_download ? $self->download->uri($item_download) : undef;
}

sub token {
  my ($self) = @_;
  my $is_pdf = $self->component(1)->{canonicalMaster} ? 0 : 1;
  return $self->derivative->item_token($self->record->{key}, $is_pdf);
}

sub _iiif_context {
  return ('@context' => "http://iiif.io/api/presentation/3/context.json");
}

sub _iiif_url {
  my ($self, $remainder) = @_;
  my $domain = $self->domain;
  my $slug   = $self->_slug;
  return "https://$domain/iiif/$slug/$remainder";
}

sub _iiif_image {
  my ($item, $max_side) = @_;
  my $height = $item->{canonicalMasterHeight};
  my $width  = $item->{canonicalMasterWidth};
  if ($max_side) {
    my $divisor = max($height, $width) / $max_side;
    $height = ceil($height / $divisor);
    $width  = ceil($width / $divisor);
  }
  my $size      = $max_side ? "!$max_side,$max_side" : "full";
  my $image_uri = $item->{uri};
  $image_uri =~ s/\$SIZE/$size/g;
  $image_uri =~ s/\$ROTATE/0/g;

  return {
    id      => $image_uri,
    type    => "Image",
    format  => "image/jpeg",
    service => [ {
        id      => $item->{iiif_service},
        type    => "ImageService2",
        profile => "level2"
      }
    ],
    height => $height,
    width  => $width
  };
}

sub iiif_annotation {
  my ($self, $seq, $is_root) = @_;
  my $item       = $self->item($seq);
  my $annotation = {
    id         => $self->_iiif_url("annotation/p$seq/image"),
    type       => "Annotation",
    motivation => "painting",
    body       => _iiif_image($item),
    target     => $self->_iiif_url("canvas/p$seq")};
  return $is_root ? {_iiif_context, %$annotation} : $annotation;
}

sub iiif_annotation_page {
  my ($self, $seq, $is_root) = @_;
  my $page = {
    id    => $self->_iiif_url("page/p$seq/main"),
    type  => "AnnotationPage",
    items => [ $self->iiif_annotation($seq) ]};
  return $is_root ? {_iiif_context, %$page} : $page;
}

sub iiif_canvas {
  my ($self, $seq, $is_root) = @_;
  my $item   = $self->item($seq);
  my $canvas = {
    id     => $self->_iiif_url("canvas/p$seq"),
    type   => "Canvas",
    label  => {none => [ $item->{label} ]},
    height => $item->{canonicalMasterHeight},
    width  => $item->{canonicalMasterWidth},
    items  => [ $self->iiif_annotation_page($seq) ],

    # thumbnail => _iiif_image($item, 200)
  };
  return $is_root ? {_iiif_context, %$canvas} : $canvas;
}

sub iiif_manifest {
  my ($self) = @_;
  return undef unless $self->is_type("document");
  my $slug = $self->record->{_id};

  return {
    _iiif_context,
    id       => $self->_iiif_url("manifest"),
    type     => "Manifest",
    label    => {none => [ $self->canonical_label ]},
    provider => [ {
        id    => "https://www.crkn-rcdr.ca/",
        type  => "Agent",
        label => {
          en => ["Canadian Research Knowledge Network"],
          fr => ["Réseau canadien de documentation pour la recherche"]
        },
        homepage => {
          id    => "https://www.crkn-rcdr.ca/",
          type  => "Text",
          label => {
            en => ["Canadian Research Knowledge Network"],
            fr => ["Réseau canadien de documentation pour la recherche"]
          },
          format => "text/html"
        }}
    ],
    metadata => {},
    items    => [ map { $self->iiif_canvas($_) } 1 .. @{$self->items} ]};
}

1;
