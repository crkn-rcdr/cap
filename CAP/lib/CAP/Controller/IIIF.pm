package CAP::Controller::IIIF;

use Moose;
use namespace::autoclean;
use JSON;

BEGIN { extends 'Catalyst::Controller'; }

sub index : PathPart('iiif') Chained('/') CaptureArgs(1) {
  my ($self, $c, $slug) = @_;

  $c->detach('/error', [ 404, "Slug not provided" ]) unless $slug;

  my $doc;
  eval {
    $doc = $c->model('Presentation')
      ->fetch($slug, $c->portal_id, $c->req->uri->host);
  };
  $c->detach('/error',
    [ 404, "Presentation fetch failed on document $slug: $@" ])
    if $@;

  if ($doc->item_mode ne "noid") {
    $c->detach("/error", [ 404, "IIIF service unavailable." ]);
  }

  $c->stash(doc => $doc);
}

sub manifest : Chained('index') Args(0) {
  my ($self, $c) = @_;
  my $manifest = $c->stash->{doc}->iiif_manifest();
  $c->stash(data => $manifest);
  return 1;
}

sub canvas : Chained('index') Args(1) {
  my ($self, $c, $canvas_name) = @_;
  my $canvas = $c->stash->{doc}->iiif_canvas(substr($canvas_name, 1), 1);
  $c->stash(data => $canvas);
  return 1;
}

sub annotation_page : PathPart('page') Chained('index') Args(2) {
  my ($self, $c, $canvas_name, $page_name) = @_;
  my $annotation_page =
    $c->stash->{doc}->iiif_annotation_page(substr($canvas_name, 1), 1);
  $c->stash(data => $annotation_page);
  return 1;
}

sub annotation : Chained('index') Args(2) {
  my ($self, $c, $canvas_name, $annotation_name) = @_;
  my $annotation =
    $c->stash->{doc}->iiif_annotation(substr($canvas_name, 1), 1);
  $c->stash(data => $annotation);
  return 1;
}

sub end : Private {
  my ($self, $c) = @_;
  my $json = JSON->new->utf8->canonical->pretty;
  $c->res->header('Content-Type', 'application/json');
  $c->res->header('Access-Control-Allow-Origin', '*');
  $c->res->body($json->encode($c->stash->{data}));
  return 1;
}

__PACKAGE__->meta->make_immutable;

1;
