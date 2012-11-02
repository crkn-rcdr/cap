package CAP::Schema::Result::Institution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::Institution

=cut

__PACKAGE__->table("institution");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 code

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 name

  data_type: 'varchar'
  default_value: 'New Institution'
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
  "code",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "name",
  {
    data_type => "varchar",
    default_value => "New Institution",
    is_nullable => 0,
    size => 128,
  },
  "subscriber",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("code", ["code"]);

=head1 RELATIONS

=head2 contributors

Type: has_many

Related object: L<CAP::Schema::Result::Contributor>

=cut

__PACKAGE__->has_many(
  "contributors",
  "CAP::Schema::Result::Contributor",
  { "foreign.institution_id" => "self.id" },
  {},
);

=head2 counter_logs

Type: has_many

Related object: L<CAP::Schema::Result::CounterLog>

=cut

__PACKAGE__->has_many(
  "counter_logs",
  "CAP::Schema::Result::CounterLog",
  { "foreign.institution_id" => "self.id" },
  {},
);

=head2 institution_alias

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionAlias>

=cut

__PACKAGE__->has_many(
  "institution_alias",
  "CAP::Schema::Result::InstitutionAlias",
  { "foreign.institution_id" => "self.id" },
  {},
);

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

=head2 institution_mgmts

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionMgmt>

=cut

__PACKAGE__->has_many(
  "institution_mgmts",
  "CAP::Schema::Result::InstitutionMgmt",
  { "foreign.institution_id" => "self.id" },
  {},
);

=head2 institution_subscriptions

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionSubscription>

=cut

__PACKAGE__->has_many(
  "institution_subscriptions",
  "CAP::Schema::Result::InstitutionSubscription",
  { "foreign.institution_id" => "self.id" },
  {},
);

=head2 request_logs

Type: has_many

Related object: L<CAP::Schema::Result::RequestLog>

=cut

__PACKAGE__->has_many(
  "request_logs",
  "CAP::Schema::Result::RequestLog",
  { "foreign.institution_id" => "self.id" },
  {},
);

=head2 stats_usage_institutions

Type: has_many

Related object: L<CAP::Schema::Result::StatsUsageInstitution>

=cut

__PACKAGE__->has_many(
  "stats_usage_institutions",
  "CAP::Schema::Result::StatsUsageInstitution",
  { "foreign.institution_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-11-02 08:56:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VxIkqQtJaSizgz4lIq/8FA

sub aliases {
    my $self = shift;
    my $aliases = {};
    foreach ($self->search_related('institution_alias')) {
        my $row = $_;
        $aliases->{ $row->lang } = $row->name;
    }
    return $aliases;
}

sub ip_addresses {
    my $self = shift;
    my $addresses = [];
    foreach ($self->search_related('institution_ipaddrs', undef, { order_by => { -asc => 'start' } })) {
        push(@{$addresses}, $_->cidr);
    }
    return $addresses;
}

sub set_alias {
    my ($self, $lang, $name) = @_;
    if ($name) {
        $self->update_or_create_related('institution_alias', { lang => $lang, name => $name });
    } else {
        $self->delete_related('institution_alias', { lang => $lang });
    }
}

# Return true if this institution subscribes to the current portal.
sub is_subscriber {
    my($self, $portal) = @_;
    my $subscriber = $self->search_related('institution_subscriptions', { portal_id => $portal->id })->count;
    return 1 if $subscriber;
    return 0;
}

sub portal_contributor {
    my ($self, $portal) = @_;
    my $entity = { id => $self->id, name => $self->name, portal => $portal };
    foreach($self->search_related('contributors', { portal_id => $portal })) {
        $entity->{$_->lang} = {url => $_->url, description => $_->description};
    }
    return $entity;
}


# You can replace this text with custom content, and it will be preserved on regeneration
1;
