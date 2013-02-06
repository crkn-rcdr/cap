use utf8;
package CAP::Schema::Result::Thesaurus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Thesaurus

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

=head1 TABLE: C<thesaurus>

=cut

__PACKAGE__->table("thesaurus");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 parent

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 term

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "parent",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "term",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 document_thesauruses

Type: has_many

Related object: L<CAP::Schema::Result::DocumentThesaurus>

=cut

__PACKAGE__->has_many(
  "document_thesauruses",
  "CAP::Schema::Result::DocumentThesaurus",
  { "foreign.thesaurus_id" => "self.id" },
  undef,
);

=head2 document_collections

Type: many_to_many

Composing rels: L</document_thesauruses> -> document_collection

=cut

__PACKAGE__->many_to_many(
  "document_collections",
  "document_thesauruses",
  "document_collection",
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-02-05 12:29:06
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HYfP89NFybqh1mDji2Qzig


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
