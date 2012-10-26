use utf8;
package CAP::Schema::Result::PortalLang;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::PortalLang

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::EncodedColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 TABLE: C<portal_lang>

=cut

__PACKAGE__->table("portal_lang");

=head1 ACCESSORS

=head2 portal_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 lang

  data_type: 'varchar'
  is_nullable: 0
  size: 2

=head2 priority

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "portal_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 64 },
  "lang",
  { data_type => "varchar", is_nullable => 0, size => 2 },
  "priority",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 UNIQUE CONSTRAINTS

=head2 C<portal_id>

=over 4

=item * L</portal_id>

=item * L</lang>

=back

=cut

__PACKAGE__->add_unique_constraint("portal_id", ["portal_id", "lang"]);

=head1 RELATIONS

=head2 portal_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Portal>

=cut

__PACKAGE__->belongs_to(
  "portal_id",
  "CAP::Schema::Result::Portal",
  { id => "portal_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2012-10-24 09:02:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vPcBq1uFdsA8blsVQ+32zg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;