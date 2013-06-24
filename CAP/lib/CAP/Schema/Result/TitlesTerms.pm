use utf8;
package CAP::Schema::Result::TitlesTerms;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::TitlesTerms

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

=head1 TABLE: C<titles_terms>

=cut

__PACKAGE__->table("titles_terms");

=head1 ACCESSORS

=head2 title_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 term_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "title_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "term_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</title_id>

=item * L</term_id>

=back

=cut

__PACKAGE__->set_primary_key("title_id", "term_id");

=head1 RELATIONS

=head2 term_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Terms>

=cut

__PACKAGE__->belongs_to("term_id", "CAP::Schema::Result::Terms", { id => "term_id" });

=head2 title_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Titles>

=cut

__PACKAGE__->belongs_to(
  "title_id",
  "CAP::Schema::Result::Titles",
  { id => "title_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-06-24 08:40:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ch1AupzheRsp4OFphxntbg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
