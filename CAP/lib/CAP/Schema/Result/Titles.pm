use utf8;
package CAP::Schema::Result::Titles;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Titles

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

=head1 TABLE: C<titles>

=cut

__PACKAGE__->table("titles");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 institution_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 identifier

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 label

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "institution_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "identifier",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "label",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<institution_id>

=over 4

=item * L</institution_id>

=item * L</identifier>

=back

=cut

__PACKAGE__->add_unique_constraint("institution_id", ["institution_id", "identifier"]);

=head1 RELATIONS

=head2 documents

Type: has_many

Related object: L<CAP::Schema::Result::Documents>

=cut

__PACKAGE__->has_many(
  "documents",
  "CAP::Schema::Result::Documents",
  { "foreign.title_id" => "self.id" },
  undef,
);

=head2 institution_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Institution>

=cut

__PACKAGE__->belongs_to(
  "institution_id",
  "CAP::Schema::Result::Institution",
  { id => "institution_id" },
);

=head2 portals_titles

Type: has_many

Related object: L<CAP::Schema::Result::PortalsTitles>

=cut

__PACKAGE__->has_many(
  "portals_titles",
  "CAP::Schema::Result::PortalsTitles",
  { "foreign.title_id" => "self.id" },
  undef,
);

=head2 titles_terms

Type: has_many

Related object: L<CAP::Schema::Result::TitlesTerms>

=cut

__PACKAGE__->has_many(
  "titles_terms",
  "CAP::Schema::Result::TitlesTerms",
  { "foreign.title_id" => "self.id" },
  undef,
);

=head2 term_ids

Type: many_to_many

Composing rels: L</titles_terms> -> term_id

=cut

__PACKAGE__->many_to_many("term_ids", "titles_terms", "term_id");


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-03-01 13:09:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NlO7lTSoYiw29eK0XU8cdQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
