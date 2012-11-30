package CAP::Schema::ResultSet::UserSubscription;

use strict;
use warnings;
use Date::Manip::Date;
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

sub expiring_subscriptions {
    my ( $self, $from_date, $now ) = @_;

    my $expiring = $self->search(
        {

            expires   => { '<=' => $from_date, '>=' => $now },
            permanent     => 0,
            reminder_sent => 0,
            level => { '>=' => 1 }

        }
    );
    
    my $result;
    my $userinfo;
    my $expiring_accounts = [];
    
    while ($result = $expiring->next) {
       $userinfo = { 'id'       => $result->user_id,
                     'level'    => $result->level,
                     'expires'  => $result->expires };
       push (@$expiring_accounts, $userinfo);   
    }
  
    return $expiring_accounts;
}

sub active_subscriptions {
    my($self) = @_;
    my $date = new Date::Manip::Date;
    $date->parse('now');
    my $now = $date->printf("%Y-%m-%d %T");
    return $self->search({ expires => { '>=' => $now }});
}

sub next_unsent_reminder {
    my($self, $from_date, $now) = @_;

    my $expiring = $self->search ({

            expires   => { '<=' => $from_date, '>=' => $now },
            permanent     => 0,
            reminder_sent => 0,
            level => { '>=' => 1 }

    });

    return $expiring->first || undef;
}


1;

