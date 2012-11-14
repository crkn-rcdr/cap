use utf8;
package CAP::Schema::Result::DocumentThesaurus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::DocumentThesaurus

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

=head1 TABLE: C<document_thesaurus>

=cut

__PACKAGE__->table("document_thesaurus");

=head1 ACCESSORS

=head2 contributor

  data_type: 'varchar'
  default_value: (empty string)
  is_foreign_key: 1
  is_nullable: 0
  size: 32

=head2 id

  data_type: 'varchar'
  default_value: (empty string)
  is_foreign_key: 1
  is_nullable: 0
  size: 128

=head2 thesaurus_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "contributor",
  {
    data_type => "varchar",
    default_value => "",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 32,
  },
  "id",
  {
    data_type => "varchar",
    default_value => "",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 128,
  },
  "thesaurus_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</contributor>

=item * L</id>

=item * L</thesaurus_id>

=back

=cut

__PACKAGE__->set_primary_key("contributor", "id", "thesaurus_id");

=head1 RELATIONS

=head2 document_collection

Type: belongs_to

Related object: L<CAP::Schema::Result::DocumentCollection>

=cut

__PACKAGE__->belongs_to(
  "document_collection",
  "CAP::Schema::Result::DocumentCollection",
  { contributor => "contributor", id => "id" },
);

=head2 thesaurus_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Thesaurus>

=cut

__PACKAGE__->belongs_to(
  "thesaurus_id",
  "CAP::Schema::Result::Thesaurus",
  { id => "thesaurus_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2012-11-14 08:53:57
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iQbNAJCdn5uMDoMQw01EiQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
