use utf8;
package CAP::Schema::Result::InstitutionIpaddr;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::InstitutionIpaddr

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<institution_ipaddr>

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

=head1 PRIMARY KEY

=over 4

=item * L</cidr>

=back

=cut

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


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-06-21 09:08:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r9JitwZHDBw22NPX3pLJcQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
