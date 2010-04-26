package CAP::Schema::ResultSet::Role;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub roles
{
    my($self, $ids) = @_;
    
    return $self->search({ id => { '-in' => $ids } });
}

# Return true if all role names in @roles exist.
# TODO: we probably don't need this.
sub role_exists
{
    my($self, @roles) = @_;
    foreach my $role (@roles) {
        return 0 unless ($self->find({ role => $role }));
    }
    return 1;
}

1;

