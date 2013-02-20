package CAP::Schema::ResultSet::TitlesTerms;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 add_document($title_id, @thesaurus_ids)

Add thesaurus terms referenced by @thesaurus_ids to the specified title.

=cut
sub add_terms {
    my($self, $title, @term_ids) = @_;

    foreach my $term_id (@term_ids) {
        $self->find_or_create({ title_id => $title->id, term_id => $term_id });
    }
}

1;
