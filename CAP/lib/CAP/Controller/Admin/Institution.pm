package CAP::Controller::Admin::Institution;
use Moose;
use namespace::autoclean;
use Encode;
use feature "switch";
use List::MoreUtils qw/ uniq /;

__PACKAGE__->config( map => { 'text/html' => [ 'View', 'Default' ] } );

BEGIN { extends 'Catalyst::Controller::REST'; }

sub base : Chained('/') PathPart('admin/institution') CaptureArgs(1) {
    my($self, $c, $institution_id) = @_;

    # Get the institution to view/edit
    my $institution = $c->model('DB::Institution')->find({ id => $institution_id });
    if (! $institution) {
        $c->message({ type => "error", message => "invalid_entity", params => ['institution'] });
        $self->status_not_found($c, message => "No such institution");
        $c->res->redirect($c->uri_for_action("/admin/index"));
        $c->detach();
    }

    # Get a list of subscribable portals and the institution's
    # subscription status for each.
    my @subscriptions = ();
    foreach my $portal ($c->model('DB::Portal')->list_subscribable) {
        my $subscribed = $institution->subscribes_to($portal);
        push(@subscriptions, { portal => $portal, subscribed => $subscribed });
    }

    $c->stash(
        entity => {
            institution => $institution,
            aliases => [$institution->aliases],
            subscriptions => \@subscriptions,
            ipaddresses => [$institution->ip_addresses]
        },
        data => $c->req->body_params
    );
    return 1;
}


=head2 index

Display the institution for editing.

=cut
sub index :Chained('base') :PathPart('') :Args(0) {
    my($self, $c) = @_;
    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}


=head2 edit

Edit the basic institution information (name, code).

=cut
sub edit : Chained('base') PathPart('edit') Args(0) ActionClass('REST') {
    my ($self, $c) = @_;
}

sub edit_POST {
    my($self, $c) = @_;
    my $institution = $c->stash->{entity}->{institution};
    my $data = $c->stash->{data};
    $c->stash( update => $institution->update_if_valid($data));
    $c->detach('/admin/institution/updated');
}

=head2 alias

Edit or create an institution alias.

=cut
sub alias : Chained('base') PathPart('alias') Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub alias_POST {
    my($self, $c) = @_;
    my $institution = $c->stash->{entity}->{institution};
    my $data = $c->stash->{data};
    $c->stash(update => $institution->update_alias_if_valid($data));
    $c->detach('/admin/institution/updated');
}


=head2 alias_delete

Delete an alias for the specified language

=cut
sub alias_delete : Chained('base') PathPart('alias_delete') Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub alias_delete_GET {
    my($self, $c) = @_;
    my $institution = $c->stash->{entity}->{institution};
    my $data = $c->req->params;
    $c->stash(update => $institution->delete_alias($data));
    $c->detach('/admin/institution/updated');
}


=head2 subscribe

Subscribe to the selected portal

=cut
sub subscribe : Chained('base') PathPart('subscribe') Args(1) ActionClass('REST') {
    my($self, $c, $portal_id) = @_;
}

sub subscribe_GET {
    my($self, $c, $portal_id) = @_;
    my $institution = $c->stash->{entity}->{institution};
    my $portal = $c->model('DB::Portal')->find({id => $portal_id});
    $c->stash(update => $institution->subscribe_if_exists({ portal => $portal }));
    $c->detach('/admin/institution/updated');
}


=head2 subscribe_delete

Remove a subscription to the selected portal

=cut
sub subscribe_delete : Chained('base') PathPart(subscribe_delete) Args(1) ActionClass('REST') {
    my($self, $c, $portal_id) = @_;
}

sub subscribe_delete_GET {
    my($self, $c, $portal_id) = @_;
    my $institution = $c->stash->{entity}->{institution};
    my $portal = $c->model('DB::Portal')->find({id => $portal_id});
    $c->stash(update => $institution->unsubscribe({ portal => $portal }));
    $c->detach('/admin/institution/updated');
}


=head2 ipaddress

Add an IP address range

=cut
sub ipaddress : Chained('base') PathPart(ipaddress) Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub ipaddress_POST {
    my($self, $c) = @_;
    my $institution = $c->stash->{entity}->{institution};
    my $data = $c->stash->{data};
    $c->stash(update => $institution->add_ipaddress_if_valid($data));
    $c->detach('/admin/institution/updated');
}


=head2 ipaddress_delete

Delete an IP address range based on its base address

=cut
sub ipaddress_delete : Chained('base') PathPart(ipaddress_delete) Args(1) ActionClass('REST') {
    my($self, $c, $start) = @_;
}

sub ipaddress_delete_GET {
    my($self, $c, $start) = @_;
    my $institution = $c->stash->{entity}->{institution};
    $c->stash(update => $institution->delete_ipaddress({ start => $start }));
    $c->detach('/admin/institution/updated');
}


=head2 updated

Methods that update an institution detach to here to check for success and to genereate messages.

=cut
sub updated :Private {
    my($self, $c) = @_;
    my $update = $c->stash->{update};
    my $institution = $c->stash->{entity}->{institution};

    if ($update->{valid}) {
        $c->message({ type => "success", message => "update_ok", params => [ $institution->name ] });
        $self->status_ok($c, entity => $c->stash->{entity});
    }
    else {
        foreach my $error (@{$update->{errors}}) {
            $c->message({ type => "error", %{$error} });
        }
        $self->status_bad_request($c, message => "Input is invalid");
    }

    $c->res->redirect($c->uri_for_action('/admin/institution/index', [$institution->id]));
    $c->detach();
}

__PACKAGE__->meta->make_immutable;




=head2 create

Create a new institution

=cut

sub create : Path('/institution/create') Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub create_GET {
    my($self, $c) = @_;
    my $institution = $c->model('DB::Institution')->create({});
    $c->res->redirect($c->uri_for_action('/admin/institution/index', [$institution->id]));
    $c->detach();
}

1;
