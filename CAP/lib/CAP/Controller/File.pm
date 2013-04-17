package CAP::Controller::File;
use Moose;
use namespace::autoclean;

use strict;
use warnings;
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

=head1 NAME

CAP::Controller::File - Catalyst Controller

=cut

sub get_page_uri :Local :Args(2) {
    my($self, $c, $key, $seq) = @_;

    my $doc = $c->model("Solr")->document($key);
    my $result;
    unless ($doc && $doc->found) {
        $result = [404, "No document with key $key"];
    } else {
        $doc->authorize($c->auth);
        my $size = $c->req->params->{s} || "1";
        my $rotate = $c->req->params->{r} || "0";
        $result = $c->cap->derivative_request($doc, $seq, "file.jpg", $size, $rotate, "jpg");
    }

    if ($c->req->params->{redirect}) {
        if ($result->[0] == 200) {
            $c->res->redirect($result->[1]);
        } else {
            $c->detach('/error', $result);
        }
    } else {
        $c->detach('/error', [404, "Can only be called through fmt=ajax"]) unless $c->stash->{current_view} eq 'Ajax';
        $c->stash(status => $result->[0], uri => $result->[1]);
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;
1;
