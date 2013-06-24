use utf8;
package CAP::Schema::Result::PortalHost;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::PortalHost

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

=head1 TABLE: C<portal_host>

=cut

__PACKAGE__->table("portal_host");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 portal_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 1
  size: 64

=head2 canonical

  data_type: 'tinyint'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "portal_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 64 },
  "canonical",
  { data_type => "tinyint", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<canonical_host>

=over 4

=item * L</id>

=item * L</canonical>

=back

=cut

__PACKAGE__->add_unique_constraint("canonical_host", ["id", "canonical"]);

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


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-06-24 08:40:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:35bvq4H6W9eKSXNIbLKY3g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
