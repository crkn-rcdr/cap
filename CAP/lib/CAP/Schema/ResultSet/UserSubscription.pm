package CAP::Schema::ResultSet::UserSubscription;

use strict;
use warnings;
use Date::Manip::Date;
use base 'DBIx::Class::ResultSet';

=head2 active_by_portal

Return the number of currently active subscriptions by portal

=cut
sub active_by_portal {
    my($self) = @_;
    my @result = $self->search(
        { expires => { '>=' => DateTime->now() }},
        {
            select => [ 'portal_id', { count => 'user_id', -as => 'user_count' } ],
            as     => [ 'portal_id', 'user_count' ],
            group_by => 'portal_id',
            order_by => [ { -desc => 'user_count' }]
        }
    )->all;
    return @result if (wantarray);
    return \@result;
}

 
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


sub expired_subscriptions {
    my($self) = @_;
    my $date = new Date::Manip::Date;
    $date->parse('now');
    my $now = $date->printf("%Y-%m-%d %T");
    return $self->search({ expires => { '<' => $now }});
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

sub log_expired_subscriptions {
    my ($self, $c) = @_;
    my $row;
    my  $message = "";
    my $portal;
    my $expires;
    my $user;
    my $date = new Date::Manip::Date;
    $date->parse('now');
    my $now = $date->printf("%Y-%m-%d %T");
    my $expired_accts;
 
    $expired_accts = $self->search(
                                                    {
                                                         expires                 =>  { '<' => $now },
                                                         permanent         => '0',
                                                         expiry_logged  =>   undef 
                                                    }
    );

    # Iterate through the rows, log and update row for each expired account
    while ( $row = $expired_accts->next ) {
          $portal = $row->portal_id->id;
          $expires = $row->expires->ymd();
          $user = $c->model('DB::User')->get_user_info($row->user_id->id);
          $message = "$portal subscription expired $expires";
          $row->update( { expiry_logged  =>  $now } );
          $user->log("SUB_END",  $message);
   }
 
    return;
 
 }


1;

