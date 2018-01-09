package CAP::Schema::ResultSet::User;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Digest::SHA qw(sha1_hex);
use POSIX qw(strftime);
use DateTime;
use DateTime::Format::MySQL;

=head2 find_user ($identifier)

Find a user by the string $identifier. If $identifier contains a '@' character, the email field is searched. Otherwise, the username string. Returns the user object or undef if no user is found.

=cut
sub find_user {
    my($self, $identifier) = @_;
    my $user;
    if (index($identifier, '@') == -1) {
        $user = $self->find({ username => $identifier });
    }
    else {
        $user = $self->find({ email => $identifier });
    }
    return $user;
}

=head2 filter (\%params)

Return a filtered set of users based on %params. Default is to return the first 10 users by ID.

=cut
sub filter {
    my($self, $params) = @_;
    my $query = {};
    my $options = { rows => 10, page => 1 };
    my $limit = $params->{limit} || undef;
    my $email = $params->{email} || undef;
    my $username = $params->{username} || undef;
    my $name = $params->{name} || undef;
    my $sort = $params->{sort} || "";
    my $confirmation = $params->{confirmation} || "";

    # Add all defined search limiters
    $query->{email} = { -like => "%$email%" } if ($email);
    $query->{username} = { -like => "%$username%" } if ($username);
    $query->{name} = { -like => "%$name%" } if ($name);
    $options->{rows} = $limit if ($limit);

    # Confirmation status
    if ($confirmation eq 'confirmed') { $query->{confirmed} = 1 }
    elsif ($confirmation eq 'unconfirmed') { $query->{confirmed} = 0 }

    # Sort options
    if ($sort eq 'updated') { $options->{order_by} = [ 'updated DESC' ]; }
    elsif ($sort eq 'created') { $options->{order_by} = [ 'created DESC' ]; }
    elsif ($sort eq 'login') { $options->{order_by} = [ 'last_login DESC' ]; }

    my @result = $self->search($query, $options)->all;
    return @result if (wantarray);
    return \@result;
}


=head2 validate ($data)

Checks all of the parameters in $data to ensure they are valid.  Returns a
list of errors. A zero-length list means all fields are valid. If $user is
a user object, fields are validated in the context of that user (e.g. the
user is allowed to have their own username). If it is undefined, fields
are validated in the context of a new user (e.g. the user cannot have any
existing username).

=cut
sub validate {
    my($self, $data, $user) = @_;
    my @errors = ();
    my $username = $data->{username} || "";
    my $email = $data->{email} || "";
    my $name = $data->{name} || "";
    my $confirmed = 0; $confirmed = 1 if ($data->{confirmed});
    my $active = 0; $active = 1 if ($data->{active});
    my $password = $data->{password} || "";
    my $passwordCheck = $data->{password_check} || "";
    my $user_for_username = $self->result_source->schema->resultset('User')->find({ username => $username });
    my $user_for_email = $self->result_source->schema->resultset('User')->find({ email => $email });

    # Username must be between 1 and 64 characters and not already in use.
    # It cannot contain the @ character (since that is how we distinguish
    # usernames from email addresses).
    push(@errors, { message => 'invalid_username' }) unless (
        $username &&
        length($username) >= 4 &&
        length($username) <= 64 &&
        index($username, '@') == -1
    );
    if ($user_for_username) {
        push(@errors, { message => 'conflict_username', params => [ $username ] }) unless ($user && $user_for_username->id eq $user->id);
    }

    # The email address must be 128 characters or less, must look vaguely
    # like an email address, and cannot already be in use.
    push(@errors, { message => 'invalid_email' }) unless (
        $email &&
        length($email) <= 128 &&
        $email =~ /^\S+\@\S+\.\S+$/
    );
    if ($user_for_email) {
        push(@errors, { message => 'conflict_email', params => [ $email ] }) unless ($user && $user_for_email->id eq $user->id);
    }

    # The real name must be 128 characters or less and cannot be empty
    push(@errors, { message => 'invalid_realname' }) unless (
        length($name) <= 128
    );
    
    # If password is supplied, it must be 6+ characters and match the check password
    push(@errors, { message => 'invalid_minlen', params => [ 'Password', 6 ] }) if ($password && length($password) < 6);
    push(@errors, { message => 'invalid_password_mismatch' }) if ($password && $password ne $passwordCheck);

    return (@errors);
}

=head2 create_if_valid($data)

Create a new user with the hash $data if it validates. Return a hash with the user (if successful) and errors (if not)

=cut
sub create_if_valid {
    my($self, $data) = @_;
    my $user;
    my @errors = $self->validate($data);
    return { errors => \@errors } if (@errors);
    $user = $self->create({
        username => $data->{username},
        email => $data->{email},
        name => $data->{name},
        password => $data->{password},
        confirmed => $data->{confirmed},
        active => $data->{active},
        created => DateTime->now()
    });
    return { user => $user };
}


sub validate_password {
    my($self, $password, $check, $re) = @_;
    my @errors = ();
    if (!$password) {
        push @errors, 'password_required';
    } elsif ($password !~ /$re/) {
        push @errors, 'password_invalid';
    } elsif ($password ne $check) {
        push @errors, 'password_match_failed';
    }
    return @errors;
}

