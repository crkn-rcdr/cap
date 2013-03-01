use utf8;
package CAP::Schema::Result::UserSubscription;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::UserSubscription

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

=head1 TABLE: C<user_subscription>

=cut

__PACKAGE__->table("user_subscription");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 portal_id

  data_type: 'varchar'
  default_value: (empty string)
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 expires

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 permanent

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 reminder_sent

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 expiry_logged

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 last_updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 level

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "portal_id",
  {
    data_type => "varchar",
    default_value => "",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 64,
  },
  "expires",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "permanent",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "reminder_sent",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "expiry_logged",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "last_updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "level",
  { data_type => "integer", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</portal_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "portal_id");

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

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("user_id", "CAP::Schema::Result::User", { id => "user_id" });


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-03-01 10:13:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:miNwmuGpZZeep6v6Bf4cBg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
