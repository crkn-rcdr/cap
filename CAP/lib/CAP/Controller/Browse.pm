package CAP::Controller::Browse;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub auto :Private {
    my ($self, $c) = @_;

    unless ($c->portal_id eq 'parl') {
        $c->detach('/error', [404, "Browsing from a non-parl portal"]);
    }
}

sub index :Path :Args(0) {
    my($self, $c) = @_;

    $c->stash(tree => $c->model('Parl')->tree());

    return 1;
}

sub leaf :Path :Args(4) {
    my ($self, $c, $language, $chamber, $type, $session) = @_;

    my $leaf = $c->model('Parl')->leaf($language, $chamber, $type, $session);
    $c->stash(
        leaf => $leaf->{leaf}, 
        title => $leaf->{title},
        chamber => $chamber,
        parl_session => $c->model('ParlSession')->session($session)
    );

    return 1;
}
__PACKAGE__->meta->make_immutable;

1;
