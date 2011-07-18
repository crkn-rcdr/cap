package CAP::Schema::Result::UserDocument;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::UserDocument

=cut

__PACKAGE__->table("user_document");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 document

  data_type: 'varchar'
  is_nullable: 0
  size: 160

=head2 acquired

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "document",
  { data_type => "varchar", is_nullable => 0, size => 160 },
  "acquired",
  { data_type => "datetime", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("user_id", "document");

=head1 RELATIONS

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("user_id", "CAP::Schema::Result::User", { id => "user_id" });


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2011-06-20 15:21:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jmnjMm+i41irXB00E4C2ow


# You can replace this text with custom content, and it will be preserved on regeneration
1;
