package CAP::Schema::ResultSet::Promocode;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use POSIX qw(strftime);


sub get_promocode
{
    ## returns an arrayref of valid codes
    my ($self) = @_;

    my $now = strftime("%Y-%m-%d %H:%M:%S",localtime());    

    my $check_promo = $self->search( 
                              { 'expires' => 
                                             { '>=' => $now }
                              }
                             );

    my $result = $check_promo->next;
    my $code = defined($result) ? $result->id : ''; # return an empty string if there is no active promo code                                

    return $code;
}


sub code_exists
{
    # returns the first active promo code
    my($self, $promocode) = @_;
           
    my $check_promo =  $self->search(
                                {

                                
                                    id => $promocode
                                  
                                }           
                             );

    my $validity = defined($check_promo->next) ? 1 : 0;

    return $validity;
}



sub expired_promocode
{
    # checks to see if promo code has expired
    my($self, $promocode) = @_;
    
    my $now = strftime("%Y-%m-%d %H:%M:%S",localtime());

    my $check_promo =  $self->search(
                                {

                                    expires => 
                                             { '>=' => $now },
                                 
                                    id => $promocode
                                  
                                }           
                             );

    my $expiry = defined($check_promo->next) ? 0 : 1; # return false if the query returns a row

    return $expiry;
}

sub promo_amount
{
    # returns promo code amount
    my($self, $promocode) = @_;
            
    my $check_promo =  $self->search(
                                {
                         
                                    id => $promocode
                                  
                                }           
                             );
    my $result = $check_promo->next;
    my $amount = defined($result) ? $result->amount : 0;  # return the amount or return zero

    return $amount;
}


1;

