package CAP::Auth;
use strict;
use warnings;
use namespace::autoclean;
use Moose;
use MooseX::Method::Signatures;

has 'subscription'    => (is => 'ro', isa => 'Maybe[CAP::Model::DB::UserSubscription]', default => undef, documentation => 'subscription row');
has 'title_context'   => (is => 'rw', isa => 'Maybe[CAP::Model::DB::Titles]', default => undef, documentation => 'subscription row');
has 'institution_sub' => (is => 'ro', isa => 'Int', default => 0, documentation => 'has an institutional subscription');

has 'access'          => (is => 'ro', isa => 'HashRef', documentation => 'access matrix for the portal');
has 'user_level'      => (is => 'ro', isa => 'Int', default => 0, documentation => 'access level of the current user');

around BUILDARGS  => sub {
    my($orig, $class, $portal, $institution, $user) = @_;
    my %params = ();

    # Get the access matrix for the portal
    my $access = $portal->access;

    # Determine the user's subscription level:
    
    # Unauthenticated visitors are always level 0.
    my $level = 0;

    # An authenticated user's level is determined by their subscription
    # (if active), otherwise zero.
    if ($user) {
        my $subscription = $user->subscription($portal);
        if ($subscription) {
            $params{subscription} = $subscription;
            if ($subscription->active) {
                $level = $subscription->level;
            }
        }
    }

    # Institutional subscriptions are always level 2 (premium).
    if ($institution) {
        if ($institution->subscriber($portal)) {
            $level = 2;
            $params{institution_sub} = 1;
        }
    }

    $params{access} = $access;
    $params{user_level} = $level;

    return $class->$orig(%params);
};


=head2  minimum_user_level (Str $feature, Int $level) 

Returns the minimum user level required to access $feature for content
with access level $level (default 0), or -1 if access is disabled
altogether.

=cut
method min_user_level (Str $feature, Int $level = 0) {
    my $min_level = -1;
    foreach my $feature_name (qw(preview content metadata resize download purchase searching browse)) {
        if ($feature eq $feature_name) {
            $min_level = $self->access->{$feature}->{$level};
            last;
        }
    }
    return $min_level;
}


=head2 can_access ($feature, $level)

Returns true or false depending on whether the user can access $feature
for content at $level. If $level is ommitted, the default title context is
    used or, if that is undefined, 0.

=cut
method can_access (Str $feature, Int $level?) {

    if (! defined($level)) {
        if ($self->title_context) {
            #warn "Getting level from title context";
            $level = $self->title_context->level;
        }
        else {
            #warn "Using default level 0";
            $level = 0;
        }
    }

    #warn "Level is $level";

    my $min_level = $self->min_user_level($feature, $level);

    #warn "Asked about $feature for level $level:  Need $min_level, have " . $self->user_level;
    return 0 if ($min_level < 0);
    return 0 if ($min_level > $self->user_level);
    return 1;
}


=head2 can_use ($feature)

Returns true if $feature is available to the user for at least some content.

=cut
method can_use (Str $feature) {
    #warn "Asking about $feature";
    for (my $level = 0; $level < 3; ++$level) {
        return 1 if ($self->can_access($feature, $level));
    }
    return 0;
}

=head2 is_enabled ($feature)

Returns true if the feature is enabled for at least one level of content.

=cut
method is_enabled (Str $feature) {
    #warn "Checking whether $feature is enabled";
    for (my $level = 0; $level < 3; ++$level) {
        return 1 if ($self->min_user_level($feature, $level) != -1);
    }
    return 0;
}


__PACKAGE__->meta->make_immutable;

1;
