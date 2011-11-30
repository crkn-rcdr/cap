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
    
    my $create = $self->create({
        completed =>   0,
        user_id   =>   $userid,
        promo     =>   $promo,
        amount    =>   $amount,
        rcpt_name =>   $trname,
        rcpt_amt  =>   $rcpt_amt,
	processor =>   $processor
    });

    # Should this return a boolean based on whether the create worked?
    return $create;
}


sub get_row
{
    # returns an arrayref of all the values in the row for a given user_id
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

sub subscription_status {
    # returns a string indicating the current status of the user's subscription
    my($self,$user_id) = @_;
         
    my $check_user_id =  $self->search(
                                {
                                
                                    user_id => $user_id
                                  
                                }           
                             );
    my $getrow = $check_user_id->next();
    my $row = defined($getrow) ? $getrow : 0;
    return 'unsubscribed' unless $row;

    return $row;
	
}

sub confirm_subscription
{
    # updates "completed" flag and expiry date
    my($self,$user_id,$expiry) = @_;
    
    my $resultset = $self->user_id_resultset($user_id);
           
    my $update =  $resultset->update(
                                {

                                
                                    completed => 1,
                                    newxpire => $expiry
                                  
                                }                                       
                             );


    return $update;

}



sub add_receipt
{
    # updates receipt information
    my($self,$user_id,$rcpt_amt,$rcpt_name,$rcpt_no) = @_;

    my $resultset = $self->user_id_resultset($user_id);

    my $update =  $resultset->update(
                                {
                                   
                                    recpt_amt   => $rcpt_amt,
                                    recpt_name  => $rcpt_name,
                                    recpt_no    => $rcpt_no
                                  
                                }     
                             );    
    return $update;

}

sub existing_request_in_progress
{
    # checks to see if user already has a pending subscription request in progress
    # get_incomplete_row() already does this
    
    return 1;

}


1;

sub user_id_resultset
{
    
    # does a search and returns a resultset for a given user_id
    my($self, $user_id) = @_;
           
    my $check_user_id =  $self->search(
                                {

                                
                                    user_id => $user_id
                                  
                                }         
                             );

    return $check_user_id;
    
}