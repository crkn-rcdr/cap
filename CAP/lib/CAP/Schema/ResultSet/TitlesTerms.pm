package CAP::Schema::ResultSet::TitlesTerms;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 add_document($title_id, @thesaurus_ids)

Add thesaurus terms referenced by @thesaurus_ids to the specified title.

=cut
sub add_terms {
    my($self, $title, @thesaurus_ids) = @_;

    foreach my $thesaurus_id (@thesaurus_ids) {
        $self->find_or_create({ title_id => $title->id, thesaurus_id => $thesaurus_id });
    }
}

1;
