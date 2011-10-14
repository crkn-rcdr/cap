package CAP::Controller::Payment::PayPal;
use Moose;
use namespace::autoclean;
use Business::PayPal::API::ExpressCheckout;

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


# Common function that will output debug information related to the
# PayPal API calls
sub debugPPAPI {
  my($c, $func, %apiret) = @_;

  for my $key ( keys %apiret ) {
    if ($key eq "Errors") {
	for my $errorno ( 0 .. $#{ $apiret{$key} }) {
	    for my $errorkey ( keys %{ $apiret{$key}[$errorno] } ) {
		$c->log->debug("Payment/Paypal/$func Error: $errorkey\[$errorno\] => $apiret{$key}[$errorno]{$errorkey}");
	    }
	}
    } else {
	my $value = $apiret{$key};
	$c->log->debug("Payment/Paypal/$func: $key => $value");
    }
  }
}



# Detach to this method to initiate a PayPal payment transaction
#sub pay :Private {
# temporary for initial test, just use /payment/paypal/pay
sub pay :Path('pay') {
    my($self, $c) = @_;

# Set this for debugging the Paypal transaction
# $Business::PayPal::API::Debug = 1;

    # Grab settings from cap_local.conf
    my $username = $c->config->{payment}->{paypal}->{username};
    my $password = $c->config->{payment}->{paypal}->{password};
    my $signature = $c->config->{payment}->{paypal}->{signature};
    my $sandbox = $c->config->{payment}->{paypal}->{sandbox};

    $c->log->debug("Payment/Paypal/Pay: username:$username , password:$password , signature:$signature , sandbox:$sandbox") if ($c->config->{debug});

    my $pp = new Business::PayPal::API::ExpressCheckout(
      Username   => $username,
      Password   => $password,
      Signature  => $signature,
      sandbox    => $sandbox);

    my $ReturnURL = $c->uri_for('/payment/paypal/finalize');
    my $CancelURL = $c->uri_for('/');

    # TODO:  How much and the description will be passed via stash from
    # elsewhere
    my $orderTotal = 123.45;
    my $orderDescription = "More money for tokens valued at \$$orderTotal";

    my %PPresp = $pp->SetExpressCheckout(
      OrderTotal => $orderTotal,
      currencyID => 'CAD',
      LocaleCode => 'CA',
      OrderDescription => $orderDescription,
      ReturnURL  => "<![CDATA[$ReturnURL]]>" ,
      CancelURL  => "<![CDATA[$CancelURL]]>" );

    debugPPAPI($c, "Pay", %PPresp ) if $c->config->{debug};

    # TODO: Check if "Ack => Success", and that we have a token.
    # We need to decide what we want to do if Paypal is down/etc. Message?
    my $sandboxURL = $sandbox ? ".sandbox" : "";
    my $paypalURL="https://www" . $sandboxURL . ".paypal.com/webscr?cmd=_express-checkout&token=" .$PPresp{Token};

    $c->log->debug("Payment/Paypal/Pay: ReturnURL => $ReturnURL , CancelURL => $CancelURL , paypalURL => $paypalURL") if ($c->config->{debug});

    $c->response->redirect($paypalURL);
    return 0;
}

# PayPal calls this URL when the transaction is complete
sub finalize :Path('finalize') {
    my($self, $c) = @_;
    
    # Grab settings from cap_local.conf
    my $username = $c->config->{payment}->{paypal}->{username};
    my $password = $c->config->{payment}->{paypal}->{password};
    my $signature = $c->config->{payment}->{paypal}->{signature};
    my $sandbox = $c->config->{payment}->{paypal}->{sandbox};

    $c->log->debug("Payment/Paypal/finalize: username:$username , password:$password , signature:$signature , sandbox:$sandbox") if ($c->config->{debug});

    my $pp = new Business::PayPal::API::ExpressCheckout(
      Username   => $username,
      Password   => $password,
      Signature  => $signature,
      sandbox    => $sandbox);

    my $token = $c->request->param( 'token' );
    $c->log->debug("Payment/Paypal/finalize: token = $token") if ($c->config->{debug});
    if (! $token) {
      # If this isn't a legitimate query, generate an error
      $c->detach('/error', [400, "Invalid query parameters"]);
      return 0;
    }


    my %details = $pp->GetExpressCheckoutDetails($token);

    # TODO: Check if "Ack => Success"

    #$c->stash->{details} = \%details;
    debugPPAPI($c, "Finalize/Get...Details", %details ) if $c->config->{debug};

    # TODO:  How much needs to be pulled out of the transaction database.
    my $orderTotal = 123.45;

    my %payinfo = $pp->DoExpressCheckoutPayment(
      Token => $details{Token},
      PaymentAction => 'Sale',
      PayerID => $details{PayerID},
      OrderTotal => $orderTotal,
      currencyID => 'CAD',
      LocaleCode => 'CA',
    );


    # TODO: Check if "Ack => Success"

    #$c->stash->{payinfo} = \%payinfo;
    debugPPAPI($c, "Finalize/Do...Payment", %payinfo ) if $c->config->{debug};

    # TODO: Not an error, but I don't know where to detach to yet.
    $c->detach('/error', [200, "Payment of $orderTotal completed."]);
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
