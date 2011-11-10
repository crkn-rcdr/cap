use utf8;
package CAP::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::User

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

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 token

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 confirmed

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 admin

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 lastseen

  data_type: 'integer'
  is_nullable: 0

=head2 credits

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 subexpires

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "token",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "confirmed",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "admin",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "lastseen",
  { data_type => "integer", is_nullable => 0 },
  "credits",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "subexpires",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<username>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username", ["username"]);

=head1 RELATIONS

=head2 subscriptions

Type: has_many

Related object: L<CAP::Schema::Result::Subscription>

=cut

__PACKAGE__->has_many(
  "subscriptions",
  "CAP::Schema::Result::Subscription",
  { "foreign.user_id" => "self.id" },
  {},
);

=head2 user_collections

Type: has_many

Related object: L<CAP::Schema::Result::UserCollection>

=cut

__PACKAGE__->has_many(
  "user_collections",
  "CAP::Schema::Result::UserCollection",
  { "foreign.user_id" => "self.id" },
  {},
);

=head2 user_documents

Type: has_many

Related object: L<CAP::Schema::Result::UserDocument>

=cut

__PACKAGE__->has_many(
  "user_documents",
  "CAP::Schema::Result::UserDocument",
  { "foreign.user_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07011 @ 2011-11-10 11:12:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JYFvy7f8rbn3w/H6wO99HA


# You can replace this text with custom content, and it will be preserved on regeneration

#__PACKAGE__->load_components('ForceUTF8');
__PACKAGE__->add_columns(
    'password' => {
        data_type => 'VARCHAR',
        size => 40 + 10,
        encode_column => 1,
        encode_class => 'Digest',
        encode_args => { algorithm => 'SHA-1', format => 'hex', salt_length => 10 },
        encode_check_method => 'check_password',
    } 
);

__PACKAGE__->has_many(map_user_roles => 'CAP::Schema::Result::UserRole', 'user_id');
__PACKAGE__->many_to_many(roles => 'map_user_roles', 'role');


1;
