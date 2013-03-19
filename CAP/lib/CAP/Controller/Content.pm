package CAP::Controller::Content;
use Moose;
use namespace::autoclean;
use CAP::Util;


__PACKAGE__->config(
    map => {
        'text/html' => [ 'View', 'Default' ],
    },
);

BEGIN { extends 'Catalyst::Controller::REST'; }

=head1 NAME

CAP::Controller::Content - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub auto :Private {
    my($self, $c) = @_;

    # The content role is required for access
    unless ($c->has_role('content')) {
        $c->session->{login_redirect} = $c->req->uri;
        $c->response->redirect($c->uri_for('/user', 'login'));
        $c->detach();
    }

    return 1;
}


sub index :Path :Args(0) {
    my ($self, $c) = @_;
    my @institutions = ();
    my @portals = ();

    $c->stash(
        institutions => [$c->model('DB::Titles')->institutions],
        portals => [$c->model('DB::Portal')->list]
    );

    return 1;
}


__PACKAGE__->meta->make_immutable;

1;
