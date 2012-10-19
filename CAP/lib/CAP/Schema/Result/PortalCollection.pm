package CAP::Schema::Result::PortalCollection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::PortalCollection

=cut

__PACKAGE__->table("portal_collection");

=head1 ACCESSORS

=head2 portal_id

  data_type: 'varchar'
  default_value: (empty string)
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 collection_id

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 hosted

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "portal_id",
  {
    data_type => "varchar",
    default_value => "",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 64,
  },
  "collection_id",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "hosted",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("portal_id", "collection_id");

=head1 RELATIONS

=head2 portal_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Portal>

=cut

__PACKAGE__->belongs_to(
  "portal_id",
  "CAP::Schema::Result::Portal",
  { id => "portal_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-10-15 16:37:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Vo2woL22Igt3pSJvZrQwRA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
