use utf8;
package CAP::Schema::Result::CronLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::CronLog

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

=head1 TABLE: C<cron_log>

=cut

__PACKAGE__->table("cron_log");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 completed

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 action

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 ok

  data_type: 'tinyint'
  is_nullable: 1

=head2 message

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "completed",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "action",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "ok",
  { data_type => "tinyint", is_nullable => 1 },
  "message",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2012-10-24 09:02:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8AkOVnHMyH8cYoLZ3lnQxQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
