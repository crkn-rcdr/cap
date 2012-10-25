use utf8;
package CAP::Schema::Result::Portal;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Portal

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

=head1 TABLE: C<portal>

=cut

__PACKAGE__->table("portal");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 enabled

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "enabled",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

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
  undef,
);

=head2 portal_collections

Type: has_many

Related object: L<CAP::Schema::Result::PortalCollection>

=cut

__PACKAGE__->has_many(
  "portal_collections",
  "CAP::Schema::Result::PortalCollection",
  { "foreign.portal_id" => "self.id" },
  undef,
);

=head2 portal_features

Type: has_many

Related object: L<CAP::Schema::Result::PortalFeature>

=cut

__PACKAGE__->has_many(
  "portal_features",
  "CAP::Schema::Result::PortalFeature",
  { "foreign.portal_id" => "self.id" },
  undef,
);

=head2 portal_hosts

Type: has_many

Related object: L<CAP::Schema::Result::PortalHost>

=cut

__PACKAGE__->has_many(
  "portal_hosts",
  "CAP::Schema::Result::PortalHost",
  { "foreign.portal_id" => "self.id" },
  undef,
);

=head2 portal_langs

Type: has_many

Related object: L<CAP::Schema::Result::PortalLang>

=cut

__PACKAGE__->has_many(
  "portal_langs",
  "CAP::Schema::Result::PortalLang",
  { "foreign.portal_id" => "self.id" },
  undef,
);

=head2 portal_subscriptions

Type: has_many

Related object: L<CAP::Schema::Result::PortalSubscription>

=cut

__PACKAGE__->has_many(
  "portal_subscriptions",
  "CAP::Schema::Result::PortalSubscription",
  { "foreign.portal_id" => "self.id" },
  undef,
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2012-10-24 09:02:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lfQTM4GjwD9iaF/UpTDKBQ


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

# Get the default language for the portal, if none is specified. This is
# based on the value of the priority column.
sub default_lang {
    my $self = shift;
    my $result = $self->search_related('portal_langs', undef, { order_by => { -desc => 'priority' }});
    return $result->first->lang if ($result->count);
    return undef;
}

sub has_feature {
    my($self, $feature) = @_;
    my $result = $self->search_related('portal_features', { feature => $feature });
    return 1 if ($result->count);
    return 0;
}

# Return true/false depending on whether $lang is supported by this
# portal.
sub supports_lang {
    my($self, $lang) = @_;
    return $self->search_related('portal_langs', { lang => $lang })->count;
}

# Return an arrayref of languages supported by this portal.
sub langs {
    my $self = shift;
    my $langs = [];
    foreach ($self->search_related('portal_langs', undef, { order_by => 'lang' })) {
        push(@{$langs}, $_->lang);
    }
    return $langs;
}

# Return true if at least one of the collection fields in $doc's record
# matches a hosted collection for this portal.
sub hosts_doc {
    my($self, $doc) = @_;
    foreach my $hosted ($self->search_related('portal_collections', { hosted => 1 })) {
        foreach my $collection (@{$doc->record->collection}) {
            if ($collection eq $hosted->collection_id) {
                return 1;
            }
        }
    }
    return 0;
}

1;
