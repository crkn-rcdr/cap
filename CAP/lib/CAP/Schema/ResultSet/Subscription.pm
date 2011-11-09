package CAP::Schema::ResultSet::Subscription;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use base 'DBIx::Class::Row';
use POSIX qw(strftime);


sub new_subscription
{
    ## inserts new row into subscriprion table
    my ($self, $c, $promo, $amount, $trname, $rcpt_amt,
        $period, $processor) = @_;

    my $userid =  $c->user->id;
    
    ## Date manipulation to set the old and new expiry dates

    use Date::Manip::Date;
    use Date::Manip::Delta;

    my $subexpires = $c->user->subexpires;
    $period = 300 unless ($period);

    my $dateexp = new Date::Manip::Date;
    my $err = $dateexp->parse($subexpires);

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
	return 0;
    }
    my $datenew = $dateexp->calc($deltaexpire);
    my $newexpire = $datenew->printf("%Y-%m-%d");
    ## END date manipulation


    my $row = $self->create({
        user_id   =>   $userid,
        promo     =>   $promo,
        amount    =>   $amount,
        rcpt_name =>   $trname,
        rcpt_amt  =>   $rcpt_amt,
	processor =>   $processor,
	oldexpire =>   $subexpires,
	newexpire =>   $newexpire
    });

    # Should this return a boolean based on whether the create worked?
    return 1;
}


sub get_row
{
    # returns an arrayref of all the
    my($self, $user_id) = @_;
           
    my $check_user_id =  $self->search(
                                {

                                
                                    user_id => $user_id
                                  
                                }           
                             );
    my $getrow = $check_user_id->next();
    my $row = defined($getrow) ? $getrow : 0;

    return $row;
}

# Sometimes need to grab only (and there should only ever be 1)
# row for a given user that is pending.
sub get_incomplete_row
{
    # returns an arrayref of all the
    my($self, $user_id) = @_;
           
    my $check_user_id =  $self->search(
                                {
				    completed => undef,
                                    user_id => $user_id
                                  
                                }           
                             );
    my $getrow = $check_user_id->next();
    my $row = defined($getrow) ? $getrow : 0;

    return $row;
}

sub confirm_subscription
{
    # toggles "completed" flag and inserts expiry date


    return 1;
}



sub add_receipt
{
    # updates receipt information
    
    return 1;

}



1;

