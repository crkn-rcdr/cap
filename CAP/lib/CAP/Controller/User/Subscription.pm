package CAP::Controller::User::Subscription;
use Moose;
use namespace::autoclean;

__PACKAGE__->config( default => 'text/html', map => { 'text/html' => [ 'View', 'Default' ] });

BEGIN { extends 'Catalyst::Controller::REST'; }

=head1 NAME

CAP::Controller::User::Subscription - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/') PathPart('user/subscription') CaptureArgs(1) {
    my($self, $c, $portal_id) = @_;

    # Get the portal to subscribe to. It must support subscriptions.
    my $portal = $c->model('DB::Portal')->find({ id => $portal_id });
    unless ($portal && $portal->supports_subscriptions) {
        $c->message({ type => "error", message => "bad_request" });
        $self->status_bad_request($c, message => "Nonexistent or non-subscribable portal");
        $c->res->redirect($c->uri_for_action("/index"));
        $c->detach();
    }

    # If the user exists, get their current subscription. Permanent
    # subscriptions cannot be modified by the user.
    my $subscription;
    if ($c->user_exists) {
        $subscription = $c->user->subscription($portal);
        if ($subscription && $subscription->permanent) {
            $c->message({ type => "error", message => "bad_request" });
            $self->status_bad_request($c, message => "User request to modify a permanent subscription");
            $c->res->redirect($c->uri_for_action("/index"));
            $c->detach();
        }
    }

    $c->stash(
        entity => {
            portal => $portal,
            subscription => $subscription,
            products => [$portal->get_subscriptions]
        },
        data => $c->req->body_params,
    );
    return 1;
}

=head2 index

List subscription options

=cut
sub index : Chained('base') PathPart('') Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub index_GET {
    my($self, $c) = @_;
    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

=head2 subscribe

Take a new subscription.

=cut
sub subscribe : Chained('base') PathPart('subscribe') Args(1) ActionClass('REST') {
    my($self, $c, $product_id) = @_;
    my $portal = $c->stash->{entity}->{portal};
    my $subscription = $c->stash->{entity}->{subscription};

    # Get the subscription product
    my $product = $portal->subscription($product_id);
    if (! $product) {
        $c->message({ type => "error", message => "bad_request" });
        $self->status_bad_request($c, message => "Request for nonexistent subscription product");
        $c->res->redirect($c->uri_for_action("/index"));
        $c->detach();
    }
    $c->stash->{entity}->{product} = $product;
    $c->stash->{entity}->{payable} = $product->price;


    # Determine the expiration date
    my $duration = DateTime::Duration->new(days => $product->duration + 1); # Round up to the next day
    if ($subscription) {
        $c->stash->{entity}->{expiry} = $subscription->calculate_expiry($duration);
    }
    else {
        $c->stash->{entity}->{expiry} = DateTime->now()->add_duration($duration);
    }

    return 1;
}

sub subscribe_GET {
    my($self, $c, $product_id) = @_;
    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

sub subscribe_POST {
    my($self, $c, $product_id) = @_;
    my $portal = $c->stash->{entity}->{portal};
    my $product = $c->stash->{entity}->{product};
    my $expiry = $c->stash->{entity}->{expiry};
    my $data = $c->stash->{data};
    my $submit = $data->{submit};
    my $tos_ok = $data->{terms};

    # If this i
    if ($submit eq 'checkout') {
        my $payable = $c->stash->{entity}->{payable};

        if (! $tos_ok) {
            $c->message({ type => "error", message => "invalid_tos" });
            $self->status_bad_request($c, message => "User did not agree to terms of service");
            $c->res->redirect($c->uri_for_action("/user/subscription/subscribe", [$portal->id, $product->id]));
            $c->detach();
        }

        my $subscription = $c->user->open_subscription($product, $expiry);
        my $description = sprintf(
            "%s. %s. %s. %s",
            $c->loc("Subscription to [_1]", $portal->title($c->stash->{lang})),
            $c->loc("Duration: [_1] days", $product->duration),
            $c->loc("Expires on [_1]", $expiry->ymd),
            $c->loc("Price: \$[_1]", $payable)
        );
        $c->detach('/payment/paypal/pay', [$payable, $description, '/user/subscribe_finalize', $subscription->id]);
    }


    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
