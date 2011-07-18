package CAP::Schema::Result::GroupsIpaddr;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::GroupsIpaddr

=cut

__PACKAGE__->table("groups_ipaddr");

=head1 ACCESSORS

=head2 cidr

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 group_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 start

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=head2 end

  data_type: 'bigint'
  extra: {unsigned => 1}
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cidr",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "group_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "start",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
  "end",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cidr");

=head1 RELATIONS

=head2 group_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Groups>

=cut

__PACKAGE__->belongs_to(
  "group_id",
  "CAP::Schema::Result::Groups",
  { id => "group_id" },
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2011-06-17 12:27:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5OQF9rDJbyova2T5M6pSKA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
