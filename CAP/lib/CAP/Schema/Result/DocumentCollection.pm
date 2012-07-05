use utf8;
package CAP::Schema::Result::DocumentCollection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::DocumentCollection

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

=head1 TABLE: C<document_collection>

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

=head1 PRIMARY KEY

=over 4

=item * L</contributor>

=item * L</id>

=item * L</collection>

=back

=cut

__PACKAGE__->set_primary_key("contributor", "id", "collection");


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-07-05 13:24:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gGsKIXzoTNBPigOV/o6iqQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;