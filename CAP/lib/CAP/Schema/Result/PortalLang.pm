package CAP::Schema::Result::PortalLang;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::PortalLang

=cut

__PACKAGE__->table("portal_lang");

=head1 ACCESSORS

=head2 portal_id

  data_type: 'varchar'
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 lang

  data_type: 'varchar'
  is_nullable: 0
  size: 2

=head2 priority

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "portal_id",
  { data_type => "varchar", is_foreign_key => 1, is_nullable => 0, size => 64 },
  "lang",
  { data_type => "varchar", is_nullable => 0, size => 2 },
  "priority",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->add_unique_constraint("portal_id", ["portal_id", "lang"]);

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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-11-02 08:56:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZsqeIwxs+pAS5Qo7o6nQMA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
