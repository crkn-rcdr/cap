package CAP::Schema::Result::Sessions;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn", "Core");
__PACKAGE__->table("sessions");
__PACKAGE__->add_columns(
  "id",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 72 },
  "session_data",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "expires",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 10 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04006 @ 2010-01-27 12:55:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yAa/pSF9fmqiJuH0rB2K4Q

__PACKAGE__->load_components('ForceUTF8');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
