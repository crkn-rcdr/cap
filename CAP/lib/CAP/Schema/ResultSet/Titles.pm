package CAP::Schema::ResultSet::Titles;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 CAP::Schema::ResultSet::Titles

=head1 METHODS

=cut

=head2 institutions

Returns a list of institutions, sorted by name, which own one or more titles.

=cut
sub institutions {
    my($self) = @_;
    my @institutions;

    my $result = $self->search({}, {
        select => [ 'institution_id' ],
        distinct => 1,
        join => 'institution_id',
        order_by => 'institution_id.name'
    });
    while (my $institution = $result->next) {
        push(@institutions, $institution->institution_id);
    }
    
    return @institutions;
}


=head2 titles_for_institution ($institution, %params)

Returns all titles belonging to $institution. %params affects the subset
and/or page returned (TBD).

=cut
sub titles_for_institution {
    my($self, $institution, %params) = @_;
    my $query = { 'me.institution_id' => $institution->id };
    my $limit = {};
    my $page = $params{page} || undef;
    my $rows = $params{rows} || 50;
    my $portal = $params{portal};
    my $unassigned = $params{unassigned};
    my $hosted = $params{hosted};
    my $identifier = $params{identifier};
    my $label = $params{label};

    # Return a paged result set
    if ($page) {
        $limit->{page} = $page;
        $limit->{rows} = $rows;
    }

    # Limit to titles matching the subtring for identifier
    if ($identifier) {
        # FIXME: is this a MySQLism? We need to escape _ and % so they
        # aren't treated as metacharacters.
        $identifier =~ s/_/\\_/g;
        $identifier =~ s/%/\\%/g;
        $query->{identifier} = { -like => "%$identifier%" };
    }

    # Limit to titles matching the substring for the label
    if ($label) {
        # FIXME: is this a MySQLism? We need to escape _ and % so they
        # aren't treated as metacharacters.
        $label =~ s/_/\\_/g;
        $label =~ s/%/\\%/g;
        $query->{label} = { -like => "%$label%" };
    }

    # Portal and unassigned are incompatible options. If both are
    # specified, portal overrides unassigned.
    if ($portal) {
        $query->{'portals_titles.portal_id'} = $portal->id;
        $limit->{join} = 'portals_titles';
        if (defined($hosted)) {
            $query->{'portals_titles.hosted'} = $hosted;
        }
    }
    elsif ($unassigned) {
        $query->{portal_id} = { '=' => undef };
        $limit->{join} = 'portals_titles';
    }

    return $self->search($query, $limit);
}


sub titles_for_portal {
    my($self, $portal, %params) = @_;
    my $page = $params{page} || undef;
    my $rows = $params{rows} || 50;
    my $institution = $params{institution} || undef;
    my $query = { 'portals_titles.portal_id' => $portal->id };
    my $limit = { join => 'portals_titles' };
    my $hosted = $params{hosted};

    # Return a paged result set
    if ($page) {
        $limit->{page} = $page;
        $limit->{rows} = $rows;
    }
    
    # Limit by indexed/hosted
    if (defined($hosted)) {
        $query->{'portals_titles.hosted'} = $hosted;
    }

    # Limit by institution
    if (defined($institution)) {
        $query->{'me.institution_id'} = $institution->id;
    }

    return $self->search($query, $limit);
}

=head2 titles_for_portal ($portal [,$page [,$rows]])

Like titles_for_institution() but returns titles that are present in $portal.

=cut
sub titles_for_portal_2 {
    my($self, $portal, $page, $rows) = @_;
    my $result;
    $rows = 50 unless ($rows);

    if ($page) {
        $result = $self->search({ 'portals_titles.portal_id' => $portal->id }, { join => 'portals_titles', page => $page, rows => $rows });
    }
    else {
        $result = $self->search({ 'portals_titles.portal_id' => $portal->id }, { join => 'portals_titles' });
    }

    return $result;
}


=head2 updated_after (DateTime)

Returns a set of titles which have either been updated or added to a portal on or after DateTime

=cut
sub updated_after {
    my($self, $time) = @_;
    my $result = $self->search(
        {
            '-or' => [
                'me.updated' => { '>=' => $time },
                'portals_titles.updated' => { '>=' => $time }
            ]
        },
        {
            join => 'portals_titles'
        }
    );
    return $result;
}


##################


sub counts_for_portal {
    my($self, $portal) = @_;

    my $result = $self->search(
        {
            'portals_titles.portal_id' => $portal->id
        },
        {
            select   => [ 'institution_id', { count => 'id', -as => 'title_count' } ],
            as       => [ 'institution_id', 'titles' ],
            group_by => [ 'institution_id' ],
            order_by => [ { -desc => 'title_count' } ],
            join     => 'portals_titles'
        }
    );

    my @institutions = ();
    while (my $result = $result->next) {
        push(@institutions, {
            institution => $result->institution_id,
            titles => $result->get_column('titles')
        });
    }
    return \@institutions;
}




1;
