package CAP::Controller::Cron;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ($self, $c) = @_;

    # Cron must be called from localhost.
# Temporarily disable
#    if ($c->req->address ne '127.0.0.1') {
#        $c->detach('/error', [403, "Request from unauthorized address"]);
#    }

    # Call various cron events
    $c->forward('/cron/session/index');

    # Return an empty document
    $c->res->status(200);
    $c->res->body(".");
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
