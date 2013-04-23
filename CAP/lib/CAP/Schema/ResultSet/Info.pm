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

sub set_pid {
    # set pid for cron script
    my ($self, $script, $pid) = @_;
    my $insert =   $self->create({
                                   name  => $script,
                                   value => $pid,
                                   time => \'NOW()'
    });
    return 1;
 }

sub delete_pid {
    # delete pid when you're done
    my ($self, $script, $pid) = @_;
    my $script_running = $self->find({
                                       name  => $script,
                                       value => $pid
    });
    my $delete = $script_running->delete();
    return 1;
}

1;



