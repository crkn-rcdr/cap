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
  default_value: (empty string)
  is_nullable: 0
  size: 64

=head2 enabled

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 supports_users

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 supports_subscriptions

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 supports_institutions

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=head2 updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 64 },
  "enabled",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "supports_users",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "supports_subscriptions",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
  "supports_institutions",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
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

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

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


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2015-03-02 17:39:42
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZkQyvH7hRWOhLFC81bl7cA


=head2 title($lang)

Returns the title of the portal in $lang.

=cut
sub title {
    my($self, $lang) = @_;
    return '[[UNDEFINED]]' unless ($lang);
    my $result = $self->related_resultset('portal_langs')->find({ lang => $lang });
    return $result->title if ($result);
    return '[[UNDEFINED]]';
}


=head2 description($lang)

Returns the description of the portal for $lang.

=cut
sub description {
    my($self, $lang) = @_;
    return "" unless ($lang);
    my $result = $self->related_resultset('portal_langs')->find({ lang => $lang });
    return $result->description if ($result);
    return "";
}

=head2 features

Returns a set of hash keys (with values set to 1) for each feature in this portal

=cut
sub features {
    my($self) = @_;
    my $features = {};
    my $result = $self->search_related('portal_features');
    while (my $feature = $result->next) {
        $features->{$feature->feature} = 1;
    }
    return $features;
}

=head2

Returns matching rows from the portal_lang table.

=cut
sub get_languages {
    my($self) =@_;
    return $self->search_related('portal_langs');
}


=head2 set_language($lang, $priority, $title, $description)

Creates or updates the portal_lang with the listed characteristics

=cut
sub set_language {
    my($self, $lang, $priority, $title, $description) = @_;
    $self->related_resultset('portal_langs')->update_or_create({
        lang        => $lang,
        priority    => $priority,
        title       => $title,
        description => $description
    })
}

=head2 canonical_hostname ($hostname)

Returns the canonical hostname for the portal, or undef if there isn't
one. If $hostname is provided (and exists), it is made the new canonical
hostname.

=cut
sub canonical_hostname {
    my($self, $hostname) = @_;
    my $canonical = $self->find_related('portal_hosts', { canonical => 1 });

    if ($hostname) {
        my $new_canonical =  $self->find_related('portal_hosts', { id => $hostname });
        if ($new_canonical) {
            if ($canonical) {
                $canonical->update({ canonical => undef });
            }
            $new_canonical->update({ canonical => 1 });
            return $new_canonical;
        }
    }
    else {
        return undef unless ($canonical);
        return $canonical->id;
    }
}


=head2 hosts

Return the hostnames for the portal

=cut
sub hosts {
    my $self = shift;
    my @hosts = $self->search_related('portal_hosts', undef, { order_by => 'id' })->all;
    return @hosts if (wantarray);
    return \@hosts;
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

1;
