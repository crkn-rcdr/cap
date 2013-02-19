use utf8;
package CAP::Schema::Result::TitlesThesauruses;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::TitlesThesauruses

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

=head1 TABLE: C<titles_thesauruses>

=cut

__PACKAGE__->table("titles_thesauruses");

=head1 ACCESSORS

=head2 title_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 thesaurus_id

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
  "thesaurus_id",
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

=item * L</thesaurus_id>

=back

=cut

__PACKAGE__->set_primary_key("title_id", "thesaurus_id");

=head1 RELATIONS

=head2 thesaurus_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Thesauruses>

=cut

__PACKAGE__->belongs_to(
  "thesaurus_id",
  "CAP::Schema::Result::Thesauruses",
  { id => "thesaurus_id" },
);

=head2 title_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Titles>

=cut

__PACKAGE__->belongs_to(
  "title_id",
  "CAP::Schema::Result::Titles",
  { id => "title_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-02-19 12:59:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:OSCfOWjgtQsDfEIfwnWjig


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
