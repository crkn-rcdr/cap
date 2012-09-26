use utf8;
package CAP::Schema::Result::InstitutionAlias;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::InstitutionAlias

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

=head1 TABLE: C<institution_alias>

=cut

__PACKAGE__->table("institution_alias");

=head1 ACCESSORS

=head2 institution_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 lang

  data_type: 'varchar'
  is_nullable: 0
  size: 2

=head2 name

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "institution_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "lang",
  { data_type => "varchar", is_nullable => 0, size => 2 },
  "name",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</institution_id>

=item * L</lang>

=back

=cut

__PACKAGE__->set_primary_key("institution_id", "lang");

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


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2012-09-26 10:41:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IqddQWlMofG9G8CDDLmvzw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
