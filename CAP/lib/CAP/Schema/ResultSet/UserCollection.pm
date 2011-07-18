package CAP::Schema::ResultSet::UserCollection;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# Returns the collections subscribed to by the user
sub collections_for_user
{
    my($self, $user_id) = @_;

    my @collections = ();
    foreach my $collection ($self->search({ user_id => $user_id })) {
        push(@collections, {
            id => $collection->collection_id->id,
            joined => $collection->joined,
            expires => $collection->expires
        });
    }
    return @collections;
}

1;



