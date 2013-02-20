package CAP::Schema::Result::StatsUsageInstitution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::StatsUsageInstitution

=cut

__PACKAGE__->table("stats_usage_institution");

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

=head2 institution_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

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
  "institution_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "searches",
  { data_type => "integer", is_nullable => 1 },
  "sessions",
  { data_type => "integer", is_nullable => 1 },
  "page_views",
  { data_type => "integer", is_nullable => 1 },
  "requests",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("month_starting", "institution_id");

=head1 RELATIONS

=head2 institution_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Institution>

=cut

__PACKAGE__->belongs_to(
  "institution_id",
  "CAP::Schema::Result::Institution",
  { id => "institution_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-20 09:44:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:KZVz7Sw77GO0ZUJHSN1qgA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
