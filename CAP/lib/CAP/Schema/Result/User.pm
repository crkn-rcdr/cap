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
  size: 64

=head2 email

  data_type: 'varchar'
  is_nullable: 1
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

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 last_login

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 credits

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 can_transcribe

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 1

=head2 can_review

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 1

=head2 public_contributions

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 1

=head2 updated

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 128 },
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
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "last_login",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "credits",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "can_transcribe",
  { data_type => "tinyint", default_value => 1, is_nullable => 1 },
  "can_review",
  { data_type => "tinyint", default_value => 1, is_nullable => 1 },
  "public_contributions",
  { data_type => "tinyint", default_value => 0, is_nullable => 1 },
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

=head1 UNIQUE CONSTRAINTS

=head2 C<email>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("email", ["email"]);

=head2 C<username_2>

=over 4

=item * L</username>

=back

=cut

__PACKAGE__->add_unique_constraint("username_2", ["username"]);

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

=head2 images

Type: has_many

Related object: L<CAP::Schema::Result::Images>

=cut

__PACKAGE__->has_many(
  "images",
  "CAP::Schema::Result::Images",
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

=head2 pages_review_user_ids

Type: has_many

Related object: L<CAP::Schema::Result::Pages>

=cut

__PACKAGE__->has_many(
  "pages_review_user_ids",
  "CAP::Schema::Result::Pages",
  { "foreign.review_user_id" => "self.id" },
  undef,
);

=head2 pages_transcription_user_ids

Type: has_many

Related object: L<CAP::Schema::Result::Pages>

=cut

__PACKAGE__->has_many(
  "pages_transcription_user_ids",
  "CAP::Schema::Result::Pages",
  { "foreign.transcription_user_id" => "self.id" },
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


# Created by DBIx::Class::Schema::Loader v0.07030 @ 2013-08-20 08:09:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:I8lKscb3ZKTqKQynJovjKA


# You can replace this text with custom content, and it will be preserved on regeneration

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


# This relationship does not get auto-generated, for some reason.
__PACKAGE__->has_many(
  "user_discounts",
  "CAP::Schema::Result::UsersDiscounts",
  { "foreign.user_id" => "self.id" },
  undef,
);

# This relationship does not get auto-generated, for some reason.
__PACKAGE__->has_many(
  "user_logs",
  "CAP::Schema::Result::UserLog",
  { "foreign.user_id" => "self.id" },
  undef,
);


=head2 update_if_valid ($data)

Updates the user account if the data is valid. Returns a validation hash.

=cut
sub update_if_valid {
    my($self, $data) = @_;
    my @errors = ();
    my $username = $data->{username} || "";
    my $email = $data->{email} || "";
    my $name = $data->{name} || "";
    my $confirmed = 0; $confirmed = 1 if ($data->{confirmed});
    my $active = 0; $active = 1 if ($data->{active});
    my $can_transcribe = 0; $can_transcribe = 1 if ($data->{can_transcribe});
    my $can_review = 0; $can_review = 1 if ($data->{can_review});
    my $password = $data->{password} || "";
    my $passwordCheck = $data->{password_check} || "";
    my $user_for_username = $self->result_source->schema->resultset('User')->find({ username => $username });
    my $user_for_email = $self->result_source->schema->resultset('User')->find({ email => $email });

    push(@errors, $self->result_source->schema->resultset('User')->validate($data, $self));

    return { valid => 0, errors => \@errors } if (@errors);

    $self->update({
        username => $username,
        email => $email,
        name => $name,
        confirmed => $confirmed,
        active => $active,
        can_transcribe => $can_transcribe,
        can_review => $can_review
    });

    $self->update({ password => $password }) if ($password);

    return { valid => 1, errors => [] };

}


=head2 update_roles_if_valid ($data)

Updates the user's roles if the data is valid. Returns a validation hash.

=cut
sub update_roles_if_valid {
    my($self, $data) = @_;
    my @errors = ();
    my @roles = ();

    if ($data->{roles}) {
        if (ref($data->{roles}) eq 'ARRAY') {
            @roles = @{$data->{roles}};
        }
        else {
            @roles = ($data->{roles});
        }
    }

    # Each role must exist
    foreach my $role (@roles) {
        unless ($self->result_source->schema->resultset('Roles')->find($role)) {
            push(@errors, { message => 'invalid_role', params => [ $role ] });
        }
    }

    return { valid => 0, errors => \@errors } if (@errors);
    $self->related_resultset('user_roles')->set_roles($self, @roles);
    return { valid => 1, errors => [] };
}


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


=head2 subscription ($portal)

Returns the susbcription for $portal.

=cut
sub subscription {
    my($self, $portal) = @_;
    my $subscription = $self->find_related("user_subscriptions", { portal_id => $portal->id });
    return $subscription;
}


=head2 open_subscription

Creates a new subscription row, or updates an existing pending subscription.

=cut
sub open_subscription {
    my($self, $product, $expiry, $discount, $discount_amount) = @_;
    my $portal = $product->portal_id;
    my $old_expire = undef;
    my $old_level = undef;
    my $discount_code;
    $discount_code = $discount->code if ($discount);

    # If the user has an existing subscription to this portal, store the
    # current expiry date and level.
    my $user_subscription = $self->find_related('user_subscriptions', { portal_id => $product->portal_id->id });
    if ($user_subscription) {
        $old_expire = $user_subscription->expires;
        $old_level = $user_subscription->level;
    }


    # If the user has an existing open subscription, find it. Otherwise,
    # create a new one.
    my $subscription = $self->find_related('subscriptions', { completed => undef }  );

    my $fields = {
        portal_id => $portal->id,
        product => $product->id,
        discount_code => $discount_code,
        discount_amount => $discount_amount,
        old_expire => $old_expire,
        new_expire => $expiry,
        old_level => $old_level,
        new_level => $product->level
    };

    if ($subscription) {
        $subscription->update($fields);
    }
    else {
        $subscription = $self->create_related('subscriptions', $fields);
    }
    return $subscription;
}


=head2 retrieve_subscription

Retrieves the user's current pending open subscription and

=cut
sub retrieve_subscription {
    my($self) = @_;
    return $self->find_related('subscriptions', { completed => undef });
}


=head2 close_subscription

Finalize a subscription row based on the $payment

=cut
sub close_subscription {
    my($self, $payment) = @_;
    my $subscription = $self->find_related('subscriptions', { completed => undef }  );
    if ($subscription) {
        $subscription->update({
            completed => DateTime->now(),
            success => $payment->success,
            payment_id => $payment->id
        });
    }
    return $subscription;
}


=head2 retrieve_payment ($foreign_id)

Retrieves a payment based on its foreign id column

=cut
sub retrieve_payment {
    my($self, $foreign_id) = @_;
    my $payment = $self->search_related('payments', { foreignid => $foreign_id });
    return $payment->first if ($payment->count);
    return undef;
}


=head2 set_subscription ($subscription)

Set's a user's subscription in the user_subscriptions table to values from
$subscription. Resets the reminder sent and expiry_logged flags. If a
discount code was used, record the use.

=cut
sub set_subscription {
    my($self, $subscription) = @_;
    my $user_subscription = $self->find_or_create_related('user_subscriptions', { portal_id => $subscription->portal_id });
    $user_subscription->update({
        expires => $subscription->new_expire,
        reminder_sent => 0,
        expiry_logged => undef,
        level => $subscription->new_level
    });

    if ($subscription->discount_code) {
        # Get the ID for the discount code
        my $discount = $self->result_source->schema->resultset('Discounts')->find({ code => $subscription->discount_code });
        if ($discount) {
            $self->update_or_create_related('user_discounts', { discount_id => $discount->id, subscription_id => $subscription->id });
        }
    }

    return $user_subscription;
}


=head2 discount_used ($discount)

If the user has previously used the specified discount, return the
corresponding subscription row. Otherwise, return undef.

=cut
sub discount_used {
    my($self, $discount) = @_;
    my $subscription = $self->find_related('user_discounts', { discount_id => $discount->id });
    return $subscription || undef;
}


=head2 subscription_history 

Returns a user's susbcription transaction history, starting with the most
recent. Includes only completed transactions.

=cut
sub subscription_history {
    my($self) = @_;
    my @history = $self->search_related('subscriptions', { completed => { '!=' => undef }}, { order_by => { -desc => 'completed'}})->all;
    return @history if (wantarray);
    return \@history;
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
    return $sub->active;
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

sub log_failed_login {
    my($self) = @_;
    my $reason;
    if (! $self->active) { $reason = 'not active'; }
    elsif (! $self->confirmed) { $reason = 'not confirmed'; }
    else { $reason = 'bad password'; }
    $self->log("LOGIN_FAILED", $reason);
    return 0;
}

=head2 update_account_information

Updates a user's email address, name, and password (if supplied).

=cut
sub update_account_information {
    my($self, $data) = @_;

    my %old_info = (username => $self->username, name => $self->name);
    $self->update({
        username => $data->{username},
        name     => $data->{name},
    });

    if ($old_info{username} ne $data->{username}) {
        $self->log('USERNAME_CHANGED', sprintf("from %s to %s", $old_info{username}, $data->{username}));
    }
    if ($old_info{name} ne $data->{name}) {
        $self->log('NAME_CHANGED', sprintf("from %s to %s", $old_info{name}, $data->{name}));
    }

    # Change the password, if requested.
    if ($data->{password}) {
        $self->update({ password => $data->{password} });
        $self->log('PASSWORD_CHANGED', "");
    }
}
=head2 managed_institutions

Returns a list of institutions the user manages

=cut
sub managed_institutions {
    my($self) = @_;
    my $result = $self->search_related('institution_mgmts', {}, { join => 'institution_id', order_by => [ 'institution_id.name' ] });
    my @institutions = ();
    while (my $row = $result->next) {
        push(@institutions, $row->institution_id);
    }
    return @institutions if (wantarray);
    return \@institutions;
}

1;
