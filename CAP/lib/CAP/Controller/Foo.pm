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

#sub index :Private {
sub index :Path("") :Args() {
    my ( $self, $c, $page ) = @_;

    my $options = { };
    $page = 1 unless ($page);

    my $query = $c->req->params->{q} . ' AND (type:series OR type:document)';
    my $resultset = $c->model('Solr')->search($c->stash->{search_subset})->query($query, options => $options, page => $page );
    #$c->model('Solr')->search($c->stash->{search_subset})->subsearch($query, $resultset);

    $c->stash->{response}->{result} = $resultset->api('result');
    $c->stash->{response}->{facet} = $resultset->api('facets');
    $c->stash->{response}->{set} = $resultset->api('docs');

    $c->stash(
        resultset => $resultset,
        template => 'foo.tt',
    );
    return 1;
}


=head1 AUTHOR

Milan Budimirovic,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

