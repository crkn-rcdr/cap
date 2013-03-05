package CAP::Schema::ResultSet::Documents;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 CAP::Schema::ResultSet::Documents

=head1 Methods

=cut


=head2 by_identifier($identifier, $institution)

Retrieve the document with the specified identifier and for the specified institution. 

$institution is the numeric ID of the institution. TODO: this should be
able to take a code and/or institution object as well.

=cut
sub by_identifier {
    my($self, $identifier, $institution) = @_;
    my $institution_id = $institution;

    my $document = $self->find(
        {
            'identifier' => $identifier,
            'title_id.institution_id' => $institution
        },  
        {   
            join => 'title_id'
        }   
    );  

    return $document;
}

1;
