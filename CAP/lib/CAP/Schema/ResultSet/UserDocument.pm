package CAP::Schema::ResultSet::UserDocument;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub purchased_documents
{
    my($self, $user_id) = @_;
    my $purchased = {};
    foreach my $document ($self->search({ user_id => $user_id })) {
        $purchased->{$document->document} = $document;
    }
    return $purchased;
}

# List of document records the user has purchased, sorted from most to
# least recently purchased
sub list_purchased
{
    my($self, $user_id, $solr) = @_;
    my $purchased = [];
    foreach my $doc ($self->search({ user_id => $user_id }, { order_by => { -desc => 'acquired'}})) {
        push(@{$purchased}, $solr->document($doc->document));
    }
    return $purchased;
}


1;

