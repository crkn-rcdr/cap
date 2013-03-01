use utf8;
package CAP::Schema::Result::Contributor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Contributor

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

=head1 TABLE: C<contributor>

=cut

__PACKAGE__->table("contributor");

=head1 ACCESSORS

=head2 portal_id

  data_type: 'varchar'
  default_value: (empty string)
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 institution_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 lang

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 2

=head2 url

  data_type: 'text'
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 logo

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 logo_filename

  data_type: 'varchar'
  is_nullable: 1
  size: 32

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
  "institution_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "lang",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 2 },
  "url",
  { data_type => "text", is_nullable => 1 },
  "description",
  { data_type => "text", is_nullable => 1 },
  "logo",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "logo_filename",
  { data_type => "varchar", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</portal_id>

=item * L</institution_id>

=item * L</lang>

=back

=cut

__PACKAGE__->set_primary_key("portal_id", "institution_id", "lang");

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

=head2 portal_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Portal>

=cut

__PACKAGE__->belongs_to(
  "portal_id",
  "CAP::Schema::Result::Portal",
  { id => "portal_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-03-01 10:13:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uCX1L9oRw+UqDNqehgbasw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
