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

Creates a new portal with a dummy placeholder identifier

=cut
sub new_portal {
    my($self) = @_;
    my $id = 'portal_' . int(rand() * 100000);
    my $portal = $self->find_or_create({ id => $id, enabled => 0 });
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

=head2 hosts_for($title)

Returns a list of all portals along with flags indicating whether this document is indexed and hosted.

=cut
sub hosts_for {
    my($self, $title) = @_;
    my @portals;

    my $result = $self->search({});

    while (my $portal = $result->next) {
        my $is_indexed = 0;
        my $is_hosted  = 0;
        my $hosted = $portal->search_related('portals_titles', { title_id => $title->id })->first;
        if ($hosted) {
            $is_indexed = 1;
            $is_hosted = 1 if ($hosted->hosted);
        }
        push(@portals, { portal => $portal, indexed => $is_indexed, hosted => $is_hosted });
    }
    return \@portals;
}

1;
