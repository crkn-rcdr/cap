package CAP::Controller::Admin::Discount;
use Moose;
use namespace::autoclean;
use CAP::Util;

__PACKAGE__->config(
    map => {
        'text/html' => [ 'View', 'Default' ],
    },
);

BEGIN { extends 'Catalyst::Controller::REST'; }

=head1 NAME

CAP::Controller::Admin::Discount - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub index_GET {
    my($self, $c) = @_;
    $c->stash(discounts => [$c->model('DB::Discounts')->all]);
}


#
# Create: add a new discount code
#

sub create :Local :Path('create') ActionClass('REST') {
    my($self, $c) = @_;
    $c->stash(
        entity => { subscribable => [$c->model('DB::Portal')->list_subscribable] }
    );

}

sub create_GET {
    my($self, $c) = @_;
    return 1;
}

sub create_POST {
    my($self, $c) = @_;
    my %data;
    foreach my $key (keys %{$c->req->body_parameters}) {
        $data{$key} = $c->req->body_parameters->{$key} if $c->req->body_parameters->{$key};
    }
    $data{percentage} = int ($data{percentage}); # Coerce the discount % into an integer

    my $portal = $c->model('DB::Portal')->find({ id => $data{portal_id} });
    my $discount = $c->model('DB::Discounts')->find({ code => $data{code} });
    my $error = 0;

    # Validate the form:

    # Discount code must not already be in use
    if ($discount) {
        $c->message({ type => "error", message => "discount_code_exists" });
        $error = 1;
    }

    # Portal must exist
    if (! $portal) {
        $c->message({ type => "error", message => "no_such_portal" });
        $error = 1;
    }
    
    # Discount percentage must be an integer between 5 and 95
    if ($data{percentage} < 5 || $data{percentage} > 95) {
        $c->message({ type => "error", message => "invalid_discount_amount" });
        $error = 1;
    }

    # Expiry date must be a valid date.
    # FIXME: this is not a full date validator. We need a generic function
    # to check if something (a) is a date and (b) is in the past/future.
    if ($data{expires} !~ /^\d{4}-\d{2}-\d{2}$/) {
        $c->message({ type => "error", message => "invalid_date" });
        $error = 1;
    }


    # Return to the form if there were any errors
    if ($error) {
        $c->response->redirect($c->uri_for_action("/admin/discount/create", \%data), 303);
        return 1;
    }

    # Create a new discount code
    $discount = $c->model('DB::Discounts')->create(\%data);
    $c->message({ type => "success", message => "discount_code_created" });
    $c->response->redirect($c->uri_for_action("/admin/discount/edit", $discount->get_column('id')));
    return 1;
}

#
# Edit: edit an existing user
#

sub edit :Local Path('edit') Args(1) ActionClass('REST') {
    my($self, $c, $id) = @_;
}

sub edit_GET {
    my($self, $c, $id) = @_;
    my $discount = $c->model('DB::Discounts')->find({ id => $id });
    if (! $discount) {
        $c->message({ type => "error", message => "discount_code_not_found" });
        $self->status_not_found($c, message => "No such discount code");
        return 1;
    }

    $c->stash(
        entity => $c->cap->build_entity($discount)
    );
}

sub edit_POST {
    my($self, $c, $id) = @_;
    my $discount = $c->model('DB::Discounts')->find({ id => $id });
    if (! $discount) {
        $c->message({ type => "error", message => "discount_code_not_found" });
        $self->status_not_found($c, message => "No such discount code");
        return 1;
    }

    my $data = $c->request->body_parameters;

    #TODO: validation

    $discount->update({
        portal_id => $data->{portal_id},
        percentage => $data->{percentage},
        expires => $data->{expires},
        description => $data->{description}
    });


    $c->message({ type => 'success', message => 'discount_code_updated' });
    $c->response->redirect($c->uri_for_action('/admin/discount/index'));
    return 1;
}

#
# Delete: delete a discount code
#

sub delete :Path('delete') Args(1) {
    my($self, $c, $id) = @_;
    my $discount = $c->model('DB::Discounts')->find({ id => $id});
    if (! $discount) {
        $c->message({ type => "error", message => "discount_code_not_found" });
        $self->status_not_found($c, message => "No such discount code");
    }
    else {
        $discount->delete;
        $c->message({ type => 'success', message => 'discount_code_deleted' });
    }
    $c->response->redirect($c->uri_for_action('/admin/discount/index'));
}


__PACKAGE__->meta->make_immutable;

1;
