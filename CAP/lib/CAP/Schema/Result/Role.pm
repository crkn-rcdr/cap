package CAP::Schema::Result::Role;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("role");
__PACKAGE__->add_columns(
  "id",
  { data_type => "INT", default_value => undef, is_nullable => 0, size => 11 },
  "role",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 128,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("role", ["role"]);


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-27 12:55:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IKlNMBMoPcIk8PbW4ehCwg

__PACKAGE__->load_components('ForceUTF8');
__PACKAGE__->has_many(map_user_roles => 'CAP::Schema::Result::UserRole', 'role_id');

1;
