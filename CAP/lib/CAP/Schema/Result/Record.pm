package CAP::Schema::Result::Record;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

CAP::Schema::Result::Record

=cut

__PACKAGE__->table("record");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 type

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 contributor

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 label

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 clabel

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 filename

  data_type: 'text'
  is_nullable: 1

=head2 md5

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "type",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "contributor",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "label",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "clabel",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "filename",
  { data_type => "text", is_nullable => 1 },
  "md5",
  { data_type => "varchar", is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-06-29 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nKVXEJvC1NRDf7W7lLZY3Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
