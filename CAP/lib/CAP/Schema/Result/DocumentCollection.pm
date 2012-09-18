package CAP::Schema::Result::DocumentCollection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

CAP::Schema::Result::DocumentCollection

=cut

__PACKAGE__->table("document_collection");

=head1 ACCESSORS

=head2 contributor

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 id

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 128

=head2 collection

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "contributor",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "id",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 128 },
  "collection",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("contributor", "id", "collection");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-09-11 16:26:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BXU+1qHdg002eMN7a6cjxA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
