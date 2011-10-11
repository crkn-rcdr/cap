package CAP::Schema::ResultSet::Info;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# Return true if the database version matches $required_version.
sub check_version {
    my($self, $required_version) = @_;
    my $db_version = $self->find({ name => 'version' });
    return 0 unless $db_version;
    return 0 unless $db_version->value;
    return 0 unless int($db_version->value) eq int($required_version);
    return 1;
}

1;



