package CAP::Schema::Result::UserGroups;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::UserGroups

=cut

__PACKAGE__->table("user_groups");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 joined

  data_type: 'datetime'
  is_nullable: 1

=head2 expires

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "joined",
  { data_type => "datetime", is_nullable => 1 },
  "expires",
  { data_type => "datetime", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("user_id", "group_id");

=head1 RELATIONS

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("user_id", "CAP::Schema::Result::User", { id => "user_id" });

=head2 group_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Groups>

=cut

__PACKAGE__->belongs_to(
  "group_id",
  "CAP::Schema::Result::Groups",
  { id => "group_id" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2011-06-17 14:10:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TwxxrjoWoqaV4jPKGdEs1g


# You can replace this text with custom content, and it will be preserved on regeneration
1;
