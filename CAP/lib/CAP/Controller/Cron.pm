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

    # Generate tax receipt PDF's and email them
    $c->forward('/cron/taxreceipt/index');
    
    # Delete unconfirmed accopunts
    $c->forward('/cron/removeunconfirmed/index');
    
    # Delete unconfirmed accopunts
    $c->forward('/cron/expiringtrialreminder/index');
    	
    return 1;
}

# Return an empty document
sub end : ActionClass('RenderView') {
    my($self, $c) = @_;
    $c->res->status(200);
    $c->res->body(".");
}

__PACKAGE__->meta->make_immutable;

1;
