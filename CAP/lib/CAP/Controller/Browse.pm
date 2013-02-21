package CAP::Controller::Browse;
use Moose;
use namespace::autoclean;
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

sub index :Path :Args(0) {
    my($self, $c) = @_;

    $c->stash(
        browse => $c->model('DB::Terms')->top_level_terms($c->portal),
    );
    return 1;
}

sub browse :Path :Args(1) {
    my($self, $c, $id) = @_;
    $c->stash(
        browse => $c->model('DB::Terms')->narrower_terms($c->portal, $id),
        browse_path => $c->model('DB::Terms')->path($id),
    );

    # If there are no narrower terms, redirect to a search for the current
    # term.
    if (@{$c->stash->{'browse'}} == 0) {
        $c->res->redirect($c->uri_for_action('/search/index', { 'term' => $id }));
        $c->detach();
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
