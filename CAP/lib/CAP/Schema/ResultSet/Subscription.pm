package CAP::Schema::ResultSet::Subscription;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use POSIX qw(strftime);


sub new_subscription
{
    ## inserts new row into subscriprion table
    my ($self, $user_id, $promo, $amount, $period) = @_;
    
    $self->create({
        user_id   =>   $user_id,
        promo     =>   $promo,
        amount    =>   $amount,
        period    =>   $period
    });                       

    return 1;
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

