package CAP::Schema::Result::Slide;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

CAP::Schema::Result::Slide

=cut

__PACKAGE__->table("slide");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 portal

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 slideshow

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 sort

  data_type: 'integer'
  is_nullable: 0

=head2 url

  data_type: 'varchar'
  is_nullable: 0
  size: 512

=head2 thumb_url

  data_type: 'varchar'
  is_nullable: 0
  size: 512

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "portal",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "slideshow",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "sort",
  { data_type => "integer", is_nullable => 0 },
  "url",
  { data_type => "varchar", is_nullable => 0, size => 512 },
  "thumb_url",
  { data_type => "varchar", is_nullable => 0, size => 512 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 slide_descriptions

Type: has_many

Related object: L<CAP::Schema::Result::SlideDescription>

=cut

__PACKAGE__->has_many(
  "slide_descriptions",
  "CAP::Schema::Result::SlideDescription",
  { "foreign.slide_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-09-11 16:26:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HAeKxVk70ht6/JWR4PeENQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
