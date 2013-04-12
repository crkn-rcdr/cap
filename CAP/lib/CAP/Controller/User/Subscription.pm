package CAP::Controller::User::Subscription;
use Moose;
use namespace::autoclean;

__PACKAGE__->config( map => { 'text/html' => [ 'View', 'Default' ] } );

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
    if (! $portal) {
        $c->message({ type => "error", message => "invalid_entity", params => ['portal'] });
        $self->status_not_found($c, message => "No such portal");
        $c->res->redirect($c->uri_for_action("/user/profile"));
        $c->detach();
    }
    if (! $portal->subscriptions) {
        $c->message({ type => "error", message => "invalid_argument", params => ['Portal', $portal->id] });
        $self->status_not_found($c, message => "Subscriptions not supported");
        $c->res->redirect($c->uri_for_action("/user/profile"));
        $c->detach();
    }

    # Get the user's existing subscription, if any.
    my $subscription = $c->user->subscription($portal);
    if ($subscription && $subscription->permanent) {
        $c->message({ type => "error", message => "sub_is_permanent" });
        $self->status_not_found($c, message => "Cannot change permanent subscription");
        $c->res->redirect($c->uri_for_action("/user/profile"));
        $c->detach();
    }

    $c->stash(
        entity => { portal => $portal, subscription => $subscription },
        data => $c->req->body_params,
        discount => undef,
        discount_amount => 0
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
        $c->message({ type => "error", message => "invalid_entity", params => ['portal'] });
        $self->status_not_found($c, message => "No such portal");
        $c->res->redirect($c->uri_for_action("/user/profile"));
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
    my $tos_ok = $data->{tos_ok};

    if ($data->{code}) {
        my $code = $data->{code};
        my $discount = $portal->discount($code);
        if (! $discount) {
            $c->message({ type => "error", message => "invalid_discount_code" });
            $self->status_bad_request($c, message => "Invalid discount code");
            $c->res->redirect($c->uri_for_action("/user/subscription/subscribe", [$portal->id, $product->id]));
            $c->detach();
        }

        # TODO: here is where we will check to see if the user has already used this code ...

        my $discount_amount = ($product->price * $discount->percentage) / 100;
        $c->stash->{entity}->{discount} = $discount;
        $c->stash->{entity}->{discount_amount} = $discount_amount;
        $c->stash->{entity}->{payable} = $product->price - $discount_amount;
    }

    if ($submit eq 'checkout') {
        my $discount = $c->stash->{entity}->{discount};
        my $discount_amount = $c->stash->{entity}->{discount_amount};

        if (! $tos_ok) {
            $c->message({ type => "error", message => "tos_agreement" });
            $self->status_bad_request($c, message => "Terms of service not agreed to");
            $c->res->redirect($c->uri_for_action("/user/subscription/subscribe", [$portal->id, $product->id]));
            $c->detach();
            # FIXME: we aren't preserving the discount code here.
        }

        my $subscription = $c->user->open_subscription($product, $expiry, $discount, $discount_amount);
        $c->detach('/payment/paypal/pay', [500, "DESCRIBE PRODUCT HERE", '/user/subscribe_finalize', $subscription->id]);
    }


    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
