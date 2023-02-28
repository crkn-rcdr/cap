package CAP::Controller::Files;

use Moose;
use namespace::autoclean;
use JSON;
use Number::Bytes::Human qw(format_bytes);

BEGIN { extends 'Catalyst::Controller'; }

sub myaction2 :Path('get'){
  my ($self, $c, $key, $seq) = @_;

  $c->detach('/error', [ 404, "Slug not provided" ]) unless $key;

  my $doc;
  eval {
    $doc = $c->model('Presentation')
      ->fetch($key, $c->portal_id, $c->req->uri->host);
  };
  $c->detach('/error',
    [ 404, "Presentation fetch failed on document $key: $@" ])
    if $@;

  if ($doc->item_mode ne "noid") {
    $c->detach("/error", [ 404, "File service unavailable." ]);
  }

  if(defined $doc &&  $doc->is_type('document') ) {
    
    if ( $doc->has_children ) {
      $seq = $doc->first_component_seq unless ( $seq && $seq =~ /^\d+$/ );

      # Make sure the requested page exists.
      $c->detach( "/error", [404, "Page not found: $seq"] )
        unless $doc->has_child($seq);

      my $child_key = join( '.', $doc->record->{key}, $seq);
      my $canvas = $c->model('Presentation')->fetch( $child_key, $c->portal_id, $c->req->uri->host );
      my $child_size = $canvas->record->{canonicalMasterSize};
      if( $child_size ) {
        $child_size = format_bytes($child_size);
      }

      my $pdf_size = $doc->first_component_size($seq);
      if( $pdf_size ) {
        $pdf_size = format_bytes($pdf_size);
      }

      $c->stash( data => {
        child_size         => $child_size,
        pdf_size           => $pdf_size
      });
    }

  } else {

    $c->stash( data => {
      child_size         => 0,
      pdf_size           => 0
    });

  }

  my $json = JSON->new->utf8->canonical->pretty;
  $c->res->header('Content-Type',                'application/json');
  $c->res->header('Access-Control-Allow-Origin', '*');
  $c->res->body($json->encode($c->stash->{data}));
  return 1;

}

__PACKAGE__->meta->make_immutable;

1;
