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

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::EncodedColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 TABLE: C<subscription>

=cut

__PACKAGE__->table("subscription");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
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

=head2 promo

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 oldexpire

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 newexpire

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 processor

  data_type: 'enum'
  extra: {list => ["paypal"]}
  is_nullable: 1

=head2 message

  data_type: 'text'
  is_nullable: 1

=head2 rcpt_amt

  data_type: 'decimal'
  default_value: 0.00
  is_nullable: 1
  size: [10,2]

=head2 rcpt_name

  data_type: 'text'
  is_nullable: 1

=head2 rcpt_no

  data_type: 'integer'
  is_nullable: 1

=head2 note

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
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
  "promo",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "oldexpire",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "newexpire",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "processor",
  { data_type => "enum", extra => { list => ["paypal"] }, is_nullable => 1 },
  "message",
  { data_type => "text", is_nullable => 1 },
  "rcpt_amt",
  {
    data_type => "decimal",
    default_value => "0.00",
    is_nullable => 1,
    size => [10, 2],
  },
  "rcpt_name",
  { data_type => "text", is_nullable => 1 },
  "rcpt_no",
  { data_type => "integer", is_nullable => 1 },
  "note",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<rcpt_no>

=over 4

=item * L</rcpt_no>

=back

=cut

__PACKAGE__->add_unique_constraint("rcpt_no", ["rcpt_no"]);

=head1 RELATIONS

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("user_id", "CAP::Schema::Result::User", { id => "user_id" });


# Created by DBIx::Class::Schema::Loader v0.07011 @ 2011-11-10 11:12:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+ILalmN6gptiVxUgb5GyVw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
