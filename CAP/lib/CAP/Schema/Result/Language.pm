use utf8;
package CAP::Schema::Result::Language;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Language

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

=head1 TABLE: C<language>

=cut

__PACKAGE__->table("language");

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

=head1 PRIMARY KEY

=over 4

=item * L</code>

=item * L</lang>

=back

=cut

__PACKAGE__->set_primary_key("code", "lang");


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-03-01 10:13:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ag/nbbyRADatjxWaZY0buQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
