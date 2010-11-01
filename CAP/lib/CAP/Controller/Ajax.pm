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
    $c->stash->{template} = 'ajax/hello.tt';
}

__PACKAGE__->meta->make_immutable;

