use utf8;
package CAP::Schema::Result::Payment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Payment

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

=head1 TABLE: C<payment>

=cut

__PACKAGE__->table("payment");

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

=head2 completed

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 success

  data_type: 'tinyint'
  is_nullable: 1

=head2 amount

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 1
  size: [10,2]

=head2 description

  data_type: 'text'
  is_nullable: 1

=head2 returnto

  data_type: 'text'
  is_nullable: 1

=head2 foreignid

  data_type: 'integer'
  is_nullable: 1

=head2 token

  data_type: 'text'
  is_nullable: 1

=head2 message

  data_type: 'text'
  is_nullable: 1

=head2 processor

  data_type: 'enum'
  extra: {list => ["paypal"]}
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
  "completed",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "success",
  { data_type => "tinyint", is_nullable => 1 },
  "amount",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 1,
    size => [10, 2],
  },
  "description",
  { data_type => "text", is_nullable => 1 },
  "returnto",
  { data_type => "text", is_nullable => 1 },
  "foreignid",
  { data_type => "integer", is_nullable => 1 },
  "token",
  { data_type => "text", is_nullable => 1 },
  "message",
  { data_type => "text", is_nullable => 1 },
  "processor",
  { data_type => "enum", extra => { list => ["paypal"] }, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 subscriptions

Type: has_many

Related object: L<CAP::Schema::Result::Subscription>

=cut

__PACKAGE__->has_many(
  "subscriptions",
  "CAP::Schema::Result::Subscription",
  { "foreign.payment_id" => "self.id" },
  {},
);

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("user_id", "CAP::Schema::Result::User", { id => "user_id" });


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-10-05 11:16:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iV6VE2GhF/LsmNp08UEuhQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
