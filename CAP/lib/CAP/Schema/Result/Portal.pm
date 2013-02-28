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

=head2 view_all

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 view_limited

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 resize

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 download

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "enabled",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "view_all",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "view_limited",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "resize",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "download",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
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

=head2 institution_subscriptions

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionSubscription>

=cut

__PACKAGE__->has_many(
  "institution_subscriptions",
  "CAP::Schema::Result::InstitutionSubscription",
  { "foreign.portal_id" => "self.id" },
  undef,
);

=head2 outbound_links

Type: has_many

Related object: L<CAP::Schema::Result::OutboundLink>

=cut

__PACKAGE__->has_many(
  "outbound_links",
  "CAP::Schema::Result::OutboundLink",
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

=head2 portal_strings

Type: has_many

Related object: L<CAP::Schema::Result::PortalString>

=cut

__PACKAGE__->has_many(
  "portal_strings",
  "CAP::Schema::Result::PortalString",
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

=head2 portal_supports

Type: has_many

Related object: L<CAP::Schema::Result::PortalSupport>

=cut

__PACKAGE__->has_many(
  "portal_supports",
  "CAP::Schema::Result::PortalSupport",
  { "foreign.portal_id" => "self.id" },
  undef,
);

=head2 portals_titles

Type: has_many

Related object: L<CAP::Schema::Result::PortalsTitles>

=cut

__PACKAGE__->has_many(
  "portals_titles",
  "CAP::Schema::Result::PortalsTitles",
  { "foreign.portal_id" => "self.id" },
  undef,
);

=head2 stats_usage_portals

Type: has_many

Related object: L<CAP::Schema::Result::StatsUsagePortal>

=cut

__PACKAGE__->has_many(
  "stats_usage_portals",
  "CAP::Schema::Result::StatsUsagePortal",
  { "foreign.portal_id" => "self.id" },
  undef,
);

=head2 user_subscriptions

Type: has_many

Related object: L<CAP::Schema::Result::UserSubscription>

=cut

__PACKAGE__->has_many(
  "user_subscriptions",
  "CAP::Schema::Result::UserSubscription",
  { "foreign.portal_id" => "self.id" },
  undef,
);

=head2 institution_ids

Type: many_to_many

Composing rels: L</institution_subscriptions> -> institution_id

=cut

__PACKAGE__->many_to_many(
  "institution_ids",
  "institution_subscriptions",
  "institution_id",
);


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-02-28 09:20:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZduRZC3tN8E/G9chLxLvkA


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
        push(@{$collections}, { id => $_->get_column('collection_id'), hosted => $_->hosted });
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

# Returns the string associated with $label and $lang.
sub get_string {
    my($self, $label, $lang) = @_;
    my $result = $self->search_related('portal_strings', { label => $label, lang => $lang });
    return $result->first->string if ($result->count);
    return ("[UNDEFINED $label-$lang]");

}

# Return true if at least one of the collection fields in $doc's record
# matches a hosted collection for this portal.
sub hosts_doc {
    my($self, $doc) = @_;
    foreach my $hosted ($self->search_related('portal_collections', { hosted => 1 })) {
        foreach my $collection (@{$doc->record->collection}) {
            if ($collection eq $hosted->collection_id->id) {
                return 1;
            }
        }
    }
    return 0;
}

# Return true if the portal has the named support page.
sub has_page {
    my($self, $page) = @_;
    my $result = $self->search_related('portal_supports', { page => $page });
    warn $result->count . " for " . $page;
    return 1 if $result->count;
    return 0;
}

sub subset {
    my $self = shift;
    my @result = $self->search_related('portal_collections')->get_column('collection_id')->all;
    my @subset = ();
    foreach my $collection (@result) {
        push(@subset, "collection:$collection");
    }

    # TODO: eventually, this will be the only thing we need to return.
    push(@subset, "portal:" . $self->id);

    return "" unless (@subset);
    return "(" . join(" OR ", @subset) . ")";
}

1;
