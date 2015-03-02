use utf8;
package CAP::Schema::Result::CollectionsTitles;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::CollectionsTitles

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::EncodedColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 TABLE: C<collections_titles>

=cut

__PACKAGE__->table("collections_titles");

=head1 ACCESSORS

=head2 title_identifier

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 collection

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "title_identifier",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "collection",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</title_identifier>

=item * L</collection>

=back

=cut

__PACKAGE__->set_primary_key("title_identifier", "collection");

=head1 RELATIONS

=head2 collection

Type: belongs_to

Related object: L<CAP::Schema::Result::Collections>

=cut

__PACKAGE__->belongs_to(
  "collection",
  "CAP::Schema::Result::Collections",
  { collection => "collection" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-03-02 15:51:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yg8Asn24xFBcKVNNDWUPfQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
