use utf8;
package CAP::Schema::Result::PortalCollection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::PortalCollection

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

=head1 TABLE: C<portal_collection>

=cut

__PACKAGE__->table("portal_collection");

=head1 ACCESSORS

=head2 portal_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 1
  size: 64

=head2 collection_id

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "portal_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 1, size => 64 },
  "collection_id",
  { data_type => "varchar", is_nullable => 1, size => 32 },
);

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


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-07-11 10:18:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:TRhd+OeYOJkL7BnqYsqXVw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
