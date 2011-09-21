package CAP::Controller::Payment::PayPal;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub auto :Private {
    my($self, $c) = @_;

    # If payment processing is not enabled for this portal, do not perform
    # any actions in this controller.
    if (! $c->stash->{payment_processing}) {
        $c->response->redirect('/index');
        return 0;
    }

    # Proceed with normal processing.
    return 1;
}

# Detach to this method to initiate a PayPal payment transaction
sub pay :Private {
    my($self, $c) = @_;
}

# PayPal calls this URL when the transaction is complete
sub finalize :Path('finalize') {
    my($self, $c) = @_;
    
    # If this isn't a legitimate query, generate an error
    $c->detach('/error', [400, "Invalid query parameters"]);
    return 0;
}

# PayPal calls this URL when the transact
sub ipn :Path('ipn') {
    my($self, $c) = @_;

    # If this isn't a legitimate query, generate an error
    $c->detach('/error', [400, "Invalid query parameters"]);
    return 0;
}

__PACKAGE__->meta->make_immutable;

