package CAP::Controller::Download;
use Moose;
use namespace::autoclean;

use strict;
use warnings;
use utf8;

use File::Temp;

BEGIN { extends 'Catalyst::Controller'; }

sub index : Path('/download') Args() {
  my ( $self, $c, @args ) = @_;

  my ( $key, $seq ) = @args;
  $c->detach( '/error', [404, 'Document key not provided'] )
    unless $key;
  $c->detach( '/error', [404, 'Download not found'] )
    if @args > 2;
  $c->detach( '/error', [404, "Page not found: $seq"] )
    if defined $seq && $seq !~ /^\d+$/;

  my $doc;
  eval {
    $doc = $c->model('Presentation')
      ->fetch( $key, $c->portal_id, $c->req->uri->host );
  };
  $c->detach( '/error',
    [404, "Presentation fetch failed on document $key: $@"] )
    if $@;

  my $download;
  if ( defined $seq ) {
    $c->detach( '/error', [404, "Page not found: $seq"] )
      unless $doc->has_child($seq);
    $download = $doc->component_download_info($seq);
  } else {
    $download = $doc->item_download_info;
  }

  $c->detach( '/error', [404, 'Download not found'] )
    unless $download;

  my $fh = File::Temp->new( UNLINK => 1 );
  binmode($fh);

  my $response = eval {
    $c->model('Presentation')->swift_client->object_get(
      $download->{repository},
      $download->{object},
      { write_file => $fh }
    );
  };

  if ( $@ || !$response || $response->code != 200 ) {
    my $message = $@
      ? $@
      : $response
        ? $response->code . ' - ' . $response->message
        : 'No response from Swift';
    $c->log->error("Swift download failed for $key: $message");
    my $status = $response && $response->code == 404 ? 404 : 502;
    $c->detach( '/error', [$status, 'Download temporarily unavailable'] );
  }

  seek( $fh, 0, 0 );

  $c->response->content_type(
    $response->content_type || 'application/octet-stream' );
  $c->response->headers->content_length( $response->content_length )
    if defined $response->content_length;
  $c->response->headers->header(
    'Content-Disposition' => _content_disposition( $download->{filename} ) );
  $c->response->body($fh);
}

sub _content_disposition {
  my ($filename) = @_;
  $filename ||= 'download';
  $filename =~ s/["\\\r\n]/_/g;
  return qq{attachment; filename="$filename"};
}

__PACKAGE__->meta->make_immutable;

1;
