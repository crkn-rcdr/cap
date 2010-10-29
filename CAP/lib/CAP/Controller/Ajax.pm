package CAP::Controller::Ajax;
use Moose;
use namespace::autoclean;
use JSON;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Ajax - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub _start :Chained('/base') PathPart('ajax') CaptureArgs(0)
{
    my($self, $c) = @_;
    if ($c->req->params->{fmt}) {
        my $fmt = $c->req->params->{fmt};
        if ($fmt eq 'json') {
            $c->stash->{fmt} = 'json';
        }
        else {
            $c->stash->{fmt} = 'html';
        }
    }
    else {
        $c->stash->{fmt} = 'html';
    }
    return 1;
}

sub hello :Chained('_start') PathPart('hello') Args(0)
{
    my($self, $c) = @_;
    $c->stash->{response} = {
        text => 'Hello, World!'
    };
    $c->stash->{template} = 'ajax/hello.tt';
    $c->forward('_end');
}

sub _end :Private
{
    my($self, $c, $fmt) = @_;
    if ($c->stash->{fmt} eq 'json') {
        $c->res->content_type('application/json');
        $c->res->status(200);
        $c->res->body(encode_json($c->stash->{response}));
        return 1;
    }
    else {
        $c->stash->{current_view} = 'Ajax';
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;

