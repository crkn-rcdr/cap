package CAP::Schema::ResultSet::UserSubscription;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

 
sub subscription {
    my ($self, $userid, $portalid) = @_;
    
    my $row = $self->find(
        {
            'user_id'   => $userid,
            'portal_id' => $portalid
        }

    );

    return $row;
}

sub is_subscriber {
    my ($self, $userid, $portalid) = @_;
    my $search = $self->search(
        {
            'user_id'   => $userid,
            'portal_id' => $portalid
        }

    );

    return $search->count;
}

sub subscribe {
    my ( $self, $userid, $portalid, $level, $expires, $permanent ) = @_;

    my %records = (

        'user_id'       => $userid,
        'portal_id'     => $portalid,
        'level'         => $level,
        'expires'       => $expires,
        'permanent'     => $permanent,
        'reminder_sent' => 0,
        'last_updated'  => undef

    );

    my $err = $self->update_or_create(

        {%records},
        { key => 'primary' }

    );

    return 1;
}



1;

