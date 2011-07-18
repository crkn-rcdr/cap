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

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 16 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 groups_collections

Type: has_many

Related object: L<CAP::Schema::Result::GroupsCollection>

=cut

__PACKAGE__->has_many(
  "groups_collections",
  "CAP::Schema::Result::GroupsCollection",
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


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2011-06-20 08:08:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:i8NeusBhG83/97khEHSCsw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
