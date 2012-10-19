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
  size: 16

=head2 price

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "price",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 institution_collections

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionCollection>

=cut

__PACKAGE__->has_many(
  "institution_collections",
  "CAP::Schema::Result::InstitutionCollection",
  { "foreign.collection_id" => "self.id" },
  {},
);

=head2 user_collections

Type: has_many

Related object: L<CAP::Schema::Result::UserCollection>

=cut

__PACKAGE__->has_many(
  "user_collections",
  "CAP::Schema::Result::UserCollection",
  { "foreign.collection_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-10-15 16:37:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9SPspbgEgo+FEAiH9XZ8lg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
