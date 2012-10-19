package CAP::Schema::ResultSet::CronLog;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub insert_feedback
{
    ## inserts new row into cron_log table
    my ($self, $action, $status, $message) = @_;


    my $create = $self->create(
        {

            action     =>   $action,
            ok         =>   $status,
            feedback   =>   $message

        }
    );

    return $create;
}




1;
