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

=item * L<DBIx::Class::TimeStamp>

=item * L<DBIx::Class::EncodedColumn>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 TABLE: C<user_subscription>

=cut

__PACKAGE__->table("user_subscription");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 portal_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

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

=head2 last_updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "portal_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
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
  "last_updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
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

Related object: L<CAP::Schema::Result::Institution>

=cut

__PACKAGE__->belongs_to(
  "portal_id",
  "CAP::Schema::Result::Institution",
  { id => "portal_id" },
);

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Institution>

=cut

__PACKAGE__->belongs_to(
  "user_id",
  "CAP::Schema::Result::Institution",
  { id => "user_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2012-09-26 10:41:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KiPrvi/3YttuEd5codxEhQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
