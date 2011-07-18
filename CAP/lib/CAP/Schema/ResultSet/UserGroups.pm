package CAP::Schema::ResultSet::UserGroups;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# Returns the groups for the selected user id.
sub groups_for_user
{
    my($self, $user_id) = @_;

    my @groups = ();
    foreach my $group ($self->search({ user_id => $user_id })) {
        push(@groups, $group->group_id);
    }
    return @groups;
}

1;

