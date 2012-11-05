use utf8;
package CAP::Schema::Result::PortalSubscription;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::PortalSubscription

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

=head1 TABLE: C<portal_subscription>

=cut

__PACKAGE__->table("portal_subscription");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 portal_id

  data_type: 'varchar'
  default_value: (empty string)
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 type

  data_type: 'enum'
  default_value: 'regular'
  extra: {list => ["trial","regular","permanent"]}
  is_nullable: 0

=head2 expires

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "portal_id",
  {
    data_type => "varchar",
    default_value => "",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 64,
  },
  "type",
  {
    data_type => "enum",
    default_value => "regular",
    extra => { list => ["trial", "regular", "permanent"] },
    is_nullable => 0,
  },
  "expires",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</portal_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "portal_id");

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


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2012-11-05 08:38:55
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/Dp0PgkBMDFW3uFLWbKjfg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
