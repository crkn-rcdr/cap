use utf8;
package CAP::Schema::Result::PortalsTitles;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::PortalsTitles

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

=head1 TABLE: C<portals_titles>

=cut

__PACKAGE__->table("portals_titles");

=head1 ACCESSORS

=head2 portal_id

  data_type: 'varchar'
  default_value: (empty string)
  is_foreign_key: 1
  is_nullable: 0
  size: 64

=head2 title_id

  data_type: 'integer'
  default_value: 0
  is_foreign_key: 1
  is_nullable: 0

=head2 hosted

  data_type: 'tinyint'
  is_nullable: 1

=head2 updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "portal_id",
  {
    data_type => "varchar",
    default_value => "",
    is_foreign_key => 1,
    is_nullable => 0,
    size => 64,
  },
  "title_id",
  {
    data_type      => "integer",
    default_value  => 0,
    is_foreign_key => 1,
    is_nullable    => 0,
  },
  "hosted",
  { data_type => "tinyint", is_nullable => 1 },
  "updated",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</portal_id>

=item * L</title_id>

=back

=cut

__PACKAGE__->set_primary_key("portal_id", "title_id");

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

=head2 title_id

Type: belongs_to

Related object: L<CAP::Schema::Result::Titles>

=cut

__PACKAGE__->belongs_to(
  "title_id",
  "CAP::Schema::Result::Titles",
  { id => "title_id" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-03-02 17:39:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:h71WCoDe5O4pyOwUxBG/eA



=head2 identifier

Returns the $contributior.$local_id unique identifier

=cut
sub identifier {
    my($self, $c) = @_;
    my $contributor = $self->title_id->institution_id->code;
    my $identifier = $self->title_id->identifier;
    return join('.', $contributor, $identifier);
}

1;
