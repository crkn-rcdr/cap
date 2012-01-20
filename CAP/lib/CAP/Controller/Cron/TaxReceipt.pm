package CAP::Controller::Cron::TaxReceipt;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }


sub esc_chars {
    my ($string, ) = @_;
    # Seems only backticks are problem with our generate.sh script
    $string =~ s/(['])/\\$1/g;
    return $string;
}


# Detach to this method to generate Tax receipts
#sub taxreceipt : Private {
# temporary for initial test, just use /cron/taxreceipt
sub index :Path('') {
    my($self, $c) = @_;


    #TODO: get from config, only set defaults here
    my $generateprog = "/home/russell/cap/cap-conf/tax-rcpt/generate.sh";
    my $outputdir = "/tmp/receipts/";
    my $rcpt_format = "011EC%06d";

    my $needreceipt = $c->model('DB::Subscription')->search(
	{ completed =>  { '!=', undef },
	  payment_id  =>  { '!=', undef },
	  rcpt_no => undef });

    while (my $subrow = $needreceipt->next) {
	my $id = $subrow->id;
	my $donor = $subrow->rcpt_name;
	my $amount_received = $subrow->payment_id->amount;
	my $amount_eligible = $subrow->rcpt_amt;
	my $amount_value = $amount_received - $amount_eligible;
	my $donation_date = $subrow->completed;
	my $address = $subrow->rcpt_address;

	$c->log->debug("Receipt::  ID: $id\nDonor: $donor\nReceived: $amount_received\nEligible: $amount_eligible\nDate: $donation_date\nAddress: $address\n");

        my $findrcpt_no = $c->model('DB::Subscription')->search(
	    {},
	    { select => [ { MAX => 'rcpt_no' } ],
	      as => [ 'rcpt_no' ],
            })->next;
        my $rcpt_no = $findrcpt_no->rcpt_no;

	if (! defined($rcpt_no)) {
	    $rcpt_no = 1;
        } 
	$rcpt_no += 1;

	my $rcpt_id = sprintf($rcpt_format,$rcpt_no);
	my $outfile = "$outputdir/${rcpt_id}.pdf";

# If this fails because rcpt_id not unique -- 
# go to next entry and try again next time
        eval { $subrow->update({
	    rcpt_date => \'now()', #' Makes Emacs Happy
	    rcpt_no => $rcpt_no,
	    rcpt_id => $rcpt_id
           })->discard_changes;     
	};
        if ($@) {
	    next;
	}
	my $rcpt_date = $subrow->rcpt_date;

# $donor and $address are strings and may have backticks, but
# everything else should not!  These two strings are also the only
# ones that may need to be truncated if they are too long.
	system($generateprog, esc_chars($donor), $amount_received,
	       $amount_value, $amount_eligible, $rcpt_date, $donation_date,  
	       $rcpt_id, esc_chars($address),$outfile);

	# TODO: What should we do if we see an error?
	if ( $? == -1 ) {
	    $c->log->debug("command failed: $!\n");
	} else {
	    $c->log->debug(sprintf("command exited with value %d\n", $? >> 8));
	}
    }

    # Return an empty document
    $c->res->status(200);
    $c->res->body("taxreceipt");
    return 1;
}


__PACKAGE__->meta->make_immutable;
