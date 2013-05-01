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


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-03-01 13:09:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Tt5lajeKpvw6uxUbj+uBrQ

=head2 active

Returns true if the subscription is currently active

=cut
sub active {
    my($self) = @_;
    return 1 if $self->permanent;
    return 1 if DateTime->compare(DateTime->now(), $self->expires) != 1;
    return 0;
}


=head2 calculate_expiry ($duration)

Calculate an expiry date of DateTime::Duration $duration  from either now
(if the subscription has expired) or from the current expiry date.

=cut
sub calculate_expiry {
    my($self, $duration) = @_;
    my $now = DateTime->now();
    my $expires = $self->expires;

    if (DateTime->compare($now, $self->expires) != 1) {
        return $self->expires->clone->add_duration($duration);
    }
    else {
        return $now->add_duration($duration);
    }
}


=head2 expires_within ($days)

Returns true if the subscription will expire within $days from now

=cut
sub expires_within {
    my($self, $days) = @_;
    my $boundary = DateTime->now()->add({ days => $days });
    warn "HI";
    warn $boundary->ymd;
    return 1 if DateTime->compare($self->expires, $boundary) != 1;
}



1;
