use utf8;
package CAP::Schema::Result::Terms;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Terms

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

=head1 TABLE: C<terms>

=cut

__PACKAGE__->table("terms");

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

=head2 titles_terms

Type: has_many

Related object: L<CAP::Schema::Result::TitlesTerms>

=cut

__PACKAGE__->has_many(
  "titles_terms",
  "CAP::Schema::Result::TitlesTerms",
  { "foreign.term_id" => "self.id" },
  undef,
);

=head2 title_ids

Type: many_to_many

Composing rels: L</titles_terms> -> title_id

=cut

__PACKAGE__->many_to_many("title_ids", "titles_terms", "title_id");


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-03-01 10:13:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UdTvrcC2p2NNnS2+8xQjOA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
