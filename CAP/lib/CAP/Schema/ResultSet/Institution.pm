package CAP::Schema::ResultSet::Institution;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 list

Returns a list of all institutions. Will return an array or arryref, depending on the calling context.

=cut
sub list {
    my($self, $lang) = @_;
    my @institutions = $self->search({}, { order_by => 'name' } )->all;
    return @institutions if (wantarray);
    return \@institutions;
}


# TODO: methods below here should be checked, documented and/or removed if
# not needed.

# builds a labels-like hash of contributor labels from institutions with contributor codes
sub get_contributors {
    my ($self, $lang, $portal) = @_;

    # get the contributors and aliases
    my @institutions = $self->search(
        { code => { '!=' => undef } }
    );

    # build the hash
    my $hash = { names => {}, info => {} }; # hackish, but it's to preserve the label logic in the view
    foreach my $institution (@institutions) {
        my $alias = $institution->find_related('institution_alias', { lang => $lang });
        my $contributor = $institution->find_related('contributors', { portal_id => $portal->id, lang => $lang });
        $hash->{names}->{$institution->code} = $alias ? $alias->name : $institution->name;
        if ($contributor) {
            $hash->{info}->{$institution->code} = { url => $contributor->url,
                description => $contributor->description,
                logo => $contributor->logo,
                logo_filename => $contributor->logo_filename };
        }
    }
    return $hash;
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
            order_by => 'sessions desc'
        }
    );
    return \@rows;
}

1;
