package CAP::Schema::ResultSet::UserDocument;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# Update the user's bookshelf contents. We create two items: an array of
# records sorted in order of acquisition and a hash table to do access
# lookups. The hash table contains the database row, while the sorted list
# contains a hashref that will later be populated with additional
# information (such as the current title of the item, according to the
# Solr database).
sub documents_for_user
{
    my($self, $c) = @_;

    foreach my $document ($self->search({ user_id => $c->user->id }, { order_by => 'acquired' })) {
        my $book = {
            key => $document->document,
            acquired => $document->acquired,
        };
        push(@{$c->session->{user_bookshelf}}, $book);
        $c->session->{bookshelf}->{$document->document} = $document;
    }
}

sub purchased_documents
{
    my($self, $user_id) = @_;
    my $purchased = {};
    foreach my $document ($self->search({ user_id => $user_id })) {
        $purchased->{$document->document} = $document;
    }
    return $purchased;
}


1;

