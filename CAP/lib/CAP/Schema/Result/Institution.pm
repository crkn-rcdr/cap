package CAP::Schema::Result::Institution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

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

=head2 user_subscription_user_ids

Type: has_many

Related object: L<CAP::Schema::Result::UserSubscription>

=cut

__PACKAGE__->has_many(
  "user_subscription_user_ids",
  "CAP::Schema::Result::UserSubscription",
  { "foreign.user_id" => "self.id" },
  {},
);

=head2 user_subscription_portal_ids

Type: has_many

Related object: L<CAP::Schema::Result::UserSubscription>

=cut

__PACKAGE__->has_many(
  "user_subscription_portal_ids",
  "CAP::Schema::Result::UserSubscription",
  { "foreign.portal_id" => "self.id" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-09-21 15:05:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jpHMnJrrf/XH7gaz/Vw4Gw

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


# You can replace this text with custom content, and it will be preserved on regeneration
1;
