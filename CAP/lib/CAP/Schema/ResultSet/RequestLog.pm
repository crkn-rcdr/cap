package CAP::Schema::ResultSet::RequestLog;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use POSIX qw(strftime);

# Log the current request.
sub log
{
    my($self, $c) = @_;

    my $get_id;
    
    eval { $get_id = $c->session->{auth}->{user}->id } ; # have to do an eval because accessor throws exception if there's no user id
    my $user_id = $@ ? $get_id : undef;

    my $institution_id = $c->session->{subscribing_institution_id} || undef;

    
    my $args = join ("/" , @{ $c->request->arguments });
    

    $self->create({
        'time' => strftime('%Y-%m-%d %H:%M:%S', localtime(time)),
        'user_id' => $user_id,
        'institution_id' => $institution_id,
        'session' => $c->sessionid,
        'session_count' => $c->session->{count},
        'portal' => $c->stash->{portal},
        'view' => $c->stash->{current_view},
        'action' => $c->request->action,
        'args' => $args
    });
}

1;
