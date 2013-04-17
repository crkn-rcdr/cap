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

=head2 contributors

Type: has_many

Related object: L<CAP::Schema::Result::Contributor>

=cut

__PACKAGE__->has_many(
  "contributors",
  "CAP::Schema::Result::Contributor",
  { "foreign.institution_id" => "self.id" },
  undef,
);

=head2 counter_logs

Type: has_many

Related object: L<CAP::Schema::Result::CounterLog>

=cut

__PACKAGE__->has_many(
  "counter_logs",
  "CAP::Schema::Result::CounterLog",
  { "foreign.institution_id" => "self.id" },
  undef,
);

=head2 institution_alias

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionAlias>

=cut

__PACKAGE__->has_many(
  "institution_alias",
  "CAP::Schema::Result::InstitutionAlias",
  { "foreign.institution_id" => "self.id" },
  undef,
);

=head2 institution_ipaddrs

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionIpaddr>

=cut

__PACKAGE__->has_many(
  "institution_ipaddrs",
  "CAP::Schema::Result::InstitutionIpaddr",
  { "foreign.institution_id" => "self.id" },
  undef,
);

=head2 institution_mgmts

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionMgmt>

=cut

__PACKAGE__->has_many(
  "institution_mgmts",
  "CAP::Schema::Result::InstitutionMgmt",
  { "foreign.institution_id" => "self.id" },
  undef,
);

=head2 institution_subscriptions

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionSubscription>

=cut

__PACKAGE__->has_many(
  "institution_subscriptions",
  "CAP::Schema::Result::InstitutionSubscription",
  { "foreign.institution_id" => "self.id" },
  undef,
);

=head2 stats_usage_institutions

Type: has_many

Related object: L<CAP::Schema::Result::StatsUsageInstitution>

=cut

__PACKAGE__->has_many(
  "stats_usage_institutions",
  "CAP::Schema::Result::StatsUsageInstitution",
  { "foreign.institution_id" => "self.id" },
  undef,
);

=head2 titles

Type: has_many

Related object: L<CAP::Schema::Result::Titles>

=cut

__PACKAGE__->has_many(
  "titles",
  "CAP::Schema::Result::Titles",
  { "foreign.institution_id" => "self.id" },
  undef,
);

=head2 portal_ids

Type: many_to_many

Composing rels: L</institution_subscriptions> -> portal_id

=cut

__PACKAGE__->many_to_many("portal_ids", "institution_subscriptions", "portal_id");

=head2 user_ids

Type: many_to_many

Composing rels: L</institution_mgmts> -> user_id

=cut

__PACKAGE__->many_to_many("user_ids", "institution_mgmts", "user_id");


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-04-11 14:00:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:N+uFRuIXpliFKtWnmCv2fQ


=head2 update_if_valid ($data)

Updates institution with $data if it is valid. Returns a validation hash
indicating whether or not the data is valid and a list of error messages.

=cut
sub update_if_valid {
    my($self, $data) = @_;
    my @errors = ();
    my $code = $data->{code} || undef;
    my $name = $data->{name} || "";

    # code: optional, lowercase alpha only, 16 characters max.
    push(@errors, { message => 'invalid_maxlen', params => [ 'Code', '16' ] }) unless (length($code) <= 16);
    push(@errors, { message => 'invalid_char', params => [ 'Code', $1, 'a-z' ] }) if ($code && $code =~ /([^a-z])/);

    # name: required, 128 characters max.
    push(@errors, { message => 'invalid_empty', params => [ 'Name' ] }) unless ($name && $name =~ /\S/);
    push(@errors, { message => 'invalid_maxlen', params => [ 'Name', '128' ] }) unless (length($name) <= 128);

    return { valid => 0, errors => \@errors } if (@errors);
    $self->update({
        code => $code,
        name => $name
    });
    return { valid => 1, errors => [] };
}


=head2 aliases

Return the aliases for this institution.

=cut
sub aliases {
    my($self) = @_;
    my @aliases = $self->search_related('institution_alias')->all;
    return @aliases if (wantarray);
    return \@aliases;
}


=head2 update_alias_if_valid ($data)

Updates or creates the institution's alias with $data if it is valid.
Returns a validation hash like update_if_valid().

=cut
sub update_alias_if_valid {
    my($self, $data) = @_;
    my @errors = ();
    my $lang = $data->{lang} || "";
    my $name = $data->{name} || "";

    # lang: required, 2 characters only
    push(@errors, { message => 'invalid_size', params => [ 'Language', '2' ] }) unless (length($lang) == 2);

    # name: must be non-empty
    push(@errors, { message => 'invalid_empty', params => [ 'Name' ]}) unless ($name);

    return { valid => 0, errors => \@errors } if (@errors);
    $self->update_or_create_related('institution_alias', { lang => $lang, name => $name });
    return { valid => 1, errors => [] };
}


=head2 delete_alias

Detete the specified language alias, if it exists

=cut
sub delete_alias {
    my($self, $data) = @_;
    my $lang = $data->{lang} || "";

    my $record = $self->find_related('institution_alias', { lang => $lang });
    $record->delete if ($record);
    return { valid => 1, errors => [] };
}


=head2 subscribes_to_portal ($portal)

Returns true if institution subscribes to $portal.

=cut
sub subscribes_to {
    my($self, $portal) = @_;
    my $subscription = $self->find_related('institution_subscriptions', { portal_id => $portal->id });
    $subscription ? 1 : 0;
}

