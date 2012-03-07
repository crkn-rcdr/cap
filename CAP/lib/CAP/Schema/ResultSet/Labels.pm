package CAP::Schema::ResultSet::Labels;

use strict;
use warnings;
use Encode;
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

1;

