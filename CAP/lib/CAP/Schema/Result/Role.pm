package CAP::Schema::Result::Role;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::Role

=cut

__PACKAGE__->table("role");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 user_roles

Type: has_many

Related object: L<CAP::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "CAP::Schema::Result::UserRole",
  { "foreign.role_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-20 09:44:25
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:x7jcHeUtT9zD9lAzpvwFaA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
