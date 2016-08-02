package CAP::Schema::ResultSet::Portal;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 list

Returns a list of all portals. Will return an array or arryref, depending on the calling context.

=cut
sub list {
    my($self) = @_;
    my @portals = $self->search({})->all;
    return @portals if (wantarray);
    return \@portals;
}

=head2 list_subscribable

Returns portals that can be subscribed to.

=cut
sub list_subscribable {
    my($self) = @_;
    my @portals = $self->search({ supports_subscriptions => 1})->all;
    return @portals if (wantarray);
    return \@portals;
}


=head2 new_portal

Creates a new portal with correctly initialized portal_access records.

=cut
sub new_portal {
    my($self, $id) = @_;
    my $portal = $self->find_or_create({ id => $id });
    $portal->add_to_portal_accesses({ level => 0, purchase => -1, browse => -1 });
    $portal->add_to_portal_accesses({ level => 1, purchase => -1, browse => -1 });
    $portal->add_to_portal_accesses({ level => 2, purchase => -1, browse => -1 });
    return $portal;
}




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

sub list_inst_portals {
    my ($self) = shift();
    my $get_portals = $self->search(
        {'supports_institutions' => '1'}
    );
    my $row;
    my $portal_id;
    my $portals = [];    
    while ($row = $get_portals->next) {
       push (@$portals, $row->id);
    }
    return $portals;
}

1;
