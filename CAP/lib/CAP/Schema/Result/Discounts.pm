use utf8;
package CAP::Schema::Result::Discounts;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Discounts

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

=head1 TABLE: C<discounts>

=cut

__PACKAGE__->table("discounts");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 code

  data_type: 'varchar'
  is_nullable: 0
  size: 16

=head2 portal_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 1
  size: 64

=head2 percentage

  data_type: 'integer'
  is_nullable: 1

=head2 expires

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "code",
  { data_type => "varchar", is_nullable => 0, size => 16 },
  "portal_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 64 },
  "percentage",
  { data_type => "integer", is_nullable => 1 },
  "expires",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "description",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<code>

=over 4

=item * L</code>

=back

=cut

__PACKAGE__->add_unique_constraint("code", ["code"]);

=head1 RELATIONS

=head2 portal_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Portal>

=cut

__PACKAGE__->belongs_to(
  "portal_id",
  "CAP::Schema::Result::Portal",
  { id => "portal_id" },
);

=head2 users_discounts_discount_ids

Type: has_many

Related object: L<CAP::Schema::Result::UsersDiscounts>

=cut

__PACKAGE__->has_many(
  "users_discounts_discount_ids",
  "CAP::Schema::Result::UsersDiscounts",
  { "foreign.discount_id" => "self.id" },
  undef,
);

=head2 users_discounts_user_ids

Type: has_many

Related object: L<CAP::Schema::Result::UsersDiscounts>

=cut

__PACKAGE__->has_many(
  "users_discounts_user_ids",
  "CAP::Schema::Result::UsersDiscounts",
  { "foreign.user_id" => "self.id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-06-24 08:40:53
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KK67y4K+oeOyo0jeL0AKlg


=head2 active

Returns true if the discount code has not yet expired

=cut
sub active {
    my($self) = @_;
    return 1 if DateTime->compare(DateTime->now(), $self->expires) != 1;
    return 0;
}

1;
