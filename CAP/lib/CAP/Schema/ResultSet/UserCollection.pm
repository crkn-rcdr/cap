package CAP::Schema::ResultSet::UserCollection;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use POSIX qw(strftime);

# Returns the collections subscribed to by the user, whether active or
# not.
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

# Returns currently active (unexpired) collections for the user.
sub subscribed_collections
{
    my($self, $user_id) = @_;
    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime(time));

    my $subscriptions = {};
    foreach my $collection ($self->search({ user_id => $user_id, expires => { '>=', $now } })) {
        $subscriptions->{$collection->id} = $collection;
    }
    return $subscriptions;
}

1;



