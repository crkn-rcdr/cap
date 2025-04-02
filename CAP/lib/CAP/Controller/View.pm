package CAP::Controller::View;
use Moose;
use namespace::autoclean;
use JSON qw/encode_json/;
use Number::Bytes::Human qw(format_bytes);
use LWP::UserAgent;
use JSON qw(decode_json encode_json);
use URI::Escape qw(uri_escape);
use CAP::Utils::ArkURL qw(get_ark_url);

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::View - Catalyst Controller

=cut


sub index : Path('') {
  my ( $self, $c, $key, $seq ) = @_;
  $c->stash->{domain} = $c->req->uri->host;

  $c->detach( '/error', [404, "Document key not provided"] ) unless $key;

  my $doc;
  eval {
    $doc = $c->model('Presentation')->fetch( $key, $c->portal_id, $c->req->uri->host );
  };
  $c->detach( '/error',
    [404, "Presentation fetch failed on document $key: $@"] )
    if $@;

  if ( $doc->is_type('series') ) {
    $c->detach( 'view_series', [$doc] );
  } elsif ( $doc->is_type('document') ) {
    $c->detach( 'view_item', [$doc, $seq] );
  } elsif ( $doc->is_type('page') ) {
    $c->response->redirect(
      $c->uri_for_action(
        'view/index',
        $doc->record->{pkey},
        $doc->record->{seq}
      )
    );
    $c->detach();
  } else {
    $c->detach(
      '/error',
      [
        404,
        "Presentation document has unsupported type $doc->record->{type}: $key"
      ]
    );
  }
}

sub view_item : Private {
  my ( $self, $c, $item, $seq ) = @_;

  # Retrieve the Persistent URL if record key exists
  if ( my $record_key = $item->record->{key} ) {
       my $ark_url    = get_ark_url($c, $record_key);
       $c->stash->{ark_url} = $ark_url;
    
  }
  
  if ( $item->has_children ) {
    $seq = $item->first_component_seq unless ( $seq && $seq =~ /^\d+$/ );

    # Make sure the requested page exists.
    $c->detach( "/error", [404, "Page not found: $seq"] )
      unless $item->has_child($seq);

    my $child_key = join( '.', $item->record->{key}, $seq);
    my $canvas = $c->model('Presentation')->fetch( $child_key, $c->portal_id, $c->req->uri->host );
    my $child_size = $canvas->record->{canonicalMasterSize};
    if( $child_size ) {
      $child_size = format_bytes($child_size);
    }

    my $pdf_size = $item->first_component_size($seq);
    if( $pdf_size ) {
      $pdf_size = format_bytes($pdf_size);
    }

   

    $c->stash(
      item               => $item,
      record             => $item->record,
      item_download      => $item->item_download,
      item_download_size => $item->item_download_size,
      seq                => $seq,
      template           => "view_item.tt",
      child_size         => $child_size,
      pdf_size           => $pdf_size,
   
    );
  } elsif ($item->item_mode eq "pdf") {
    $c->stash(
      item     => $item,
      record   => $item->record,
      item_download => $item->item_download,
      template => "view_pdf.tt"
    );
  } else {
    $c->stash(
      item => $item,
      record => $item->record,
      template => "view_item.tt"
    );
  }

  if ( $c->portal_id eq "parl" ) {
    $c->stash(
      nodes => [
        sort {
          $a->[0] cmp $b->[0]   ||    # eng before fra
            $b->[1] cmp $a->[1] ||    # s before c
            $a->[3] cmp $b->[3]
        } @{ $item->record->{parlNode} }
      ]
    );
  }

  return 1;
}

sub view_series : Private {
  my ( $self, $c, $series ) = @_;
  
  # Retrieve the Persistent URL if record key exists
  if ( my $record_key = $series->record->{key} ) {
       my $ark_url    = get_ark_url($c, $record_key);
       $c->stash->{ark_url} = $ark_url;
   
  }
  $c->stash(
    series   => $series,
    template => "view_series.tt"
  );

  return 1;
}

# Select a random document
sub random : Path('/viewrandom') Args() {
  my ( $self, $c ) = @_;

  my $doc;
  eval {
    $doc = $c->model('Search')->random_document( {
        root_collection => $c->portal_id
      }
    )->{resultset}{documents}[0];
  };
  $c->detach( '/error', [503, "Solr error: $@"] ) if ($@);

  if(defined $doc) {
    $c->res->redirect( $c->uri_for_action( 'view/index', $doc->{key} ) );
  }
  $c->detach();
}



__PACKAGE__->meta->make_immutable;

1;
