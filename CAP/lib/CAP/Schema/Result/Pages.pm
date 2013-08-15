use utf8;
package CAP::Schema::Result::Pages;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Pages

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

=head1 TABLE: C<pages>

=cut

__PACKAGE__->table("pages");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 document_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 sequence

  accessor: 'column_sequence'
  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=head2 label

  data_type: 'text'
  is_nullable: 1

=head2 transcription_user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 review_user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 transcription_status

  data_type: 'enum'
  default_value: 'not_transcribed'
  extra: {list => ["not_transcribed","locked_for_transcription","awaiting_review","locked_for_review","transcribed","transcribed_with_corrections"]}
  is_nullable: 0

=head2 transcription

  data_type: 'text'
  is_nullable: 1

=head2 type

  data_type: 'enum'
  default_value: 'unknown'
  extra: {list => ["unknown","control","single_page","start_page","end_page","middle_page"]}
  is_nullable: 0

=head2 updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "document_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "sequence",
  {
    accessor      => "column_sequence",
    data_type     => "integer",
    default_value => 1,
    is_nullable   => 1,
  },
  "label",
  { data_type => "text", is_nullable => 1 },
  "transcription_user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "review_user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "transcription_status",
  {
    data_type => "enum",
    default_value => "not_transcribed",
    extra => {
      list => [
        "not_transcribed",
        "locked_for_transcription",
        "awaiting_review",
        "locked_for_review",
        "transcribed",
        "transcribed_with_corrections",
      ],
    },
    is_nullable => 0,
  },
  "transcription",
  { data_type => "text", is_nullable => 1 },
  "type",
  {
    data_type => "enum",
    default_value => "unknown",
    extra => {
      list => [
        "unknown",
        "control",
        "single_page",
        "start_page",
        "end_page",
        "middle_page",
      ],
    },
    is_nullable => 0,
  },
  "updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 document_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Documents>

=cut

__PACKAGE__->belongs_to(
  "document_id",
  "CAP::Schema::Result::Documents",
  { id => "document_id" },
);

=head2 review_user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "review_user_id",
  "CAP::Schema::Result::User",
  { id => "review_user_id" },
);

=head2 transcription_user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "transcription_user_id",
  "CAP::Schema::Result::User",
  { id => "transcription_user_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-08-15 09:34:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NTPavlngsdoLpMtfy0DnEw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
