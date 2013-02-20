package CAP::Schema::Result::CronLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::CronLog

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
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-20 09:44:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0roBWHh3wEXVeP6JfWNSzQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