sub validate_confirmation
{
    my($self, $auth) = @_;
    my($id, $token) = split(':', $auth, 2);
    my $user = $self->find({ id => $id });
    return 0 unless ($token);                    # Token is null/empty
    return 0 unless ($user);                     # User does not exist
    return 0 unless ($user->password);           # Token is null/empty
    return 0 unless (sha1_hex($user->password) eq $token); # Tokens do not match
    return $id;
}

sub confirm_new_user
{
    my($self, $auth) = @_;
    my($id, $token) = split(':', $auth, 2);
    my $user = $self->find({ id => $id });
    return 0 unless ($user);                     # User does not exist
    return 0 unless ($token);                    # Token is null/empty
    return 0 unless (sha1_hex($user->password) eq $token); # Authentication token mismatch
    return 0 unless ($user->confirmed == 0);     # User is already confirmed

    # Confirm the user
    $user->update({ confirmed => 1 });
    return $user->id;
}


# Persistent login token:
# These functions set, clear, and validate the persistent login token that
# is set in a cookie on the user's browser. The cookie value is the user's
# ID and a random SHA1 hash, separated with a colon. If the hash matches
# the hash set in the user's token field, we allow that user to be logged
# in without having to re-supply their username and password.

# Set and return a persistent login token for this user.
sub set_token
{
    my($self, $id) = @_;
    my $user = $self->find({ id => $id });
    return undef unless ($user);
    my $random = sha1_hex(rand());
    $user->update({ token => $random });
    return $user->get_column('id') . ':' . $random;
}

# Clear the persistent login token for this user.
sub clear_token
{
    my($self, $id) = @_;
    my $user = $self->find({ id => $id });
    return 0 unless ($user);
    $user->update({ token => "" });
    return 1;
}

# Check whether the supplied token is valid. Returns the user's ID or 0 if
# the token is invalid.
sub validate_token
{
    my($self, $cookie) = @_;
    my($id, $token) = split(':', $cookie, 2);
    my $user = $self->find({ id => $id });
    return 0 unless ($token);                 # Token is null/empty
    return 0 unless ($user);                  # User does not exist
    return 0 unless ($user->confirmed);       # User has not yet been confirmed
    return 0 unless ($user->active);          # User account is inactive
    return 0 unless ($user->token);           # Token is null/empty
    return 0 unless ($user->token eq $token); # Tokens do not match
    return $id;
}


# Determine if the user has a currently-active subscription
sub has_active_subscription
{
    my($self, $id) = @_;
    return $self->search({ id => $id, active => 1 })->count;
}

sub subscribers
{
    my($self) = @_;
    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
    return $self->search({ subexpires => { '>=', $now } })->count;
}




# Number of unconfirmed user accounts
sub unconfirmed_accounts {
    my($self) = @_;
    return $self->search({
        active    => 1,
        confirmed => 0,
    })->count;
}

# Delete unconfirmed users
sub delete_unconfirmed {
    my ( $self, $grace_days ) = @_;

    my $created = DateTime::Format::MySQL->format_datetime(DateTime->now->subtract( days => $grace_days ));
    my $num_deleted = 0;

    my $unconfirmed = $self->search(
        {

            created   => { '<=' => $created },
            active    => 1,
            confirmed => 0

        }
    );

    while (my $user = $unconfirmed->next) {

        # Delete the user_log entries associated with the user.
        my $userlog = $user->search_related('user_logs', { user_id => $user->id});
        $userlog->delete;
        ++$num_deleted if ($user->delete);
    }

    return $num_deleted;
}

# Tally logged requests by user
sub requests {
    my $self = shift;
    my @rows = $self->search(
        { 'request_logs.id' => { '!=' => undef } },
        {
            join => 'request_logs',
            select => ['id', 'name', { count => { distinct => 'request_logs.session' }, '-as' => 'sessions'}, { count => 'me.id', '-as' => 'requests' }],
            as => ['id', 'name', 'sessions', 'requests'],
            group_by => ['me.id'],
            order_by => 'sessions desc'
        }
    );
    return \@rows;
}


# Return the user object for the next user whose account is subscribing
# after $now but before $exp_date, and whose remindersent flag is unset,
# or undef if no such user exists.
sub next_unsent_reminder {
    my($self, $from_date, $now) = @_;

    my $expiring = $self->search ({
        subexpires   => { '<=' => $from_date, '>=' => $now },
        active       => 1,
        remindersent => 0,
        confirmed    => 1,
    });

    return $expiring->first || undef;
}


sub get_user_info {

    my($self, $id) = @_;
    my $get_row =  $self->search( {id => $id} );
    my $row = $get_row->next;

    return $row;

}

sub get_all_data {

    my($self) = shift();
    my $get_row =  $self->search( {} );
    
    my $result = [];
    my $row;
    
    while ($row = $get_row->next) {

        push (@$result, $row);

    }

    return $result;

}

sub get_user_id {

    my($self, $username) = @_;
    my $get_row =  $self->search( {username => $username} );
    my $row = $get_row->next;

    return $row->id;

}


1;
