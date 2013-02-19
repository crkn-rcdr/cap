package CAP::Schema::ResultSet::TitlesThesauruses;
use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 add_document($contributor, $doc_id, \@keys, \@terms)

Add document $contributor.$doc_id to the document_thesaurus table with the
listed hierarchy in \@keys and \@labels. Missing thesaurus terms are
created.

=cut
sub add_document {
    my($self, $contributor, $doc_id, @keys) = @_;
    my $thesaurus = $self->related_resultset('thesaurus_id');

    foreach my $thesaurus_id (@keys) {
        $self->find_or_create({contributor => $contributor, id => $doc_id, thesaurus_id => $thesaurus_id});
    }

}

1;
