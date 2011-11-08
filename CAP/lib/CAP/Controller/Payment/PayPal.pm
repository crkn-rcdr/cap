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
    my($self, $c, $amount, $description, $period) = @_;


    # This function only needs the following
    my $orderTotal = ($amount) ? $amount : 0;
    my $orderDescription = ($description) ? $description : "";


### BEGIN functions that should be elsewhere 
    use Date::Manip::Date;
    use Date::Manip::Delta;

    my $userid =  $c->user->id;
    my $subexpires = $c->user->subexpires;

    $period = 300 unless ($period);
    $c->log->debug("Payment/Paypal/Pay parameters: amount:$orderTotal description:\"$orderDescription\" , period:$period") if ($c->debug);

# Update subscription with correct dates.

    my $dateexp = new Date::Manip::Date;
    my $err = $dateexp->parse($subexpires);

my $dateexpt = $err ? "error" : $dateexp->value();
$c->log->debug("Payment/Paypal/Pay Parse: $err $dateexpt") if ($c->debug);

    my $datetoday = new Date::Manip::Date;
    $datetoday->parse("today");

    # If we couldn't parse expiry date (likely null), or expired in past.
    if ($err || (($dateexp->cmp($datetoday)) <= 0)) {
        # The new expiry date is built from today
	$dateexp=$datetoday;
    }

    # Create a delta based on the period we were passed in.
    my $deltaexpire = new Date::Manip::Delta;
    $err = $deltaexpire->parse($period . " days");

    if ($err) {
      # If I was passed in a bad period, then what?
$c->log->debug("Payment/Paypal/Pay Delta Error?  \"$period days\"") if ($c->debug);
    } else {
      my $datenew = $dateexp->calc($deltaexpire);
      my $newexpire = $datenew->printf("%Y-%m-%d");
$c->log->debug("Payment/Paypal/Pay New Expiry Date: $newexpire") if ($c->debug);

      my $subscriberow = $c->model('DB::Subscription')->get_incomplete_row($c->user->id);
      if ($subscriberow) {
	  $subscriberow->update({
	      processor => "paypal",
	      oldexpire => $subexpires,
              newexpire => $newexpire
				});
      } else {
        # Ouch -- got here, but no pending subscription?
$c->log->debug("Payment/Paypal/Pay No pending subscription!") if ($c->debug);
      }
   }   

### END


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

    # TODO: Check if "Ack => Success", and that we have a token.
    # We need to decide what we want to do if Paypal is down/etc. Message?
    my $sandboxURL = $sandbox ? ".sandbox" : "";
    my $paypalURL="https://www" . $sandboxURL . ".paypal.com/webscr?cmd=_express-checkout&token=" .$PPresp{Token};

    $c->log->debug("Payment/Paypal/Pay: ReturnURL => $ReturnURL , CancelURL => $CancelURL , paypalURL => $paypalURL") if ($c->debug);

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

    $c->log->debug("Payment/Paypal/finalize: username:$username , password:$password , signature:$signature , sandbox:$sandbox") if ($c->debug);

    my $pp = new Business::PayPal::API::ExpressCheckout(
      Username   => $username,
      Password   => $password,
      Signature  => $signature,
      sandbox    => $sandbox);

    my $token = $c->request->param( 'token' );
    $c->log->debug("Payment/Paypal/finalize: token = $token") if ($c->debug);
    if (! $token) {
      # If this isn't a legitimate query, generate an error
      $c->detach('/error', [400, "Invalid query parameters"]);
      return 0;
    }


    my %details = $pp->GetExpressCheckoutDetails($token);

    debugPPAPI($c, "Finalize/Get...Details", %details ) if ($c->debug);

    # TODO:  Should all model calls be in different function?
    my $subscriberow = $c->model('DB::Subscription')->get_incomplete_row($c->user->id);
    if ($subscriberow) {
	my $orderTotal = $subscriberow->amount;

	my %payinfo = $pp->DoExpressCheckoutPayment(
	    Token => $details{Token},
	    PaymentAction => 'Sale',
	    PayerID => $details{PayerID},
	    OrderTotal => $orderTotal,
	    currencyID => 'CAD',
	    LocaleCode => 'CA',
	    );

	# Verify both interactions with PayPall indicated success.
        my $success = (($payinfo{Ack} eq "Success") 
		    && ($details{Ack} eq "Success"));

$c->log->debug("Payment/Paypal/finalize: Success? : $success") if ($c->debug);
debugPPAPI($c, "Finalize/Do...Payment", %payinfo ) if ($c->debug);

        use JSON::XS;
        my $message = encode_json [%details, %payinfo];

### BEGIN functions that should be elsewhere 
##  $success and $message would be passed into some external function

	my $userid =  $c->user->id;
	my $newexpires = $subscriberow->newexpire;
        my $rcpt_amt = $orderTotal - 50;  ## What should be here?
        my $rcpt_no = 12345; # Get next receipt from...?


        if ($success) {
	    my $user_account = $c->find_user({ id => $userid });

	    eval { $user_account->update({
		subscriber => 1,
		subexpires => $newexpires
					 }) };
	    if ($@) {
		$c->log->debug("Payment/Paypal/Pay user account:  " .$@) if ($c->debug);
		$c->detach('/error', [500,"user account"]);
	    }

	    # Update current session. User may have become subscriber.
	    $c->forward('/user/init');
        }

        # Whether successful or not, record completion and the messages
        # from PayPal
	eval { $subscriberow->update({
	    completed => \'now()', #' Makes Emacs Happy
            success => $success,
            message => $message,
      				     }) };  
        if ($@) {
	    $c->log->debug("Payment/Paypal/Pay subscriber update:  " .$@) if ($c->debug);
	    $c->detach('/error', [500,"subscriber update"]);
	}

##END

        # TODO: $success boolean may suggest different place to detach...
        if ($success) {
	    $c->message(Message::Stack::Message->new(
			    level => "success",
			    msgid => "payment_complete",
			params => [$orderTotal]));
        } else {
	    $c->message({ type => "error", message => "payment_failed" });
        }
	$c->response->redirect('/user/profile');
    } else {
        # Ouch -- got here, but no pending subscription?
	$c->log->debug("Payment/Paypal/Pay No pending subscription!") if ($c->debug);
	$c->detach('/error', [200, "No pending subscription. Payment not finalized!"]);
    }
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
