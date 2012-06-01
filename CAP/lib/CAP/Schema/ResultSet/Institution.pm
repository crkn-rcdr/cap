package CAP::Schema::ResultSet::Institution;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# Returns institution's public name given the institution id

sub get_name
{
    my($self, $institution_id) = @_;
    my $check_name = $self->search(
                               { 
                             
                                 id => $institution_id,

                               }
                             );

    my $result = $check_name->next;
    my $name = defined($result) ? $result->name : 0;  # return the amount or return zero

    return $name;    
}

# Returns institution's id name given the public name
# Not sure how useful this is, but since we're already here...

sub get_id
{
    my($self, $name) = @_;


    my $check_id =  $self->search(
                                   {
                         
                                     name => $name
                                  
                                   }           
                                 );
    my $result = $check_id->next;
    my $id = defined($result) ? $result->id : 0;  # return the amount or return zero

    return $id;
}

1;

