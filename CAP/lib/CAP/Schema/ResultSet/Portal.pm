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

# Returns a ResultSet of portals that only contain the given feature
sub with_feature {
    my ($self, $feature, $lang) = @_;
    return $self->search({ 'feature' => $feature }, { join => 'portal_features' });
}

sub with_titles {
    my ($self, $lang) = @_;
    my $rs = $self->search({ 'portal_langs.lang' => $lang },
        { join => 'portal_langs', 'select' => ['me.id', 'portal_langs.title'], 'as' => ['id', 'title'] });

    return { map {
        ($_->get_column('id') => $_->get_column('title') || $_->get_column('id'))
        } $rs->all() };
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
