package CAP::Schema::Result::Info;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::Info

=cut

__PACKAGE__->table("info");

=head1 ACCESSORS

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 value

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "name",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "value",
  { data_type => "varchar", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("name");


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2011-08-04 13:16:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3+Om8VGvdpWf0+xa0eH4yA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
