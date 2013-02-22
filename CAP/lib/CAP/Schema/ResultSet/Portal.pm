package CAP::Schema::ResultSet::Portal;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# Returns a ResultSet of portals that only contain the given feature
sub with_feature {
    my ($self, $feature, $lang) = @_;
    return $self->search({ 'feature' => $feature }, { join => 'portal_features' });
}

sub with_names {
    my ($self, $lang) = @_;
    return $self->search({ 'lang' => $lang, 'label' => 'name' },
        { join => 'portal_strings', '+select' => ['portal_strings.string'], '+as' => ['string'] });
}

sub list_portals {
    my ($self) = shift();
    my $get_portals = $self->search({});
    my $row;
    my $portal_id;
    my $portals = [];    
    while ($row = $get_portals->next) {
       push (@$portals, $row->id);
    }
    return $portals;
}
1;
