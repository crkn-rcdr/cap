package CAP::Schema::Result::Groups;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::Groups

=cut

__PACKAGE__->table("groups");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 128 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 groups_collections

Type: has_many

Related object: L<CAP::Schema::Result::GroupsCollection>

=cut

__PACKAGE__->has_many(
  "groups_collections",
  "CAP::Schema::Result::GroupsCollection",
  { "foreign.group_id" => "self.id" },
  {},
);

=head2 groups_ipaddrs

Type: has_many

Related object: L<CAP::Schema::Result::GroupsIpaddr>

=cut

__PACKAGE__->has_many(
  "groups_ipaddrs",
  "CAP::Schema::Result::GroupsIpaddr",
  { "foreign.group_id" => "self.id" },
  {},
);

=head2 user_groups

Type: has_many

Related object: L<CAP::Schema::Result::UserGroups>

=cut

__PACKAGE__->has_many(
  "user_groups",
  "CAP::Schema::Result::UserGroups",
  { "foreign.group_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2011-06-17 14:10:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:94zUjb8XAKASj0aZ1IF4Cw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
