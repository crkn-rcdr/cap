package CAP::Schema::Result::UserRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::UserRole

=cut

__PACKAGE__->table("user_role");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 role_id

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "role_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("user_id", "role_id");


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-27 12:33:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b678gYVkPyS398OcaDfbkw


# You can replace this text with custom content, and it will be preserved on regeneration

#__PACKAGE__->load_components('ForceUTF8');
__PACKAGE__->belongs_to(user => 'CAP::Schema::Result::User', 'user_id');
__PACKAGE__->belongs_to(role => 'CAP::Schema::Result::Role', 'role_id');

1;
