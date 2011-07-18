package CAP::Schema::ResultSet::GroupsCollection;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# Returns the collections subscribed to by the group
sub collections_for_group
{
    my($self, $group_id) = @_;

    my @collections = ();
    foreach my $collection ($self->search({ group_id => $group_id })) {
        push(@collections, {
            id => $collection->collection_id->id,
            joined => $collection->joined,
            expires => $collection->expires
        });
    }
    return @collections;
}

1;


