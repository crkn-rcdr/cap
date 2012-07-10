use utf8;
package CAP::Schema::Result::Role;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Role

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

=head1 TABLE: C<role>

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

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-07-10 10:31:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gZzjlJboYt7qrRRXEntIsw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
