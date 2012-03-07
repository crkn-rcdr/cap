use utf8;
package CAP::Schema::Result::RequestLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::RequestLog

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

=head1 TABLE: C<request_log>

=cut

__PACKAGE__->table("request_log");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 institution_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 time

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
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

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "institution_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "time",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
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
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

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

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("user_id", "CAP::Schema::Result::User", { id => "user_id" });


# Created by DBIx::Class::Schema::Loader v0.07011 @ 2012-03-07 08:14:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:l1iTc9bVVfClGUr4SWpswg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
