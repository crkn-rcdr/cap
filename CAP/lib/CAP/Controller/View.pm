package CAP::Controller::View;
use Moose;
use namespace::autoclean;
use JSON qw/encode_json/;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::View - Catalyst Controller

=cut

sub index : Path('') {
  my ( $self, $c, $key, $seq ) = @_;

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

    $c->stash(
      item               => $item,
      record             => $item->record,
      item_download      => $item->item_download,
      item_download_size => $item->item_download_size,
      seq                => $seq,
      template           => "view_item.tt"
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
