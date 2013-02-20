package CAP::Schema::Result::PortalString;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::PortalString

=cut

__PACKAGE__->table("portal_string");

=head1 ACCESSORS

=head2 portal_id

  data_type: 'varchar'
  default_value: (empty string)
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 lang

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 2

=head2 label

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 string

  data_type: 'text'
  is_nullable: 1

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
  "lang",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 2 },
  "label",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "string",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("portal_id", "lang", "label");

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-20 09:44:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nRWIgP71qeWMUl1Cjboe6g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
