use utf8;
package CAP::Schema::Result::Institution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Institution

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

=head1 TABLE: C<institution>

=cut

__PACKAGE__->table("institution");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 subscriber

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "subscriber",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 institution_collections

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionCollection>

=cut

__PACKAGE__->has_many(
  "institution_collections",
  "CAP::Schema::Result::InstitutionCollection",
  { "foreign.institution_id" => "self.id" },
  {},
);

=head2 institution_ipaddrs

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionIpaddr>

=cut

__PACKAGE__->has_many(
  "institution_ipaddrs",
  "CAP::Schema::Result::InstitutionIpaddr",
  { "foreign.institution_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07011 @ 2011-11-10 11:12:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ckwXaoSaeZouQGom4oq5AQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
