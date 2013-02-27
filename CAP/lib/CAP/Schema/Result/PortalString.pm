use utf8;
package CAP::Schema::Result::PortalString;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::PortalString

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

=head1 TABLE: C<portal_string>

=cut

__PACKAGE__->table("portal_string");

=head1 ACCESSORS

=head2 portal_id

  data_type: 'varchar'
  default_value: (empty string)
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 lang

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 2

=head2 label

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 string

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "portal_id",
  {
    data_type => "varchar",
    default_value => "",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 64,
  },
  "lang",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 2 },
  "label",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "string",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</portal_id>

=item * L</lang>

=item * L</label>

=back

=cut

__PACKAGE__->set_primary_key("portal_id", "lang", "label");

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


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-02-27 08:15:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:B3vxgBrVn9xhosBR7p8uNA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
