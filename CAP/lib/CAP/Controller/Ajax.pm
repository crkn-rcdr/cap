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

sub auto :Private
{
    my($self, $c) = @_;
    $c->stash->{current_view} = 'Ajax';
    return 1;
}

sub hello :Path('hello') :Args(0)
{
    my($self, $c) = @_;
    $c->stash->{response} = {
        text => 'Hello, World!'
    };
    $c->stash->{template} = 'hello.tt';
}

sub facet :Path('facet') :Args(0)
{
    my($self, $c) = @_;
    $c->forward('/search/main', [1, { rows => 0 }]);
    $c->stash->{response} = $c->stash->{response}->{facet};
    $c->stash->{template} = 'facet.tt';
    return 1;
}

__PACKAGE__->meta->make_immutable;

