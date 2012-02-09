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
sub index : Private {
    my($self, $c) = @_;


    my $generateprog = $c->config->{taxreceipt}->{prog};
    my $outputdir = $c->config->{taxreceipt}->{outputdir};
    my $rcpt_format = $c->config->{taxreceipt}->{format};

    if (!$generateprog || !$outputdir || !$rcpt_format) {
	# If not configured, then don't run
	return 1;
    }

# TODO: Move more database work to model?
    my $needreceipt = $c->model('DB::Subscription')->search(
	{ success =>  1,
	  payment_id  =>  { '!=', undef },
	  rcpt_no => undef });

    while (my $subrow = $needreceipt->next) {
	my $id = $subrow->id;
	my $donor = $subrow->rcpt_name;
	my $amount_received = $subrow->payment_id->amount;
	my $amount_eligible = $subrow->rcpt_amt;
	my $amount_value = $amount_received - $amount_eligible;

	my $donation_date = $subrow->completed;
	$donation_date =~ s/T.*$//;

	my $address = $subrow->rcpt_address;

        my $findrcpt_no = $c->model('DB::Subscription')->search(
	    {},
	    { select => [ { MAX => 'rcpt_no' } ],
	      as => [ 'rcpt_no' ],
            })->next;
        my $rcpt_no = $findrcpt_no->rcpt_no;

	if (! defined($rcpt_no)) {
	    $rcpt_no = 0;
        } 
	$rcpt_no += 1;

	my $rcpt_id = sprintf($rcpt_format,$rcpt_no);
	my $outfile = "$outputdir/${rcpt_id}.pdf";

        eval { $subrow->update({
	    rcpt_date => \'now()', #' Makes Emacs Happy
	    rcpt_no => $rcpt_no,
	    rcpt_id => $rcpt_id
           })->discard_changes;     
	};

        # If update fails because rcpt_id not unique -- 
        # go to next entry and try again next time
        if ($@) {
	    next;
	}

	my $rcpt_date = $subrow->rcpt_date;
	$rcpt_date =~ s/T.*$//;

        # $donor and $address are strings and may have backticks, but
        # everything else should not!  These two strings are also the only
        # ones that may need to be truncated if they are too long.
	system($generateprog, esc_chars($donor), $amount_received,
	       $amount_value, $amount_eligible, $rcpt_date, $donation_date,  
	       $rcpt_id, esc_chars($address),$outfile);

	if ( $? == -1 || ($? >> 8) || ! -e $outfile) {
	    my $error = "Subscription $id: Tax receipt generate failed: $!";

	    if ($? >> 8) {
		$error .= " : Return: " . ($? >> 8);
	    }
	    $c->log->error("$error\n");

	    $c->model('DB::CronLog')->create({
		action  => 'taxreceipt',
		ok      => 0,
		message => $error,
		});

	} else {
	    $c->model('DB::CronLog')->create({
		action  => 'taxreceipt',
		ok      => 1,
		message => "Subscription $id: PDF file created: $outfile",
		});

            # Send subscriber an email with PDF attachment
	    my $email = $subrow->user_id->username;
	    my $name  = $subrow->user_id->name;
	    $c->forward("/mail/subscription_taxreceipt", [$email, $name, $outfile]);
	}
    }
    return 1;
}


__PACKAGE__->meta->make_immutable;
