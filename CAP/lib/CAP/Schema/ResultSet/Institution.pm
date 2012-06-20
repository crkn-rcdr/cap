package CAP::Schema::ResultSet::Institution;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# builds a labels-like hash of contributor labels from institutions with contributor codes
sub get_contributors {
    my ($self, $lang) = @_;

    # get the contributors and aliases
    my @contributors = $self->search(
        {
            code => { '!=' => undef }
        },
        {
            join => 'institution_alias',
            '+select' => ['institution_alias.name', 'institution_alias.lang'],
            '+as' => ['alias', 'alias_lang']
        }
    );

    # build the hash
    my $hash = {};
    foreach my $contributor (@contributors) {
        my $alias = $contributor->get_column('alias');
        my $alias_lang = $contributor->get_column('alias_lang');
        next if $hash->{$contributor->code} && $alias_lang ne $lang; # skip rows with aliases we don't need
        $hash->{$contributor->code} = $alias && $alias_lang eq $lang ? $alias : $contributor->name;
    }
    return $hash;
}

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

