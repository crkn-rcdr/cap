package CAP::Schema::Result::InstitutionIpaddr;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

CAP::Schema::Result::InstitutionIpaddr

=cut

__PACKAGE__->table("institution_ipaddr");

=head1 ACCESSORS

=head2 cidr

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 institution_id

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
  "institution_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "start",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
  "end",
  { data_type => "bigint", extra => { unsigned => 1 }, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cidr");

=head1 RELATIONS

=head2 institution_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Institution>

=cut

__PACKAGE__->belongs_to(
  "institution_id",
  "CAP::Schema::Result::Institution",
  { id => "institution_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-09-11 16:26:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:b9x5GK05tgHOecqzJpHdAg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
