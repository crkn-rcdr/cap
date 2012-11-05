use utf8;
package CAP::Schema::Result::UserRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::UserRole

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

=head1 TABLE: C<user_role>

=cut

__PACKAGE__->table("user_role");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 role_id

  data_type: 'varchar'
  default_value: (empty string)
  is_foreign_key: 1
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "user_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "role_id",
  {
    data_type => "varchar",
    default_value => "",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 32,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</role_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "role_id");

=head1 RELATIONS

=head2 role_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Role>

=cut

__PACKAGE__->belongs_to("role_id", "CAP::Schema::Result::Role", { id => "role_id" });

=head2 user_id

Type: belongs_to

Related object: L<CAP::Schema::Result::User>

=cut

__PACKAGE__->belongs_to("user_id", "CAP::Schema::Result::User", { id => "user_id" });


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2012-11-05 08:38:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0fP9IJRTKZfvepLDz1izTw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