=head2 subscribe_if_exists ($portal)

Subscribes to $portal if it exists

=cut
sub subscribe_if_exists {
    my($self, $data) = @_;
    my @errors = ();
    my $portal = $data->{portal};

    # portal must exist and be subscribable
    if ($portal) {
        push(@errors, { message => 'invalid_argument', params => [ 'Portal', $portal->id ] }) unless ($portal->subscriptions);
    }
    else {
        push(@errors, { message => 'invalid_null', params => [ 'Portal' ] });
    }
    
    return { valid => 0, errors => \@errors } if (@errors);
    $self->update_or_create_related('institution_subscriptions', { portal_id => $portal->id });
    return { valid => 1, errors => [] };
}


=head2 unsubscribe ($portal)

Unsubscribe from the selected portal.

=cut
sub unsubscribe {
    my($self, $data) = @_;
    my @errors = ();
    my $portal = $data->{portal};

    # portal must exist.
    push(@errors, { message => 'invalid_null', params => [ 'Portal' ] }) unless ($portal);

    return { valid => 0, errors => \@errors } if (@errors);

    my $subscription = $self->find_related('institution_subscriptions', { portal_id => $portal->id });
    $subscription->delete if ($subscription);
    return { valid => 1, errors => [] };
}


=head2 ip_addresses

Returns the IP address ranges belonging to the institution.

=cut
sub ip_addresses {
    my $self = shift;
    my @ipaddresses  = $self->search_related('institution_ipaddrs', {}, { order_by => { -asc => 'start' } })->all;
    return @ipaddresses if (wantarray);
    return \@ipaddresses;
}


=head2 add_ipaddress_if_valid

Adds an IP address or range if it is valid.

=cut
sub add_ipaddress_if_valid {
    my($self, $data) = @_;
    my @errors = ();
    my $cidr = $data->{cidr};
    my($start, $end);

    if ($cidr) {
        my $ip_addr = Net::IP->new($cidr);
        if (! $ip_addr) {
            push(@errors, { message => 'invalid_argument', params => ['Address', $cidr] });
        }
        else {
            $cidr = $ip_addr->print();
            $start = $ip_addr->intip();
            $end = $ip_addr->last_int();

            my $ip_start = $ip_addr->intip;
            my $ip_end = $ip_addr->last_int;
            my $overlap;

            # Check the start of the range for overlaps
            $overlap = $self->result_source->schema->resultset('InstitutionIpaddr')->search({start => { '<=', $ip_start }, end => { '>=', $ip_start }});
            push(@errors, { message => 'invalid_ipconflict', params => ['Address', $overlap->first->cidr, $overlap->first->institution_id->name] }) if ($overlap->count);

            # Check the end of the range for overlaps
            $overlap = $self->result_source->schema->resultset('InstitutionIpaddr')->search({start => { '<=', $ip_end }, end => { '>=', $ip_end }});
            push(@errors, { message => 'invalid_ipconflict', params => ['Address', $overlap->first->cidr, $overlap->first->institution_id->name] }) if ($overlap->count);

            # Check for existing subsets of the range
            $overlap = $self->result_source->schema->resultset('InstitutionIpaddr')->search({ start => { '>=', $ip_start, '<=', $ip_end }, end => { '>=', $ip_start, '<=', $ip_end }});
            push(@errors, { message => 'invalid_ipconflict', params => ['Address', $overlap->first->cidr, $overlap->first->institution_id->name] }) if ($overlap->count);
        }
    }
    else {
        push(@errors, { message => 'invalid_null', params => ['Address'] });
    }

    return { valid => 0, errors => \@errors } if (@errors);

    $self->create_related('institution_ipaddrs', { cidr => $cidr, start => $start, end => $end });
    return { valid => 1, errors => [] };
}


=head2 delete_ipaddress

Deletes the selected IP address range based on its starting address

=cut
sub delete_ipaddress {
    my($self, $data) = @_;
    my @errors = ();
    my $start = $data->{start};

    # portal must exist.
    push(@errors, { message => 'invalid_null', params => [ 'Address' ] }) unless ($start);

    return { valid => 0, errors => \@errors } if (@errors);

    my $iprange = $self->find_related('institution_ipaddrs', { start => $start });
    $iprange->delete if ($iprange);
    return { valid => 1, errors => [] };
}





#######


# Return true if this institution subscribes to the current portal.
sub is_subscriber {
    my($self, $portal) = @_;
    my $subscriber = $self->search_related('institution_subscriptions', { portal_id => $portal->id })->count;
    return 1 if $subscriber;
    return 0;
}


sub set_alias {
    my ($self, $lang, $name) = @_;
    if ($name) {
        $self->update_or_create_related('institution_alias', { lang => $lang, name => $name });
    } else {
        $self->delete_related('institution_alias', { lang => $lang });
    }
}

sub portal_contributor {
    my ($self, $portal) = @_;
    my $entity = { id => $self->id, name => $self->name, portal => $portal };
    foreach($self->search_related('contributors', { portal_id => $portal })) {
        $entity->{logo} = $_->logo;
        $entity->{logo_filename} = $_->logo_filename;
        $entity->{$_->lang} = { url => $_->url, description => $_->description };
    }
    return $entity;
}


# You can replace this text with custom content, and it will be preserved on regeneration
1;

