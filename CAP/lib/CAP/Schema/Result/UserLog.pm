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

=head1 RELATIONS

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("user_id", "CAP::Schema::Result::User", { id => "user_id" });


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-03-01 13:09:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Dg3Datj8czWNH74ZP8FEyQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration

1;
