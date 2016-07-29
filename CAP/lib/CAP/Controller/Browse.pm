package CAP::Controller::Browse;
use Moose;
use namespace::autoclean;
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

sub index :Path :Args(0) {
    my($self, $c) = @_;

    if ($c->portal->id eq 'parl') {
        delete $c->session->{$c->portal->id}->{search};
    } else {
        $c->detach('/error', [404, "Browsing from a non-parl portal"]);
    }

    return 1;
}
__PACKAGE__->meta->make_immutable;

1;
