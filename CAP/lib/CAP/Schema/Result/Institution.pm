use utf8;
package CAP::Schema::Result::Institution;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::Institution

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

=head1 TABLE: C<institution>

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

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<code>

=over 4

=item * L</code>

=back

=cut

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

=head2 institution_roles

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionRole>

=cut

__PACKAGE__->has_many(
  "institution_roles",
  "CAP::Schema::Result::InstitutionRole",
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


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2012-07-05 13:24:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QZUZCFvn24S3wuIq1yao7A

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
