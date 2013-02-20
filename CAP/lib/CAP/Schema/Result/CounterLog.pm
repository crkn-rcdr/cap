package CAP::Schema::Result::CounterLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::CounterLog

=cut

__PACKAGE__->table("counter_log");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 institution_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 document

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "institution_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "document",
  { data_type => "varchar", is_nullable => 0, size => 128 },
);
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-20 09:44:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ttr+omMSIFTjXDN83sfYtg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
