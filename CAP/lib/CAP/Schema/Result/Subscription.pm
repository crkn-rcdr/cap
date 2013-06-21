use utf8;
package CAP::Schema::Result::Subscription;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Subscription

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

=head1 TABLE: C<subscription>

=cut

__PACKAGE__->table("subscription");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 portal_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 completed

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 success

  data_type: 'tinyint'
  is_nullable: 1

=head2 product

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 discount_code

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 discount_amount

  data_type: 'decimal'
  is_nullable: 1
  size: [10,2]

=head2 old_expire

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 new_expire

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 old_level

  data_type: 'integer'
  is_nullable: 1

=head2 new_level

  data_type: 'integer'
  is_nullable: 1

=head2 payment_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 note

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "portal_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 64 },
  "completed",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "success",
  { data_type => "tinyint", is_nullable => 1 },
  "product",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "discount_code",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "discount_amount",
  { data_type => "decimal", is_nullable => 1, size => [10, 2] },
  "old_expire",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "new_expire",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "old_level",
  { data_type => "integer", is_nullable => 1 },
  "new_level",
  { data_type => "integer", is_nullable => 1 },
  "payment_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "note",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 payment_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Payment>

=cut

__PACKAGE__->belongs_to(
  "payment_id",
  "CAP::Schema::Result::Payment",
  { id => "payment_id" },
);

=head2 portal_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Portal>

=cut

__PACKAGE__->belongs_to(
  "portal_id",
  "CAP::Schema::Result::Portal",
  { id => "portal_id" },
);

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("user_id", "CAP::Schema::Result::User", { id => "user_id" });

=head2 users_discounts

Type: has_many

Related object: L<CAP::Schema::Result::UsersDiscounts>

=cut

__PACKAGE__->has_many(
  "users_discounts",
  "CAP::Schema::Result::UsersDiscounts",
  { "foreign.subscription_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-06-21 09:08:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rd/IFlDTTizpnCaFZOC4sQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
