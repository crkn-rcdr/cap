package CAP::Schema::ResultSet::User;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use Digest::SHA qw(sha1_hex);
use POSIX qw(strftime);

sub validate {
    my($self, $fields, $re, %options) = @_;
    my @errors = ();
    $options{current_user} = '' unless defined($options{current_user});
    if ($fields && $re) {
        if (!$fields->{username}) {
            push @errors, 'email_required';
        } elsif ($self->find({ username => $fields->{username} })) {
            if (!$options{current_user}) {
                push @errors, 'account_exists';
            } elsif ($options{current_user} ne $fields->{username}) {
                push @errors, 'username_exists';
            }
        } elsif ($fields->{username} !~ /$re->{username}/) {
            push @errors, 'email_invalid';
        }

        if (!$fields->{name}) {
            push @errors, 'name_required';
        } elsif ($fields->{name} !~ /$re->{name}/) {
            push @errors, 'name_invalid';
        }

        if ($options{validate_password}) {
            push @errors, $self->validate_password(
                $fields->{password},
                $fields->{password_check},
                $re->{password});
        }
    } else {
        push @errors, 'missing_information';
    }
    return @errors;
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
    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
    return $self->search({ id => $id, subexpires => { '>=', $now } })->count;
}

sub subscribers
{
    my($self) = @_;
    my $now = strftime("%Y-%m-%d %H:%M:%S", localtime);
    return $self->search({ subexpires => { '>=', $now } })->count;
}


sub get_user_class {

    my($self, $id) = @_;
    my $get_class =  $self->search(
                                {
                         
                                    id => $id
                                  
                                }           
                             );
    my $result = $get_class->next;

    return $result->class;

}

# Number of active trial subscriptions
sub active_trials {
    my($self) = @_;
    return $self->search({
        active    => 1,
        confirmed => 1,
        class     => 'trial',
        subexpires   => { '>=', strftime("%Y-%m-%d %H:%M:%S", localtime)}
    })->count;
}

# Number of expired trial subscriptions
sub expired_trials {
    my($self) = @_;
    return $self->search({
        active    => 1,
        confirmed => 1,
        class     => 'trial',
        subexpires   => { '<', strftime("%Y-%m-%d %H:%M:%S", localtime)}
    })->count;
}

# Number of active paid subscriptions
sub active_subscriptions {
    my($self) = @_;
    return $self->search({
        active    => 1,
        confirmed => 1,
        class     => 'paid',
        subexpires   => { '>=', strftime("%Y-%m-%d %H:%M:%S", localtime)}
    })->count;
}

# Number of expired paid subscriptions
sub expired_subscriptions {
    my($self) = @_;
    return $self->search({
        active    => 1,
        confirmed => 1,
        class     => 'paid',
        subexpires   => { '<', strftime("%Y-%m-%d %H:%M:%S", localtime)}
    })->count;
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
    my ( $self, $created ) = @_;

    my $unconfirmed = $self->search(
        {

            created   => { '<=' => $created },
            active    => 1,
            confirmed => 0

        }
    );
    
    my $result = $unconfirmed->next;
    my $deleted = [];
    

    return $unconfirmed->delete();
}

# Tally logged requests by user
sub requests {
    my $self = shift;
    my @rows = $self->search(
        { 'request_logs.id' => { '!=' => undef } },
        {
            join => 'request_logs',
            select => ['id', 'name', 'class', { count => { distinct => 'request_logs.session' }, '-as' => 'sessions'}, { count => 'me.id', '-as' => 'requests' }],
            as => ['id', 'name', 'class', 'sessions', 'requests'],
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
        class        => { '!=' => 'permanent' },
        active       => 1,
        remindersent => 0,
        confirmed    => 1,
    });

    return $expiring->first || undef;
}

# Get all the users whose accounts are expiring.
sub expiring_subscriptions {
    my ( $self, $from_date, $now ) = @_;

    my $expiring = $self->search(
        {

            subexpires   => { '<=' => $from_date, '>=' => $now },
            #subexpires   => { '>=' => $now },
            class        => { '!=' => 'permanent'},
            class        => { '!=' => 'admin'},
            active       => 1,
            remindersent => 0,
            confirmed    => 1

        }
    );
    
    my $result;
    my $userinfo;
    my $expiring_accounts = [];
    
    while ($result = $expiring->next) {
       $userinfo = { 'id'       => $result->id,
                     'name'     => $result->name,
                     'username' => $result->username,
                     'class'    => $result->class,
                     'expires'  => $result->subexpires };
       push (@$expiring_accounts, $userinfo);   
    }
  
    return $expiring_accounts;
}

# reset the user's remidersent record
sub set_remindersent {

       my ( $self, $user_id, $new_setting ) = @_;
       
       my $user = $self->find({ id => $user_id });
       $user->update({ remindersent => $new_setting });

       return 1;
    
}


1;
