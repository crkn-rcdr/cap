package CAP::Schema::ResultSet::Subscription;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use base 'DBIx::Class::Row';
use POSIX qw(strftime);


sub new_subscription
{
    ## inserts new row into subscriprion table
    my ($self, $c, $promo, $amount, $trname, $rcpt_amt, $processor) = @_;

    my $userid =  $c->user->id;
    
    my $row = $self->create({
        user_id   =>   $userid,
        promo     =>   $promo,
        amount    =>   $amount,
        rcpt_name =>   $trname,
        rcpt_amt  =>   $rcpt_amt,
	processor =>   $processor
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

