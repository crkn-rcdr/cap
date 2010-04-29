package CAP::Schema::Result::UserRole;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("user_role");
__PACKAGE__->add_columns(
  "user_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
  "role_id",
  { data_type => "INT", default_value => 0, is_nullable => 0, size => 11 },
);
__PACKAGE__->set_primary_key("user_id", "role_id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-04-27 14:17:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XRSLBG4ADA+F6ftr45LX1w


# You can replace this text with custom content, and it will be preserved on regeneration

__PACKAGE__->load_components('ForceUTF8');
__PACKAGE__->belongs_to(user => 'CAP::Schema::Result::User', 'user_id');
__PACKAGE__->belongs_to(role => 'CAP::Schema::Result::Role', 'role_id');

1;
