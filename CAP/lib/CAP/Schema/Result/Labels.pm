use utf8;
package CAP::Schema::Result::Labels;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Labels

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<labels>

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

=head1 PRIMARY KEY

=over 4

=item * L</field>

=item * L</code>

=item * L</lang>

=back

=cut

__PACKAGE__->set_primary_key("field", "code", "lang");


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-06-21 09:08:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uob7z6dSBKvQwGB54POs/A


# You can replace this text with custom content, and it will be preserved on regeneration
#__PACKAGE__->load_components('ForceUTF8');

1;
