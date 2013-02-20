package CAP::Schema::Result::Pages;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::Pages

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
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "document_id",
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
  { data_type => "text", is_nullable => 1 },
);
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-20 09:44:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fwKFLl+DcCMbhaIzLt0x7Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
