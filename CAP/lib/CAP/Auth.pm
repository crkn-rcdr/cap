package CAP::Auth;
use strict;
use warnings;
use namespace::autoclean;
use Moose;
use MooseX::Method::Signatures;

has 'all'             => (is => 'ro', isa => 'Int', default => 0, documentation => 'can view all content'); 
has 'download'        => (is => 'ro', isa => 'Int', default => 0, documentation => 'can download distribution media');
has 'preview'         => (is => 'ro', isa => 'Int', default => 0, documentation => 'can view preview content');
has 'resize'          => (is => 'ro', isa => 'Int', default => 0, documentation => 'can resize images');
has 'individual_sub'  => (is => 'ro', isa => 'Int', default => 0, documentation => 'has an individual subscription');
has 'institution_sub' => (is => 'ro', isa => 'Int', default => 0, documentation => 'has an institutional subscription');

around BUILDARGS  => sub {
    my($orig, $class, $portal, $institution, $user) = @_;
    my %params = ();

    # Determine the user's subscription level:
    #
    # Unauthenticated visitors are always level 0.
    my $level = 0;

    # An authenticated user's level is determined by their subscription
    # (if active), otherwise zero.
    if ($user) {
        my $subscription = $user->subscription($portal);
        if ($subscription && $subscription->active) {
            $level = $subscription->level;
            $params{individual_sub} = 1;
        }
    }

    # Institutional subscriptions are always level 2 (premium).
    if ($institution) {
        if ($institution->subscriber($portal)) {
            $level = 2;
            $params{institutional_sub} = 1;
        }
    }

    # Set permissions
    $params{all} = 1 if ($portal->access_all != -1 && $portal->access_all <= $level);
    $params{download} = 1 if ($portal->access_download != -1 && $portal->access_download <= $level);
    $params{preview} = 1 if ($portal->access_preview != -1 && $portal->access_preview <= $level);
    $params{resize} = 1 if ($portal->access_resize != -1 && $portal->access_resize <= $level);

    return $class->$orig(%params);
};

__PACKAGE__->meta->make_immutable;

1;
