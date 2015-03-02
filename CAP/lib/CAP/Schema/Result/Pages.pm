use utf8;
package CAP::Schema::Result::Pages;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Pages

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

=head1 TABLE: C<pages>

=cut

__PACKAGE__->table("pages");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 document_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sequence

  accessor: 'column_sequence'
  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=head2 label

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "document_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sequence",
  {
    accessor      => "column_sequence",
    data_type     => "integer",
    default_value => 1,
    is_nullable   => 1,
  },
  "label",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 document_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Documents>

=cut

__PACKAGE__->belongs_to(
  "document_id",
  "CAP::Schema::Result::Documents",
  { id => "document_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-03-02 15:51:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6kmXqWqGzNvrzaLD53fGcw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
