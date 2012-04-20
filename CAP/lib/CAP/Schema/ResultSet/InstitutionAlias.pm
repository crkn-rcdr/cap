package CAP::Schema::ResultSet::InstitutionAlias;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# Returns institution's public name given the institution and language

sub get_alias
{
    my($self, $institution_id, $language) = @_;
    my $check_alias = $self->search(
                               { 
                             
                                 institution_id => $institution_id,
                                 lang => $language

                               }
                             );

    my $result = $check_alias->next;
    my $alias = defined($result) ? $result->name : 0;  # return the amount or return zero

    return $alias;    
}

# Returns institution's id name given the public name and language
# Not sure how useful this is, but since we're already here...

sub get_id
{
    my($self, $alias, $language) = @_;


    my $check_id =  $self->search(
                                   {
                         
                                     alias => $alias,
                                     lang => $language
                                  
                                   }           
                                 );
    my $result = $check_id->next;
    my $id = defined($result) ? $result->id : 0;  # return the amount or return zero

    return $id;
}

1;

