use utf8;
package CAP::Schema::Result::SlideDescription;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::SlideDescription

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

=head1 TABLE: C<slide_description>

=cut

__PACKAGE__->table("slide_description");

=head1 ACCESSORS

=head2 slide_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 lang

  data_type: 'varchar'
  is_nullable: 0
  size: 2

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "slide_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "lang",
  { data_type => "varchar", is_nullable => 0, size => 2 },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</slide_id>

=item * L</lang>

=back

=cut

__PACKAGE__->set_primary_key("slide_id", "lang");

=head1 RELATIONS

=head2 slide_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Slide>

=cut

__PACKAGE__->belongs_to("slide_id", "CAP::Schema::Result::Slide", { id => "slide_id" });


# Created by DBIx::Class::Schema::Loader v0.07022 @ 2012-04-25 11:20:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:XwMogml+lpNXq9+CVXumdA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
