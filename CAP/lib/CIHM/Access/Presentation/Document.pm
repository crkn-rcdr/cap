package CIHM::Access::Presentation::Document;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/HashRef ArrayRef Str/;
use List::Util qw/min max/;
use POSIX qw/ceil/;
use List::MoreUtils qw/any/;
use Number::Bytes::Human qw(format_bytes);

has 'record' => (
  is       => 'ro',
  isa      => HashRef,
  required => 1
);

has 'image_client' => (
  is  => 'ro',
  isa => sub {
    die "$_[0] is not a valid object"
      unless ref($_[0]) eq 'CIHM::Access::Presentation::ImageClient';
  },
  required => 1
);

has 'swift_client' => (
  is  => 'ro',
  isa => sub {
    die "$_[0] is not a valid object"
      unless ref($_[0]) eq 'CIHM::Access::Presentation::SwiftClient';
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

# For presentation documents of type "document" (i.e. manifests), determine
# if the manifest is a PDF or has canvas components.
# This populates the `item_mode` property.
sub _build_item_mode {
  my ($self) = @_;
  if ($self->is_type("document")) {
    if (defined $self->record->{components}) {
      return "noid";
    } elsif ($self->item_download) {
      return "pdf";
    }
  }
  return "";
}

sub _build_items {
  my ($self) = @_;
  if ($self->is_type("series")) {
    return [ map { {key => $_, %{$self->record->{items}{$_}}} }
        @{$self->record->{order}} ];
  }
  if ($self->is_type("document") && $self->item_mode eq "noid") {
    return [
      map {
        my $seq              = $_;
        my $page_slug        = $self->record->{order}[ $seq - 1 ];
        my $component_record = $self->record->{components}{$page_slug};
        my $noid             = $component_record->{noid};

        my $r = {
          %{$component_record},
          seq => $seq,
          iiif_image_info => $self->image_client->info($noid),
          iiif_image_full => $self->image_client->full($noid)
        };

        if ($component_record->{canonicalDownload}) {
          # Not likely in use any more, but this is how single-page PDFs are found in the preservation Swift repository.
          my $obj_path = $component_record->{canonicalDownload};
          $r->{download_uri} = $self->swift_client->preservation_uri($obj_path);
        } elsif (
          $component_record->{canonicalDownloadExtension}
        ) {
          # This generates the URL for a single page from the access-files Swift repository.
          my $obj_path = join('.', $noid, $component_record->{canonicalDownloadExtension});

          my $filename = join('.', $page_slug, $component_record->{canonicalDownloadExtension});

          $r->{download_uri} = $self->swift_client->access_uri($obj_path, $filename);
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

sub is_type {
  my ($self, $type) = @_;
  return $self->record->{type} eq $type;
}

sub is_in_collection {
  my ($self, $collection) = @_;
  return any { $_ eq $collection } @{$self->record->{collection}};
}

sub has_children {
  my ($self) = @_;
  if (defined $self->record->{order}) {
    return scalar(@{$self->record->{order}});
  } else {
    return 0;
  }
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

# Checks the access repository for a multi-page PDF, falls back to preservation, or returns undefined.
sub item_download {
  my ($self) = @_;
  if( (ref $self->record->{ocrPdf} eq "HASH" ) && $self->record->{ocrPdf}->{extension} ) {
    my $slug = $self->record->{_id}; 
    my $item_download =  join('.', $self->record->{noid}, $self->record->{ocrPdf}{extension});
    my $item_filename =  join('.', $slug, $self->record->{ocrPdf}{extension});
    return $item_download ? $self->swift_client->access_uri($item_download, $item_filename) : undef;
  } elsif ( $self->record->{canonicalDownload} ) {
    my $item_download = defined $self->record->{file} ? $self->record->{file}{path} : $self->record->{canonicalDownload};
    return $item_download ? $self->swift_client->preservation_uri($item_download) : undef;
  }
  return undef;
}

# Checks the access repository for a multi-page PDF, falls back to preservation, or returns undefined.
sub item_download_size {
  my ($self) = @_;
  if( (ref $self->record->{ocrPdf} eq "HASH" ) && $self->record->{ocrPdf}->{size} ) {
    return format_bytes($self->record->{ocrPdf}->{size});
  } elsif ( $self->record->{canonicalDownload} ) {
    my $size = defined $self->record->{file} ? $self->record->{file}->{size} : undef;
    return $size ? format_bytes($size) : undef;
  }
  return undef;
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

sub iiif_annotation {
  my ($self, $seq, $is_root) = @_;
  my $item       = $self->item($seq);
  my $annotation = {
    id         => $self->_iiif_url("annotation/p$seq/image"),
    type       => "Annotation",
    motivation => "painting",
    body       => {
      id      => $self->image_client->full($item->{noid}),
      type    => "Image",
      format  => "image/jpeg",
      service => [ {
          id      => $self->image_client->bare($item->{noid}),
          type    => "ImageService2",
          profile => "level2"
        }
      ],
      height => $item->{canonicalMasterHeight},
      width  => $item->{canonicalMasterWidth}
    },
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

sub iiif_thumbnail {
  my ($self, $seq, $is_root) = @_;
  my $item = $self->item($seq);
  my $thumbnail = {
    id => $self->image_client->full($item->{noid}),
    type => "Image",
    format => "image/jpeg"
  };
  return $is_root ? {_iiif_context, %$thumbnail} : $thumbnail;
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
    thumbnail => [ $self->iiif_thumbnail($seq) ],
    items  => [ $self->iiif_annotation_page($seq) ],
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
        homepage => [{
          id    => "https://www.crkn-rcdr.ca/",
          type  => "Text",
          label => {
            en => ["Canadian Research Knowledge Network"],
            fr => ["Réseau canadien de documentation pour la recherche"]
          },
          format => "text/html"
        }]
      }
    ],
    metadata => [],
    items    => [ map { $self->iiif_canvas($_) } 1 .. @{$self->items} ]};
}

1;
