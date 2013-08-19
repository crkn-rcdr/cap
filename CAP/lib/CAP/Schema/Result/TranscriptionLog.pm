use utf8;
package CAP::Schema::Result::TranscriptionLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::TranscriptionLog

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

=head1 TABLE: C<transcription_log>

=cut

__PACKAGE__->table("transcription_log");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 transcriber_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 reviewer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 date

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 status

  data_type: 'enum'
  extra: {list => ["failed","passed","corrected"]}
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "transcriber_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "reviewer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "date",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "status",
  {
    data_type => "enum",
    extra => { list => ["failed", "passed", "corrected"] },
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-08-19 08:35:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:T78DX14cfop3nkrbuh9OQw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
