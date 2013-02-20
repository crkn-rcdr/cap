package CAP::Schema::Result::Collection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::Collection

=cut

__PACKAGE__->table("collection");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 document_collections

Type: has_many

Related object: L<CAP::Schema::Result::DocumentCollection>

=cut

__PACKAGE__->has_many(
  "document_collections",
  "CAP::Schema::Result::DocumentCollection",
  { "foreign.collection" => "self.id" },
  {},
);

=head2 portal_collections

Type: has_many

Related object: L<CAP::Schema::Result::PortalCollection>

=cut

__PACKAGE__->has_many(
  "portal_collections",
  "CAP::Schema::Result::PortalCollection",
  { "foreign.collection_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-20 09:44:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:EJFXLms6kUWYNlKz/G1TwQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
