use utf8;
package CAP::Schema::Result::Images;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Images

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

=head1 TABLE: C<images>

=cut

__PACKAGE__->table("images");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 filename

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 content_type

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 height

  data_type: 'integer'
  is_nullable: 0

=head2 width

  data_type: 'integer'
  is_nullable: 0

=head2 updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "filename",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "content_type",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "height",
  { data_type => "integer", is_nullable => 0 },
  "width",
  { data_type => "integer", is_nullable => 0 },
  "updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<filename>

=over 4

=item * L</filename>

=back

=cut

__PACKAGE__->add_unique_constraint("filename", ["filename"]);

=head1 RELATIONS

=head2 image_resources

Type: has_many

Related object: L<CAP::Schema::Result::ImageResources>

=cut

__PACKAGE__->has_many(
  "image_resources",
  "CAP::Schema::Result::ImageResources",
  { "foreign.image_id" => "self.id" },
  {},
);

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("user_id", "CAP::Schema::Result::User", { id => "user_id" });


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-06-21 09:08:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QuXYzWmWZJCDPOGpW4tzpw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
