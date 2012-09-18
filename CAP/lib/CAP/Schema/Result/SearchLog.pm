package CAP::Schema::Result::SearchLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

CAP::Schema::Result::SearchLog

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-09-11 16:26:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Xhfd1d4F1zIFe8pEo8Kphw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
