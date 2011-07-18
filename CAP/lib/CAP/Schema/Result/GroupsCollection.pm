package CAP::Schema::Result::GroupsCollection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::GroupsCollection

=cut

__PACKAGE__->table("groups_collection");

=head1 ACCESSORS

=head2 collection_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 joined

  data_type: 'datetime'
  is_nullable: 1

=head2 expires

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "collection_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "joined",
  { data_type => "datetime", is_nullable => 1 },
  "expires",
  { data_type => "datetime", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("collection_id", "group_id");

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

=head2 group_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Groups>

=cut

__PACKAGE__->belongs_to(
  "group_id",
  "CAP::Schema::Result::Groups",
  { id => "group_id" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2011-06-20 08:08:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:o4ntZhhIdsYPg7vCIvGbCA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
