package CAP::Schema::ResultSet::PortalString;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub names {
    my ($self, $lang) = @_;
    my %names = ();
    foreach ($self->search({ 'label' => 'name', 'lang' => $lang })) {
        $names{$_->get_column('portal_id')} = $_->string;
    }
    return %names;
}
1;


