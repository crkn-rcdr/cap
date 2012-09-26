use utf8;
package CAP::Schema::Result::InstitutionCollection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::InstitutionCollection

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

=head1 TABLE: C<institution_collection>

=cut

__PACKAGE__->table("institution_collection");

=head1 ACCESSORS

=head2 institution_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 collection_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=cut

__PACKAGE__->add_columns(
  "institution_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "collection_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
);

=head1 PRIMARY KEY

=over 4

=item * L</collection_id>

=back

=cut

__PACKAGE__->set_primary_key("collection_id");

=head1 RELATIONS

=head2 collection_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Collection>

=cut

__PACKAGE__->belongs_to(
  "collection_id",
  "CAP::Schema::Result::Collection",
  { id => "collection_id" },
);

=head2 institution_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Institution>

=cut

__PACKAGE__->belongs_to(
  "institution_id",
  "CAP::Schema::Result::Institution",
  { id => "institution_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2012-09-26 10:41:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RsFHxoqLr8BGsEy2pwEJGg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
