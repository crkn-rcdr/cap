package CAP::Schema::ResultSet::Lexicon;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';


=head1 NAME

CAP::Schema::ResultSet::Lexicon - i18n lexicon database methods

=head1 DESCRIPTION

Methods for editing the i18n lexicon database.

=head1 METHODS

=cut

=head1 

=over 4

=item translations ( I<$language> )

Returns all of the table rows containing translations into I<$language>.

=back
=cut
sub translations
{
    my($self, $language) = @_;
    my $result = $self->search(
        { language => { '=' => $language } },
        { order_by => 'path, message' },
    );
    return [$result->all()];
}

# All messages for $language with no value or an empty value
sub untranslated
{
    my($self, $language) = @_;
    my $result = $self->search(
        { 
            language => { '=' => $language },
            value => { '=' => [undef, ''] },
        },
        { order_by => 'path, message' },
    );
    return [$result->all()];
}


# All messages for $language with a value
sub translated
{
    my($self, $language) = @_;
    my $result = $self->search(
        { 
            language => { '=' => $language },
            value => { '!=' => '' },
        },
        { order_by => 'path, message' },
    );
    return [$result->all()];
}

sub get_message
{
    my($self, $id) = @_;
    return $self->find({ id => $id });
}

1;
