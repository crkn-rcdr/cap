package CAP::Schema::ResultSet::Discounts;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 CAP::Schema::ResultSet::Discounts

=head1 Methods

=cut

=head2 list

Returns a list of all discounts. Will return an array or arryref,
depending on the calling context.

=cut
sub list {
    my($self) = @_;
    my @discounts = $self->search({}, { order_by => 'expires' })->all;
    return @discounts if (wantarray);
    return \@discounts;
}


1;
