package CAP::Schema::Result::PimgCache;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::PimgCache

=cut

__PACKAGE__->table("pimg_cache");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 format

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 size

  data_type: 'integer'
  is_nullable: 0

=head2 rot

  data_type: 'integer'
  is_nullable: 0

=head2 data

  data_type: 'longblob'
  is_nullable: 0

=head2 ctime

  data_type: 'integer'
  is_nullable: 0

=head2 atime

  data_type: 'datetime'
  is_nullable: 0

=head2 acount

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "format",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "size",
  { data_type => "integer", is_nullable => 0 },
  "rot",
  { data_type => "integer", is_nullable => 0 },
  "data",
  { data_type => "longblob", is_nullable => 0 },
  "ctime",
  { data_type => "integer", is_nullable => 0 },
  "atime",
  { data_type => "datetime", is_nullable => 0 },
  "acount",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id", "format", "size", "rot");


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-27 12:33:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xcpwvkMpkKcQ2PaySE4mog
#
#
__PACKAGE__->load_components('ForceUTF8');
__PACKAGE__->resultset_class('CAP::Schema::ResultSet::PimgCache');

__PACKAGE__->add_columns(
    "atime" =>
    { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
);


# You can replace this text with custom content, and it will be preserved on regeneration
1;
