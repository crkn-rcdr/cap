use utf8;
package CAP::Schema::Result::SearchLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::SearchLog

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

=head1 TABLE: C<search_log>

=cut

__PACKAGE__->table("search_log");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 request_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 query

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=head2 results

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "request_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "query",
  { data_type => "varchar", is_nullable => 1, size => 256 },
  "results",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 request_id

Type: belongs_to

Related object: L<CAP::Schema::Result::RequestLog>

=cut

__PACKAGE__->belongs_to(
  "request_id",
  "CAP::Schema::Result::RequestLog",
  { id => "request_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-03-02 15:51:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:D1xqv3y9oKw7HyBqGPtpTA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
