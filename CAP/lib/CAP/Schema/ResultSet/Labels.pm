package CAP::Schema::ResultSet::Labels;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub get_labels
{
    my($self, $lang) = @_;
    my $labels = {};

    my $result = $self->search({ lang => $lang });

    while (my $label = $result->next) {
        $labels->{$label->field} = {} unless ($labels->{$label->field});
        $labels->{$label->field}->{$label->code} = $label->label;
    }
    return $labels;
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

