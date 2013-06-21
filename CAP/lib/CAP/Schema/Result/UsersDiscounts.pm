use utf8;
package CAP::Schema::Result::UsersDiscounts;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::UsersDiscounts

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

=head1 TABLE: C<users_discounts>

=cut

__PACKAGE__->table("users_discounts");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 discount_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 subscription_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "discount_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "subscription_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</discount_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "discount_id");

=head1 RELATIONS

=head2 discount_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Discounts>

=cut

__PACKAGE__->belongs_to(
  "discount_id",
  "CAP::Schema::Result::Discounts",
  { id => "discount_id" },
);

=head2 subscription_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Subscription>

=cut

__PACKAGE__->belongs_to(
  "subscription_id",
  "CAP::Schema::Result::Subscription",
  { id => "subscription_id" },
);

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Discounts>

=cut

__PACKAGE__->belongs_to(
  "user_id",
  "CAP::Schema::Result::Discounts",
  { id => "user_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-06-21 09:08:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tZPzc8RlMSF+YSnr5l3AWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
