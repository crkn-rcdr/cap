package CAP::Schema::Result::OutboundLink;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::OutboundLink

=cut

__PACKAGE__->table("outbound_link");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 portal_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 1
  size: 64

=head2 contributor

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 document

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 url

  data_type: 'varchar'
  is_nullable: 1
  size: 256

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "portal_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 64 },
  "contributor",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "document",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "url",
  { data_type => "varchar", is_nullable => 1, size => 256 },
);
__PACKAGE__->set_primary_key("id");

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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CgCkVEokUZ+kZpl4Yp+LfA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
