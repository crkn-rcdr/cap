use utf8;
package CAP::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CAP::Schema::Result::User

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

=head1 TABLE: C<user>

=cut

__PACKAGE__->table("user");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 50

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 token

  data_type: 'varchar'
  is_nullable: 1
  size: 128

=head2 confirmed

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 active

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 lastseen

  data_type: 'integer'
  is_nullable: 0

=head2 credits

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 class

  data_type: 'enum'
  default_value: 'basic'
  extra: {list => ["basic","trial","paid","permanent"]}
  is_nullable: 0

=head2 subexpires

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 remindersent

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 128 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 50 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "token",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "confirmed",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "active",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "lastseen",
  { data_type => "integer", is_nullable => 0 },
  "credits",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "class",
  {
    data_type => "enum",
    default_value => "basic",
    extra => { list => ["basic", "trial", "paid", "permanent"] },
    is_nullable => 0,
  },
  "subexpires",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "remindersent",
  { data_type => "tinyint", default_value => 0, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<username>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username", ["username"]);

=head1 RELATIONS

=head2 feedbacks

Type: has_many

Related object: L<CAP::Schema::Result::Feedback>

=cut

__PACKAGE__->has_many(
  "feedbacks",
  "CAP::Schema::Result::Feedback",
  { "foreign.user_id" => "self.id" },
  undef,
);

=head2 institution_mgmts

Type: has_many

Related object: L<CAP::Schema::Result::InstitutionMgmt>

=cut

__PACKAGE__->has_many(
  "institution_mgmts",
  "CAP::Schema::Result::InstitutionMgmt",
  { "foreign.user_id" => "self.id" },
  undef,
);

=head2 payments

Type: has_many

Related object: L<CAP::Schema::Result::Payment>

=cut

__PACKAGE__->has_many(
  "payments",
  "CAP::Schema::Result::Payment",
  { "foreign.user_id" => "self.id" },
  undef,
);

=head2 request_logs

Type: has_many

Related object: L<CAP::Schema::Result::RequestLog>

=cut

__PACKAGE__->has_many(
  "request_logs",
  "CAP::Schema::Result::RequestLog",
  { "foreign.user_id" => "self.id" },
  undef,
);

=head2 subscriptions

Type: has_many

Related object: L<CAP::Schema::Result::Subscription>

=cut

__PACKAGE__->has_many(
  "subscriptions",
  "CAP::Schema::Result::Subscription",
  { "foreign.user_id" => "self.id" },
  undef,
);

=head2 user_documents

Type: has_many

Related object: L<CAP::Schema::Result::UserDocument>

=cut

__PACKAGE__->has_many(
  "user_documents",
  "CAP::Schema::Result::UserDocument",
  { "foreign.user_id" => "self.id" },
  undef,
);

=head2 user_logs

Type: has_many

Related object: L<CAP::Schema::Result::UserLog>

=cut

__PACKAGE__->has_many(
  "user_logs",
  "CAP::Schema::Result::UserLog",
  { "foreign.user_id" => "self.id" },
  undef,
);

=head2 user_roles

Type: has_many

Related object: L<CAP::Schema::Result::UserRoles>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "CAP::Schema::Result::UserRoles",
  { "foreign.user_id" => "self.id" },
  undef,
);

=head2 user_subscriptions

Type: has_many

Related object: L<CAP::Schema::Result::UserSubscription>

=cut

__PACKAGE__->has_many(
  "user_subscriptions",
  "CAP::Schema::Result::UserSubscription",
  { "foreign.user_id" => "self.id" },
  undef,
);

=head2 institution_ids

Type: many_to_many

Composing rels: L</institution_mgmts> -> institution_id

=cut

__PACKAGE__->many_to_many("institution_ids", "institution_mgmts", "institution_id");


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-03-01 13:09:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rjOwnh20oxd+3S3QXukWNQ


# You can replace this text with custom content, and it will be preserved on regeneration

