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
sub pay : Private {
# temporary for initial test, just use /payment/paypal/pay
#sub pay :Path('pay') {
    my($self, $c, $amount, $description, $returnto) = @_;


    # This function only needs the following
    my $orderTotal = ($amount) ? $amount : 0;
    my $orderDescription = ($description) ? $description : "";

# Set this for debugging the Paypal transaction
# $Business::PayPal::API::Debug = 1;

    # Grab settings from cap_local.conf
    my $username = $c->config->{payment}->{paypal}->{username};
    my $password = $c->config->{payment}->{paypal}->{password};
    my $signature = $c->config->{payment}->{paypal}->{signature};
    my $sandbox = $c->config->{payment}->{paypal}->{sandbox};

    $c->log->debug("Payment/Paypal/Pay: username:$username , password:$password , signature:$signature , sandbox:$sandbox") if ($c->debug);

    my $pp = new Business::PayPal::API::ExpressCheckout(
      Username   => $username,
      Password   => $password,
      Signature  => $signature,
      sandbox    => $sandbox);

    my $ReturnURL = $c->uri_for('/payment/paypal/finalize');
    my $CancelURL = $c->uri_for('/');


    my %PPresp = $pp->SetExpressCheckout(
      OrderTotal => $orderTotal,
      currencyID => 'CAD',
      LocaleCode => 'CA',
      OrderDescription => $orderDescription,
      ReturnURL  => "<![CDATA[$ReturnURL]]>" ,
      CancelURL  => "<![CDATA[$CancelURL]]>" );

    debugPPAPI($c, "Pay", %PPresp ) if $c->debug;

    if ($PPresp{Ack} eq "Success") {

	my $sandboxURL = $sandbox ? ".sandbox" : "";
	my $paypalURL="https://www" . $sandboxURL . ".paypal.com/webscr?cmd=_express-checkout&token=" .$PPresp{Token};

	$c->log->debug("Payment/Paypal/Pay: ReturnURL => $ReturnURL , CancelURL => $CancelURL , paypalURL => $paypalURL") if ($c->debug);

	# Set session variables needed by finalize
	$c->flash->{"PayPal"} = [$returnto,$amount];
	$c->response->redirect($paypalURL);
    } else {
	use JSON;
	## Encode all results from PayPal into single JSON message
	my $message = encode_json [["PPresp","",%PPresp]];

	## Detach to location set when we were called to indicate failure
	$c->detach($returnto, [0, $message, undef, "paypal"]);
    }
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

    $c->log->debug("Payment/Paypal/finalize: username:$username , password:$password , signature:$signature , sandbox:$sandbox") if ($c->debug);

    my $flashvars = $c->flash->{"PayPal"};
    my ($returnto, $amount);

    if ($flashvars) {
	$returnto = @$flashvars[0];
	$amount = @$flashvars[1];
	$c->log->debug("Payment/Paypal/finalize: returnto:$returnto , amount:$amount") if ($c->debug);
    } else {
	# If the session is missing key variables, generate an error
	# TODO: localize
	$c->detach('/error', [500, "Session variables missing"]);
	return 0;
    }

    my $token = $c->request->param( 'token' );
    $c->log->debug("Payment/Paypal/finalize: token = $token") if ($c->debug);
    if (! $token) {
      # If this isn't a legitimate query, generate an error
      $c->detach('/error', [400, "Invalid query parameters"]);
      return 0;
    }

    my $pp = new Business::PayPal::API::ExpressCheckout(
      Username   => $username,
      Password   => $password,
      Signature  => $signature,
      sandbox    => $sandbox);

    my %details = $pp->GetExpressCheckoutDetails($token);

    debugPPAPI($c, "Finalize/Get...Details", %details ) if ($c->debug);

    my %payinfo = $pp->DoExpressCheckoutPayment(
	Token => $details{Token},
	PaymentAction => 'Sale',
	PayerID => $details{PayerID},
	OrderTotal => $amount,
	currencyID => 'CAD',
	LocaleCode => 'CA',
	);

debugPPAPI($c, "Finalize/Do...Payment", %payinfo ) if ($c->debug);

    # Verify both interactions with PayPal indicated success.
    my $success = (($payinfo{Ack} eq "Success") 
		   && ($details{Ack} eq "Success"));
$c->log->debug("Payment/Paypal/finalize: Success? : $success") if ($c->debug);

    use JSON;
    ## Encode all results from PayPal into single JSON message
    my $message = encode_json [["Details","",%details],["PayInfo","",%payinfo]];

    # Detach to variable set when Paypal::Pay first called
    $c->detach($returnto, [$success, $message,$amount,"paypal"]);
    return 0;
}

# This is something we can do in the future if we feel the need to log
# IPN's.  Duplicates information we receive as part of express-checkout
sub ipn :Path('ipn') {
    my($self, $c) = @_;

    # If this isn't a legitimate query, generate an error
    $c->detach('/error', [400, "Invalid query parameters"]);
    return 0;
}

__PACKAGE__->meta->make_immutable;
