use utf8;
package CAP::Schema::Result::Thesauruses;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Thesauruses

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

=head1 TABLE: C<thesauruses>

=cut

__PACKAGE__->table("thesauruses");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 parent

  data_type: 'integer'
  is_nullable: 1

=head2 sortkey

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 term

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "parent",
  { data_type => "integer", is_nullable => 1 },
  "sortkey",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "term",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 titles_thesauruses

Type: has_many

Related object: L<CAP::Schema::Result::TitlesThesauruses>

=cut

__PACKAGE__->has_many(
  "titles_thesauruses",
  "CAP::Schema::Result::TitlesThesauruses",
  { "foreign.thesaurus_id" => "self.id" },
  undef,
);

=head2 title_ids

Type: many_to_many

Composing rels: L</titles_thesauruses> -> title_id

=cut

__PACKAGE__->many_to_many("title_ids", "titles_thesauruses", "title_id");


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-02-19 12:59:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IdVTqrUDiaGvo9ddL+/Dtg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
