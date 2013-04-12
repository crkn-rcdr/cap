use utf8;
package CAP::Schema::Result::ImageResources;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::ImageResources

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

=head1 TABLE: C<image_resources>

=cut

__PACKAGE__->table("image_resources");

=head1 ACCESSORS

=head2 image_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 lang

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 2

=head2 resource

  data_type: 'enum'
  default_value: 'title'
  extra: {list => ["title","description"]}
  is_nullable: 0

=head2 value

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "image_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "lang",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 2 },
  "resource",
  {
    data_type => "enum",
    default_value => "title",
    extra => { list => ["title", "description"] },
    is_nullable => 0,
  },
  "value",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</image_id>

=item * L</lang>

=item * L</resource>

=back

=cut

__PACKAGE__->set_primary_key("image_id", "lang", "resource");

=head1 RELATIONS

=head2 image_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Images>

=cut

__PACKAGE__->belongs_to(
  "image_id",
  "CAP::Schema::Result::Images",
  { id => "image_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-04-12 12:39:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LE1z8h9kuOFyN02rhByOBA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
