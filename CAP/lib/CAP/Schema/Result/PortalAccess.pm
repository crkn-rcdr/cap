use utf8;
package CAP::Schema::Result::PortalAccess;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::PortalAccess

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

=head1 TABLE: C<portal_access>

=cut

__PACKAGE__->table("portal_access");

=head1 ACCESSORS

=head2 portal_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 level

  data_type: 'integer'
  is_nullable: 0

=head2 preview

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 content

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 metadata

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 resize

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 download

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 purchase

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 searching

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 browse

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "portal_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 64 },
  "level",
  { data_type => "integer", is_nullable => 0 },
  "preview",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "content",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "metadata",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "resize",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "download",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "purchase",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "searching",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "browse",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</portal_id>

=item * L</level>

=back

=cut

__PACKAGE__->set_primary_key("portal_id", "level");

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


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-08-16 13:32:12
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UrKrSKBKaBJhHXwiPWyxcg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
