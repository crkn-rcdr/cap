package CAP::Schema::Result::Portal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::Portal

=cut

__PACKAGE__->table("portal");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 enabled

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "enabled",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 contributors

Type: has_many

Related object: L<CAP::Schema::Result::Contributor>

=cut

__PACKAGE__->has_many(
  "contributors",
  "CAP::Schema::Result::Contributor",
  { "foreign.portal_id" => "self.id" },
  {},
);

=head2 portal_collections

Type: has_many

Related object: L<CAP::Schema::Result::PortalCollection>

=cut

__PACKAGE__->has_many(
  "portal_collections",
  "CAP::Schema::Result::PortalCollection",
  { "foreign.portal_id" => "self.id" },
  {},
);

=head2 portal_hosts

Type: has_many

Related object: L<CAP::Schema::Result::PortalHost>

=cut

__PACKAGE__->has_many(
  "portal_hosts",
  "CAP::Schema::Result::PortalHost",
  { "foreign.portal_id" => "self.id" },
  {},
);

=head2 portal_subscriptions

Type: has_many

Related object: L<CAP::Schema::Result::PortalSubscription>

=cut

__PACKAGE__->has_many(
  "portal_subscriptions",
  "CAP::Schema::Result::PortalSubscription",
  { "foreign.portal_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-10-15 16:37:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:deEUs95ZndRBrTgWPvnRSQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration

sub hosts {
    my $self = shift;
    my $hosts = [];
    foreach ($self->search_related('portal_hosts', undef, { order_by => 'id' })) {
        push(@{$hosts}, $_->id);
    }
    return $hosts;
}

sub collections {
    my $self = shift;
    my $collections = [];
    foreach($self->search_related('portal_collections', undef, { order_by => 'collection_id' })) {
        push(@{$collections}, { id => $_->collection_id, hosted => $_->hosted });
    }
    return $collections;
}
1;
