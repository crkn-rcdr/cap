package CAP::Controller::Admin::Institution;
use Moose;
use namespace::autoclean;

__PACKAGE__->config(
    map => {
        'text/html' => [ 'View', 'Default' ],
    },
);

BEGIN { extends 'Catalyst::Controller::REST'; }


#
# Index: list institutions
#


sub index :Path :Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub index_GET {
    my($self, $c) = @_;
    my $list = {};
    my $institutions = [$c->model('DB::Institution')->all];
    $c->stash->{institutions} = $institutions;
    foreach my $institution (@{$institutions}) {
        $list->{$institution->id} = {
            name => $institution->name,
            url => "" . $c->uri_for_action('admin/institution/edit', [$institution->id]), # "" forces object into a string
        };
    }
    $self->status_ok($c, entity => $list);
    return 1;
}

#
# Create: add a new institution
#

sub create :Path('create') {
    my($self, $c) = @_;
    my $institution = $c->model('DB::Institution')->create({});
    $c->res->redirect($c->uri_for_action('admin/institution/edit', [$institution->id]));
}

#
# Edit: edit an existing institution
#

sub edit :Local Path('edit') Args(1) ActionClass('REST') {
    my($self, $c, $id) = @_;
}

sub edit_GET {
    my($self, $c, $id) = @_;
    my $institution = $c->model('DB::Institution')->find({ id => $id });
    if (! $institution) {
        $c->message({ type => "error", message => "institution_not_found" });
        $self->status_not_found( $c, message => "No such institution");
        return 1;
    }

    my $ip_addresses = $c->model('DB::InstitutionIpaddr')->ip_for_institution($institution->id);

    $c->stash(entity => {
        id => $institution->id,
        name => $institution->name,
        subscriber => $institution->subscriber,
        ip_addresses => $ip_addresses,
    });

    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

sub edit_POST {
    my($self, $c, $id) = @_;
    my $institution = $c->model('DB::Institution')->find({ id => $id });
    if (! $institution) {
        $c->message({ type => "error", message => "institution_not_found" });
        $self->status_not_found( $c, message => "No such institution");
        return 1;
    }

    my %data = (%{$c->req->params}); # FIXME: The docs seem to say $c->req->data should work, but it doesn't get defined anywhere

    # Normalize parameters and set defaults.
    $data{name} = $institution->name unless (defined($data{name}));
    $data{subscriber} = $institution->subscriber unless (defined($data{subscriber}) && ($data{subscriber} == 0 || $data{subscriber} == 1));

    # Update the institution record.
    $institution->update({
        name => $data{name},
        subscriber => $data{subscriber},
    });

    # Add a new IP address range
    if ($data{new_ip_range}) {
        my $conflict;
        if (! $c->model('DB::InstitutionIpaddr')->add($institution->id, $data{new_ip_range}, \$conflict)) {
            if ($conflict) {
                $c->message(Message::Stack::Message->new(level => "error", msgid => "ip_range_conflict", params => [$data{new_ip_range}, $conflict]));
            }
            else {
                $c->message({ type => "error", message => "ip_range_error" });
            }
        }
    }

    # Delete IP address ranges
    if ($data{delete_ip_range}) {
        $c->model('DB::InstitutionIpaddr')->delete_address($data{delete_ip_range});
    }
    

    # Create a response entity
    $c->stash( entity => {
        id => $institution->id,
        name => $institution->name,
        subscriber => $institution->subscriber,
        ip_addresses => $c->model('DB::InstitutionIpaddr')->ip_for_institution($institution->id),
    });

    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

#
# Delete: remove an institution
#

sub delete :Path('delete') Args(1) {
    my($self, $c, $id) = @_;
    my $institution = $c->model('DB::Institution')->find({ id => $id });
    if ($institution) {
        $institution->delete;
        $c->message({ type => "success", message => "institution_deleted" });
    }
    else {
        $c->message({ type => "error", message => "institution_not_found" });
    }
    $c->res->redirect($c->uri_for_action('admin/institution/index'));
    return 1;
}


__PACKAGE__->meta->make_immutable;

1;
