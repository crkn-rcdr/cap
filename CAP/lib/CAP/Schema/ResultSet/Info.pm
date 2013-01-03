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
    my($self, $assert_version) = @_;
    my $db_version = $self->find({ name => 'version' });
    unless ($db_version && $db_version->value && int($db_version->value) eq int($assert_version)) {
        die("assert_version failed: CAP database version is $db_version but is supposed to be $assert_version");
    }
    return 1;
}

1;



