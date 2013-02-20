package CAP::Schema::Result::StatsUsagePortal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::StatsUsagePortal

=cut

__PACKAGE__->table("stats_usage_portal");

=head1 ACCESSORS

=head2 last_updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 month_starting

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 portal_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 searches

  data_type: 'integer'
  is_nullable: 1

=head2 sessions

  data_type: 'integer'
  is_nullable: 1

=head2 page_views

  data_type: 'integer'
  is_nullable: 1

=head2 requests

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "last_updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "month_starting",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 0 },
  "portal_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 64 },
  "searches",
  { data_type => "integer", is_nullable => 1 },
  "sessions",
  { data_type => "integer", is_nullable => 1 },
  "page_views",
  { data_type => "integer", is_nullable => 1 },
  "requests",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("month_starting", "portal_id");

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-20 09:44:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:USntPqjmuTj5Ur4ubOa4xA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
