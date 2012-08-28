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


sub list_inst_for_user
{
    # returns the first active promo code
    my($self, $userid) = @_;
           
    my $mgr_check =  $self->search(
                                {
                                
                                    user_id         =>  $userid,
                                  
                                }           
                             );

    my $institutions = [];
    my $nextrow;
    
    while ($nextrow = $mgr_check->next) {
    
       push (@$institutions,$nextrow->institution_id->{_column_data})
        
    }

    return $institutions;
}





1;

