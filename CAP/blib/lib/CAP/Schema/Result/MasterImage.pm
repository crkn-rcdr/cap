package CAP::Schema::Result::MasterImage;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("master_image");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 128,
  },
  "path",
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
  "ctime",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "bytes",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "md5",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 32,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-27 12:55:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aMKfuoOT5hpbFj8WpMT0vA

__PACKAGE__->load_components('ForceUTF8');
__PACKAGE__->resultset_class('CAP::Schema::ResultSet::MasterImage');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
