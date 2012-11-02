package CAP::Schema::Result::Labels;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::Labels

=cut

__PACKAGE__->table("labels");

=head1 ACCESSORS

=head2 field

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 code

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 32

=head2 lang

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 2

=head2 label

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=cut

__PACKAGE__->add_columns(
  "field",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "code",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "lang",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 2 },
  "label",
  { data_type => "varchar", is_nullable => 1, size => 128 },
);
__PACKAGE__->set_primary_key("field", "code", "lang");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-11-02 08:56:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yGpvNUZwPYLQZoV5hz30/w


# You can replace this text with custom content, and it will be preserved on regeneration
#__PACKAGE__->load_components('ForceUTF8');

1;
