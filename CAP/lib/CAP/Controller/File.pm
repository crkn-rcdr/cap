package CAP::Controller::File;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use CAP::Ingest;

=head1 NAME

CAP::Controller::File - Catalyst Controller

=cut

sub get_page_uri :Local :Args(2) {
    my($self, $c, $key, $seq) = @_;

    $c->detach('/error', [404, "Can only be called through fmt=ajax"]) unless $c->stash->{current_view} eq 'Ajax';

    my $doc = $c->model("Solr")->document($key);
    $c->detach('/error', [404, "No document with key $key"]) unless $doc;
    $doc->set_auth($c->stash->{access_model}, $c->user);
    $c->detach('/error', [404, "No page $seq for $key"]) unless $doc->child($seq);

    my $size = $c->req->params->{s} || "1";
    my $rotate = $c->req->params->{r} || "0";

    my $req = $doc->derivative_request($c->config->{content}, $c->config->{derivative}, $seq, "file.jpg", $size, $rotate, "jpg");
    $c->stash(status => $req->[0], uri => $req->[1]);
    return 1;
}

1;
