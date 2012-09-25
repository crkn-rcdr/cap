package CAP::Schema::ResultSet::UserSubscription;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

 
sub subscription {
    my ($self, $userid, $portalid) = @_;

    return 1;
}

sub is_subscriber {
    my ($self, $userid, $portalid) = @_;

    return 1;
}

sub subscribe {
    my ($self, $userid, $portalid) = @_;

    return 1;
}



1;

