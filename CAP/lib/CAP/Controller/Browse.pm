package CAP::Controller::Browse;
use Moose;
use namespace::autoclean;
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

__PACKAGE__->config(
    action_roles => [ 'NoSSL' ]
);

sub index :Path :Args(0) {
    my($self, $c) = @_;

    $c->stash(
        browse => $c->model('DB::Thesaurus')->top_level_terms($c->portal),
    );
    return 1;
}

sub browse :Path :Args(1) {
    my($self, $c, $id) = @_;
    $c->stash(
        browse => $c->model('DB::Thesaurus')->narrower_terms($c->portal, $id),
        browse_path => $c->model('DB::Thesaurus')->path($id),
    );
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
