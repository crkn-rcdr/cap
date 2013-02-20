package CAP::Schema::Result::MediaType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::MediaType

=cut

__PACKAGE__->table("media_type");

=head1 ACCESSORS

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
  "code",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 32 },
  "lang",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 2 },
  "label",
  { data_type => "varchar", is_nullable => 1, size => 128 },
);
__PACKAGE__->set_primary_key("code", "lang");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-20 09:44:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GJOdmaQkurREPbExkAmR3Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
