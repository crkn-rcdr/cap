package CAP::Schema::ResultSet::InstitutionCollection;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

# Returns a result set of collections sponsored by the institution as an
# arrayref
sub sponsored_collections
{
    my($self, $institution_id) = @_;
    return [$self->search({ institution_id => $institution_id }, { order_by => { -asc => 'collection_id' }})->all];
}

sub sponsor_collection
{
    my($self, $institution_id, $collection_id) = @_;

    $self->find_or_create(
        {
            institution_id => $institution_id,
            collection_id  => $collection_id,
        },
        { key => 'primary' }
    );
    return 1;
}

sub unsponsor_collection
{
    my($self, @collection) = @_;
    foreach my $collection_id (@collection) {
        my $record = $self->find({ collection_id => $collection_id});
        $record->delete if ($record);
    }
    return 1;
}

1;

