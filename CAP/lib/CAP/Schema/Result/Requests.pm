use utf8;
package CAP::Schema::Result::Requests;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Requests

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

=head1 TABLE: C<requests>

=cut

__PACKAGE__->table("requests");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 institution_id

  data_type: 'integer'
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

=head2 args

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "institution_id",
  { data_type => "integer", is_nullable => 1 },
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
  "args",
  { data_type => "varchar", is_nullable => 1, size => 256 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-09-18 09:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QUkv1FYuMctzgFFBCFMkNA


# We need to tell CAP that this table is not in the cap database.
__PACKAGE__->table("cap_log.requests");

1;
