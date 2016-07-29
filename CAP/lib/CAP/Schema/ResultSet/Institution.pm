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

sub list_ids {

    my($self) = @_;
    my $institutions =[];
    my $row;
    my $search = $self->search({});
    while ($row = $search->next) {
        push (@$institutions, $row->id);
    }
    
    return $institutions;
    
}


# TODO: methods below here should be checked, documented and/or removed if
# not needed.


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
