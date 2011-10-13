package CAP::Schema::Result::Role;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::Role

=cut

__PACKAGE__->table("role");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 role

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "role",
  { data_type => "varchar", is_nullable => 0, size => 128 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("role", ["role"]);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-27 12:33:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:C0I/YBC8g6yf6cLtVToEjg

#__PACKAGE__->load_components('ForceUTF8');
__PACKAGE__->has_many(map_user_roles => 'CAP::Schema::Result::UserRole', 'role_id');

1;
