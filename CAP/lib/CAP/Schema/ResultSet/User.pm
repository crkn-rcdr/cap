package CAP::Schema::ResultSet::User;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Digest::SHA1 qw(sha1_hex);
use POSIX qw(strftime);

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
    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
    return $self->search({ id => $id, subexpires => { '>=', $now } })->count;
}

sub subscribers
{
    my($self) = @_;
    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
    return $self->search({ subexpires => { '>=', $now } })->count;
}

1;
