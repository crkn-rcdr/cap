package CAP::Controller::View;
use Moose;
use namespace::autoclean;
use JSON qw/encode_json/;
use Number::Bytes::Human qw(format_bytes);
use LWP::UserAgent;
use JSON qw(decode_json);
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
        eval {
           $ark = $self->_fetch_ark_from_solr($c, $record_key);
        };
        if ($@) {
            $c->detach('/error', [503, "Solr error: $@"]);
        } 
        elsif (!$ark) {
            $c->detach('/error', [404, "Ark not found for record key: $record_key"]);
            }
        else  {
            #my $base_url = $c->request->base;
            #$base_url .= '/' unless $base_url =~ /\/$/;
            #my $ark_url = $base_url . "ark:/69429/foobar/" . $ark;
            my $ark_url = "https://n2t.net/ark:/69429-test/foobar" . $ark;
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

# Get ark from Solr base on record.key

sub _fetch_ark_from_solr {
  my ($self,$c,$record_key) = @_;

  # Get Solr config from env
  my $solr_url = $ENV{SOLR_URL};
  my $solr_account = $ENV{SOLR_USER};
  my $solr_password = $ENV{SOLR_PASSWORD};

  # Initialize http client
  my $ua = LWP::UserAgent->new;
  $ua->timeout(10);

  if ($solr_account && $solr_password) {
    $ua->credentials(
      URI->new($solr_url)->host_port,
      'solr',
      $solr_account => $solr_password,
    );
  }
  my $query_key = uri_escape('slug:"' . $record_key . '"');
  my $url = "$solr_url/select?q=$query_key&wt=json&rows=1";

  #send a request to Solr
  my $response = $ua->get($url);
  if ($response->is_success) {
    my $content = $response->decoded_content;
    my $data = decode_json($content);
     if ($data->{response}{numFound} > 0) {
            my $doc = $data->{response}{docs}[0];
            return $doc->{ark};  
        } else {
             $c->detach( '/error', [503, "Solr error"] );
        }
    } else {
         $c->detach( '/error', [503, "Solr error"] );
    };
  return 1
}

__PACKAGE__->meta->make_immutable;

1;
