package CAP::Schema::ResultSet::SearchLog;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use POSIX qw(strftime);

# Log the current request.
sub log
{
    my($self, $c, $request_log) = @_;

    $self->create({
        'request_id' => $request_log->id,
        'query'      => $c->request->uri,
        'results'    => $c->stash->{response}->{result}->{hits}
    });
}

1;
