package CAP::Schema::ResultSet::Institution;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Text::Trim qw/trim/;

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

sub export {
    my ($self, @languages) = @_;
    my $out = "";
    foreach my $inst ($self->search(undef, { order_by => 'name' })) {
        my $line = join(";",
            $inst->name,
            defined($inst->code) ? $inst->code : "",
            $inst->subscriber
        );

        my $aliases = {};
        foreach my $alias ($inst->search_related('institution_alias')) {
            $aliases->{$alias->lang} = $alias->name;
        }
        foreach my $lang (@languages) {
            $line = join(";", $line, defined($aliases->{$lang}) ? $aliases->{$lang} : "");
        }

        $out = join("&#10;", $out, $line); # using the HTML escape for newline so that formatting is preserved in the HTML
    }

    return $out;
}

sub import {
    my ($self, $data, @languages) = @_;
    return sub {
        foreach my $line (split(/\n/, $data)) {
            # basic record items
            my @items = split(/;/, trim($line));
            my $record = { name => shift @items };
            my $code = shift @items;
            $record->{code} = $code if $code;
            $record->{subscriber} = shift @items;
            my $institution = $self->update_or_create($record);

            # now for the aliases
            foreach my $lang (@languages) {
                $institution->set_alias($lang, shift @items);
            }
        }
    };
}

# Tally logged requests by institution
sub requests {
    my $self = shift;
    my @rows = $self->search(
        { 'request_logs.id' => { '!=' => undef } },
        {
            join => 'request_logs',
            select => ['id', 'name', { count => { distinct => 'request_logs.session' }, '-as' => 'sessions'}, { count => 'me.id', '-as' => 'requests' }],
            as => ['id', 'name', 'sessions', 'requests'],
            group_by => ['me.id'],
            order_by => 'sessions'
        }
    );
    return \@rows;
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

