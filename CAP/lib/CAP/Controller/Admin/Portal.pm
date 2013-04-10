package CAP::Controller::Admin::Portal;
use Moose;
use namespace::autoclean;
use Encode;
use feature "switch";

__PACKAGE__->config( map => { 'text/html' => [ 'View', 'Default' ] } );

BEGIN { extends 'Catalyst::Controller::REST'; }


sub base : Chained('/') PathPart('admin/portal') CaptureArgs(1) {
    my($self, $c, $portal_id) = @_;

    # Get the portal to view/edit
    my $portal = $c->model('DB::Portal')->find({ id => $portal_id });
    if (! $portal) {
        $c->message({ type => "error", message => "invalid_entity", params => ['portal'] });
        $self->status_not_found($c, message => "No such portal");
        $c->res->redirect($c->uri_for_action("/admin/index"));
        $c->detach();
    }

    $c->stash(entity => $portal);
    return 1;
}


sub index :Chained('base') PathPart('') Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub index_GET {
    my($self, $c) = @_;
    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

#
# Create: add a new portal
#

sub create :Path('create') {
    my($self, $c) = @_;
    my $id = $c->req->body_parameters->{id};
    my $portal = $c->model("DB::Portal")->find_or_create({ id => $id });
    $c->res->redirect($c->uri_for_action('/admin/portal/edit', $id));
}

#
# Edit: edit an existing portal 
#

sub edit :Local Path('edit') Args(1) ActionClass('REST') {
    my($self, $c, $id) = @_;
}

sub edit_GET {
    my($self, $c, $id) = @_;
    my $portal = $c->model('DB::Portal')->find({ id => $id });
    if (! $portal) {
        $c->message({ type => "error", message => "portal_not_found" });
        $self->status_not_found( $c, message => "No such portal");
        return 1;
    }

    $c->stash(entity => {
        id      => $portal->id,
        access  => $c->cap->build_entity($portal),
        features => $portal->features,
        languages => [$portal->get_languages],
        hosts   => $portal->hosts(),
        subscriptions => [$portal->get_subscriptions]
    });

    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

sub edit_POST {
    my($self, $c, $id) = @_;
    my $portal = $c->model('DB::Portal')->find({ id => $id });
    if (! $portal) {
        $c->message({ type => "error", message => "portal_not_found" });
        $self->status_not_found( $c, message => "No such portal");
        return 1;
    }

    my %data = %{$c->req->body_params};

    given ($data{update}) {
        when ('access') {
            $portal->update({
                enabled         => $data{enabled} ? 1 : 0,
                users           => $data{users} ? 1 : 0,
                subscriptions   => $data{subscriptions} ? 1 : 0,
                institutions    => $data{institutions} ? 1 : 0,
                access_preview  => $data{access_preview},
                access_all      => $data{access_all},
                access_resize   => $data{access_resize},
                access_download => $data{access_download},
                access_purchase => $data{access_purchase},
            });
        }
        when ('delete_hosts') {
            my @list = to_list($data{delete_hosts});

            foreach my $host (@list) {
                my $record = $c->model("DB::PortalHost")->find({ id => $host });
                $record->delete() if ($record);
            }
        }
        when ('update_features') {
            foreach my $feature (qw(contributors random_doc)) {
                if ($data{"feature_$feature"}) {
                    $portal->add_feature($feature);
                }
                else {
                    $portal->remove_feature($feature);
                }
            }
        }
        when ('update_languages') {
            # TODO: validate...
            $portal->set_language($data{language_lang}, $data{language_priority}, $data{language_title});
        }
        when ('new_host') {
            my $validation = $c->model("DB::PortalHost")->validate($data{new_host});
            if ($validation->{valid}) {
                $portal->create_related("portal_hosts", { id => $data{new_host} });
            } else {
                $c->message({ type => "error", message => $validation->{error} });
            }
        }
        when ('new_subscription') {
            my $validation = $c->model('DB::PortalSubscriptions')->validate(%data);
            if ($validation->{valid}) {
                $portal->create_related("portal_subscriptions", {
                    id => $data{subscription_id},
                    level => $data{subscription_level},
                    duration => $data{subscription_duration},
                    price => $data{subscription_price}
                });
            }
            else {
                foreach my $error (@{$validation->{errors}}) {
                    $c->message({ type => "error", message => $error });
                }
            }
        }
        default {
            warn "No update parameter passed";
        }
    }

    $c->res->redirect($c->uri_for_action("/admin/portal/edit", $id));
    return 1;
}

sub to_list {
    my $ref = shift;
    return () unless defined($ref);
    return (ref($ref) eq 'ARRAY') ? @{$ref} : ($ref);
}

#
# Delete: remove a portal
#

sub delete :Path('delete') Args(1) {
    my($self, $c, $id) = @_;
    my $portal = $c->model('DB::Portal')->find({ id => $id });
    if ($portal) {
        $portal->delete();
        $c->message({ type => "success", message => "portal_deleted" });
    }
    else {
        $c->message({ type => "error", message => "portal_not_found" });
    }
    $c->res->redirect($c->uri_for_action('admin/portal/index'));
    return 1;
}


__PACKAGE__->meta->make_immutable;

1;
