package CAP::Schema::ResultSet::RequestLog;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use POSIX qw(strftime);

# Log the current request.
sub log
{
    my($self, $c) = @_;

    my $user_id;
    $user_id = $c->user->id if ($c->user_exists);

    $self->create({
        'time' => strftime('%Y-%m-%d %H:%M:%S', localtime(time)),
        'user_id' => $user_id,
        #'institution_id' => ....,
        'session' => $c->sessionid,
        'session_count' => $c->session->{count},
        'portal' => $c->stash->{portal},
        'view' => $c->stash->{current_view},
        'action' => $c->request->action,
        'status' => $c->response->status,
    });
}

1;
