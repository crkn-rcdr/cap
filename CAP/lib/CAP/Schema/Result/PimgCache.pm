package CAP::Schema::Result::PimgCache;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("pimg_cache");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 128,
  },
  "format",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
  "size",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "rot",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "data",
  {
    data_type => "LONGBLOB",
    default_value => undef,
    is_nullable => 0,
    size => 4294967295,
  },
  "ctime",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "atime",
  {
    data_type => "DATETIME",
    default_value => undef,
    is_nullable => 0,
    size => 19,
  },
  "acount",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("id", "format", "size", "rot");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-04-27 14:17:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9YVfudWaabF3NJMtgVLTXQ
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
