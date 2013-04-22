use utf8;
package CAP::Schema::Result::UserLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::UserLog

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

=head1 TABLE: C<user_log>

=cut

__PACKAGE__->table("user_log");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 date

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 event

  data_type: 'enum'
  extra: {list => ["CREATED","CONFIRMED","TRIAL_START","TRIAL_END","SUB_START","SUB_END","LOGIN","LOGOUT","RESTORE_SESSION","PASSWORD_CHANGED","USERNAME_CHANGED","NAME_CHANGED","LOGIN_FAILED","REMINDER_SENT","RESET_REQUEST"]}
  is_nullable: 1

=head2 info

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "date",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "event",
  {
    data_type => "enum",
    extra => {
      list => [
        "CREATED",
        "CONFIRMED",
        "TRIAL_START",
        "TRIAL_END",
        "SUB_START",
        "SUB_END",
        "LOGIN",
        "LOGOUT",
        "RESTORE_SESSION",
        "PASSWORD_CHANGED",
        "USERNAME_CHANGED",
        "NAME_CHANGED",
        "LOGIN_FAILED",
        "REMINDER_SENT",
        "RESET_REQUEST",
      ],
    },
    is_nullable => 1,
  },
  "info",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-04-22 14:33:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6dHBoalj+RQwBWWHI2dmbQ


# We need to tell CAP that this table is not in the cap database.
__PACKAGE__->table("cap_log.user_log");

1;
