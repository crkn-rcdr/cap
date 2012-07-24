package CAP::Schema::ResultSet::PortalCollection;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# Return a Solr query fragment for limiting queries to collections
# searchable by the portal. If there are no entries in portal_collection
# for the current portal, return an empty string (i.e. search everything)
sub search_subset {
    my($self, $portal) = @_;
    my @result = $self->search({ portal_id => $portal })->get_column('collection_id')->all;
    my @subset = ();
    foreach my $collection (@result) {
        push(@subset, "collection:$collection");
    }
    return "" unless (@subset);
    return join(" OR ", @subset);
}

1;



