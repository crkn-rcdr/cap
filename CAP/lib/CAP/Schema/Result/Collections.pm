use utf8;
package CAP::Schema::Result::Collections;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Collections

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

=head1 TABLE: C<collections>

=cut

__PACKAGE__->table("collections");

=head1 ACCESSORS

=head2 collection

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 title_en

  data_type: 'text'
  is_nullable: 0

=head2 title_fr

  data_type: 'text'
  is_nullable: 0

=head2 description_en

  data_type: 'text'
  is_nullable: 0

=head2 description_fr

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "collection",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "title_en",
  { data_type => "text", is_nullable => 0 },
  "title_fr",
  { data_type => "text", is_nullable => 0 },
  "description_en",
  { data_type => "text", is_nullable => 0 },
  "description_fr",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</collection>

=back

=cut

__PACKAGE__->set_primary_key("collection");

=head1 RELATIONS

=head2 collections_titles

Type: has_many

Related object: L<CAP::Schema::Result::CollectionsTitles>

=cut

__PACKAGE__->has_many(
  "collections_titles",
  "CAP::Schema::Result::CollectionsTitles",
  { "foreign.collection" => "self.collection" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-03-02 15:51:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PVhTEx/+56chkOLwIEd3ow


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
