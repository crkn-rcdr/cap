package CAP::Schema::Result::MasterImage;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::MasterImage

=cut

__PACKAGE__->table("master_image");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 path

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 format

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 ctime

  data_type: 'integer'
  is_nullable: 0

=head2 bytes

  data_type: 'integer'
  is_nullable: 0

=head2 md5

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "path",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "format",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "ctime",
  { data_type => "integer", is_nullable => 0 },
  "bytes",
  { data_type => "integer", is_nullable => 0 },
  "md5",
  { data_type => "varchar", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-27 12:33:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8jog6u/jdkFGUjNsYU44yg

__PACKAGE__->load_components('ForceUTF8');
__PACKAGE__->resultset_class('CAP::Schema::ResultSet::MasterImage');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
