package CAP::Controller::Browse;
use Moose;
use namespace::autoclean;
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

sub index :Path :Args(0) {
    my($self, $c) = @_;

    delete $c->session->{$c->portal->id}->{search};

    $c->stash(
        browse => $c->model('DB::Terms')->top_level_terms($c->portal),
    );
    return 1;
}

sub browse :Path :Args(1) {
    my($self, $c, $id) = @_;

    my $terms = $c->model('DB::Terms')->narrower_terms($c->portal, $id);
    my $title_urls = {};
    foreach my $term (@{$terms}) {
        if ($term->get_column('count') == 1 && !$c->model('DB::Terms')->term_has_children($term->id)) {
            # FIXME: Hey you've hardcoded the contributor code here!!
            $title_urls->{$term->id} = $c->uri_for_action('view/key', "oop." . $term->titles->first()->identifier)->as_string;
        }
    }
    $c->stash(
        browse => $terms,
        title_urls => $title_urls,
        browse_path => $c->model('DB::Terms')->path($id),
    );

    delete $c->session->{$c->portal->id}->{search};
    
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
