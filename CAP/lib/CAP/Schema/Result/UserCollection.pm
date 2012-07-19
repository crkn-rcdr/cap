use utf8;
package CAP::Schema::Result::UserCollection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::UserCollection

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

=head1 TABLE: C<user_collection>

=cut

__PACKAGE__->table("user_collection");

=head1 ACCESSORS

=head2 collection_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 16

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 subscribed

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 expires

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "collection_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 16 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "subscribed",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "expires",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</collection_id>

=item * L</user_id>

=back

=cut

__PACKAGE__->set_primary_key("collection_id", "user_id");

=head1 RELATIONS

=head2 collection_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Collection>

=cut

__PACKAGE__->belongs_to(
  "collection_id",
  "CAP::Schema::Result::Collection",
  { id => "collection_id" },
);

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("user_id", "CAP::Schema::Result::User", { id => "user_id" });


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-07-19 10:34:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:UFJ5oDCI7o03y27kkQ17eg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
