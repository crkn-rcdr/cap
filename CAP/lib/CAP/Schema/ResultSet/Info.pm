package CAP::Schema::ResultSet::Info;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 assert_version

assert_version($version)

=over 4

Die with an error message if the database version does not match the asserted version.

=back

=cut
sub assert_version {
    my ($self, $assert_version) = @_;
    my $db_version = $self->find({ name => 'version' });
    unless ($db_version && $db_version->value && int($db_version->value) eq int($assert_version)) {
        die("assert_version failed: CAP database version is " . $db_version->value . " but is supposed to be $assert_version");
    }
    return 1;
}

sub existing_pid {
    # returns pid of existing cron script or undef
    my ($self, $script) = @_;
    my $script_running = $self->find({ name  => $script });
    my $process_id = defined ($script_running) ? $script_running->value : undef;
    return $process_id;
}



sub obtain_pid_lock {

    # return false if you find an existing instance of the script
    my ($self, $script, $pid) = @_;
    my $script_running = $self->find({ name  => $script });

    if ( defined ($script_running) ) {
        return 0;
    }
    
    # otherwise insert pid and return true
    else {
            my $insert =   $self->create({
                                   name  => $script,
                                   value => $pid,
                                   time => \'NOW()'
          });
          return 1;
    }

}


1;



