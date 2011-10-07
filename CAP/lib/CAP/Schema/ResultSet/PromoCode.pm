package CAP::Schema::ResultSet::PromoCode;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub get_promo_codes
{
    ## returns an arrayref of valid codes
    my $self = shift();
    my $codes = $self->search({ 'expires' => 
                                             { '>=' => 'now()' } });
    return $codes;
}

sub validate_code
{
    # checks to see if promo code is valid
    my($self, $promocode) = @_;
    
    my $good =  $self->search(
                              { 'expires' => 
                                             { '>=' => 'now()' }},
                              {  'id' => 
                                             { '=' => $promocode }              
                             );
    
    return 0 unless $good;
    return 1;
}

1;

