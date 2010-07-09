package CAP::Schema::Result::Validation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

CAP::Schema::Result::Validation

=cut

__PACKAGE__->table("validation");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 last_ts

  data_type: 'timestamp'
  default_value: CURRENT_TIMESTAMP
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "last_ts",
  {
    data_type     => "timestamp",
    default_value => \"CURRENT_TIMESTAMP",
    is_nullable   => 0,
  },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.06001 @ 2010-06-29 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:HHeWYxn/z27mj43i+zWTmw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
