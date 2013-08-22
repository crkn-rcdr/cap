package CAP::Schema::ResultSet::Subscription;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use base 'DBIx::Class::Row';
use POSIX qw(strftime);


=head2 metrics ($resultset)

Returns a hashref of metrics for $resultset.

=cut
sub metrics {
    my($self, $resultset) = @_;
    my $metrics = {
        payment => 0,
        new => 0,
        renewals => 0
    };

    foreach my $row ($resultset->all) {
        if ($row->payment_id) {
            $metrics->{revenue} += $row->payment_id->amount;
            $metrics->{avg_revenue} += $row->payment_id->amount;
        }
        $metrics->{discount}++ if ($row->discount_code);
        if ($row->old_expire) {
            $metrics->{renewal}++;
        }
        else {
            $metrics->{new}++;
        }
    }

    $metrics->{avg_revenue} /= $resultset->count if ($resultset->count);

    return $metrics;
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

# Get a payment history for user $id.
sub payment_history {
    my($self, $id) = @_;
    my $history = []; 
    return [] unless $self->find({ id => $id });
    foreach my $record ($self->search({ user_id => $id, success => 1}, {order_by => { -desc => 'completed' }})->all) {
        push(@{$history}, {
            completed => $record->completed,
            amount    => $record->payment_id->amount,
            newexpire => $record->newexpire,
        });
    }
    return $history;
}
