package CAP::Controller::Foo;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Foo - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Private {
    my ( $self, $c ) = @_;

    # $c->response->body('Matched CAP::Controller::Foo in Foo.');
    $c->stash(template => 'foo.tt');
}


=head1 AUTHOR

Milan Budimirovic,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

