package CAP::Schema::ResultSet::InstitutionMgmt;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';


sub is_inst_manager
{
    # returns the first active promo code
    my($self, $userid, $inst) = @_;
           
    my $mgr_check =  $self->search(
                                {

                                
                                    user_id         =>  $userid,
                                    institution_id  =>  $inst
                                  
                                }           
                             );

    my $is_mgr = defined($mgr_check->next) ? 1 : 0;

    return $is_mgr;
}






1;

