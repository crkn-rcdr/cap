package CAP::Controller::Cron::TaxReceipt;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub auto :Private {
    my($self, $c) = @_;

    # Only allow from local IP.  Do nothing for now.
    if (0) {
        $c->response->redirect('/index');
        return 0;
    }

    # Proceed with normal processing.
    return 1;
}

# Detach to this method to generate Tax receipts
#sub taxreceipt : Private {
# temporary for initial test, just use /payment/paypal/pay
sub index :Path('') {
    my($self, $c) = @_;


    $c->stash->{template} = "index.tt";

    my $html = "test";
    $c->stash->{content} = $html;

    return 0;
}

__PACKAGE__->meta->make_immutable;