#__PACKAGE__->load_components('ForceUTF8');
__PACKAGE__->add_columns(
    'password' => {
        data_type => 'VARCHAR',
        size => 40 + 10,
        encode_column => 1,
        encode_class => 'Digest',
        encode_args => { algorithm => 'SHA-1', format => 'hex', salt_length => 10 },
        encode_check_method => 'check_password',
    } 
);

=head2 has_role($role_name, [$by_name])

Returns true if the user has the role $role_name. If $by_name is defined
and nonzero, this method returns true only if the user has the named role.
Otherwise, the method will also return true for any query if the user has
the administrator role.

=cut
sub has_role {
    my($self, $role_name, $by_name) = @_;
    return 1 if ($self->find_related('user_roles', { role_id => $role_name} ));
    return 0 if ($by_name);
    return 1 if ($self->find_related('user_roles', { role_id => 'administrator'} ));
    return 0;
}

# Returns the subscriber level for the user's subscription to $portal; 0 for no subscription
sub subscriber_level {
    my($self, $portal) = @_;
    my $sub = $self->find_related('user_subscriptions', { portal_id => $portal->id });
    return $sub->level if ($sub);
    return 0;
}

# Returns the effective access level (0 for none) based on whether the
# user has a subscription and, if so, is it active and what type.
sub access_level {
    my($self, $portal) = @_;
    my $sub = $self->find_related('user_subscriptions', { portal_id => $portal->id });
    return 0 unless ($sub); # No subscription, so level 0
    return 0 unless ($sub->permanent || $sub->expires->epoch() > time); # Expired, so level 0
    return $sub->level; # Active subscription; use indicated level
}

# Returns true if the user has a currently active subscription for $portal.
sub subscription_active {
    my($self, $portal) = @_;
    my $sub = $self->find_related('user_subscriptions', { portal_id => $portal->id });
    return 0 unless ($sub);
    my $active = ( $sub->permanent || $sub->expires->epoch() > time ) ? 1 : 0;
    return $active;
}

# Returns the date the subscription expire(d|s). Returns 'permanent' if
# the subscription does not expire and null if there is no subscription.
sub subscription_expires {
    my($self, $portal) = @_;
    my $sub = $self->find_related('user_subscriptions', { portal_id => $portal->id });
    return undef unless ($sub);
    return 'permanent' if ($sub->permanent);
    return $sub->expires;
}






sub set_roles {
    my ($self, $on_roles, @all_roles) = @_;
    my @active_roles;
    if(ref($on_roles) eq 'ARRAY') {
        @active_roles = @{$on_roles};
    }
    else {
        @active_roles = ($on_roles);
    }

    foreach my $role_row (@all_roles) {
        my $role = $role_row->id;
        if (grep /^$role$/, @active_roles) {
            $self->find_or_create_related('user_roles', { role_id => $role });
        } else {
            $self->delete_related('user_roles', { role_id => $role });
        }
    }
}

use Digest::SHA qw(sha1_hex);

# Account confirmation/password reset token: consists of the user's ID and
# password hash.
sub confirmation_token
{
    my $self = shift;;
    return join(":", $self->id, sha1_hex($self->password));
}

# Create a log entry for the user.
sub log {
    my($self, $event, $info) = @_;
    $info = "" unless ($info);
    eval {
        $self->create_related('user_logs', { event => $event, info => $info })
    };
    if ($@) {
        warn(sprintf("Error updating user_log for user %d: $@\n", $self->id));
    }
    return 1;
}

sub subscription {
    my($self, $portal) = @_;
    my $entity = { id => $self->id, username => $self->username, name => $self->name, portal => $portal };
    my $subscription = $self->find_related("user_subscriptions", { portal_id => $portal });
    if ($subscription) {
        $entity->{expires} = $subscription->expires;
        $entity->{reminder_sent} = $subscription->reminder_sent;
        $entity->{permanent} = $subscription->permanent;
        $entity->{level} = $subscription->level;
    }
    return $entity;
}

1;
