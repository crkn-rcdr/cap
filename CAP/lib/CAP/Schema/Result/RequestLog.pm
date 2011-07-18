package CAP::Schema::Result::RequestLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::RequestLog

=cut

__PACKAGE__->table("request_log");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 time

  data_type: 'datetime'
  is_nullable: 0

=head2 session

  data_type: 'varchar'
  is_nullable: 0
  size: 40

=head2 session_count

  data_type: 'integer'
  is_nullable: 0

=head2 portal

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 view

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 action

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 status

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "time",
  { data_type => "datetime", is_nullable => 0 },
  "session",
  { data_type => "varchar", is_nullable => 0, size => 40 },
  "session_count",
  { data_type => "integer", is_nullable => 0 },
  "portal",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "view",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "action",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "status",
  { data_type => "integer", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 search_logs

Type: has_many

Related object: L<CAP::Schema::Result::SearchLog>

=cut

__PACKAGE__->has_many(
  "search_logs",
  "CAP::Schema::Result::SearchLog",
  { "foreign.request_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2011-06-17 12:27:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QzrBwtZ129wW9EqjgTefFQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
