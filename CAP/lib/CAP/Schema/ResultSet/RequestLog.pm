package CAP::Schema::ResultSet::RequestLog;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use POSIX qw(strftime);

# Log the current request.
sub log
{
    my($self, $c) = @_;

    $self->create({
        'time' => strftime('%Y-%m-%d %H:%M:%S', localtime(time)),
        'session' => $c->sessionid,
        'session_count' => $c->session->{count},
        'portal' => $c->stash->{portal},
        'view' => $c->stash->{current_view},
        'action' => $c->request->action,
        'status' => $c->response->status,
    });
}

1;
