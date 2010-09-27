package CAP::Schema::Result::Lexicon;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::Lexicon

=cut

__PACKAGE__->table("lexicon");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 language

  data_type: 'varchar'
  is_nullable: 1
  size: 15

=head2 path

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 message

  data_type: 'text'
  is_nullable: 1

=head2 value

  data_type: 'text'
  is_nullable: 1

=head2 notes

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "language",
  { data_type => "varchar", is_nullable => 1, size => 15 },
  "path",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "message",
  { data_type => "text", is_nullable => 1 },
  "value",
  { data_type => "text", is_nullable => 1 },
  "notes",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-09-27 12:33:52
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CjozzjlD4z7/9WDbX39ysA

__PACKAGE__->load_components('ForceUTF8');

# You can replace this text with custom content, and it will be preserved on regeneration
1;
