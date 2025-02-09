package CAP::Controller::View;
use Moose;
use namespace::autoclean;
use JSON qw/encode_json/;
use Number::Bytes::Human qw(format_bytes);
use LWP::UserAgent;
use JSON qw(decode_json encode_json);
use URI::Escape qw(uri_escape);

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
    my $record_key = $item->record->{key};
    if ($record_key) {
      my $ark;
      my $json = JSON->new->utf8->canonical->pretty;
      my $ark_resolver_base = $c->config->{ark_resolver_base};
      my $ark_resolver_endpoint = "slug";
      my $ark_resolver_url = $ark_resolver_base . $ark_resolver_endpoint;

      # Initialize a UserAgent object
      my $ua = LWP::UserAgent->new;
      $ua->timeout(10);

      # Build a query param
      my %query_params = ( slug => $record_key );

      # Build an url with a query params
      my $ark_url_query = URI->new($ark_resolver_url);
      $ark_url_query->query_form(%query_params) if %query_params; 

      # Call Ark-reslover api to get an ark
      eval {
           my $response = $ua->get($ark_url_query);
           if ($response->is_success) {
              my $data;
              my $content = $response->decoded_content;
              $data =$json->decode($content);
              $ark = $data->{data}->{ark};
           }
           1;
        } or do {
          $c->stash->{ark_no_found} = "Persistent URL unavailable";
        };
      unless ($ark){
        $c->stash->{ark_no_found} = "Persistent URL unavailable";
        
      } else {
        my $ark_url = "https://legacy-n2t.n2t.net/ark:/69429-test/foobar/" . $ark;
        $c->stash->{ark_url} = $ark_url;
      }
        
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
