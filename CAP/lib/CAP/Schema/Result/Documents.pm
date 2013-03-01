use utf8;
package CAP::Schema::Result::Documents;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Documents

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

=head1 TABLE: C<documents>

=cut

__PACKAGE__->table("documents");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 identifier

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 sequence

  accessor: 'column_sequence'
  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=head2 label

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "identifier",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "sequence",
  {
    accessor      => "column_sequence",
    data_type     => "integer",
    default_value => 1,
    is_nullable   => 1,
  },
  "label",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 pages

Type: has_many

Related object: L<CAP::Schema::Result::Pages>

=cut

__PACKAGE__->has_many(
  "pages",
  "CAP::Schema::Result::Pages",
  { "foreign.document_id" => "self.id" },
  undef,
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


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-03-01 13:09:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jzVWfZECTP6C5Kbpfd0+8A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;