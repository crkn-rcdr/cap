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

    $c->stash(entity => {
        portal  => $portal,
        access => $portal->access,
        features => $portal->features,
        languages => [$portal->get_languages],
        hosts   => [$portal->hosts],
        subscriptions => [$portal->get_subscriptions]
    });

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


=head2 delete_host

Delete a hostname from this portal

=cut
sub delete_host : Chained('base') PathPart('delete_host') Args(1) ActionClass('REST') {
    my($self, $c, $host_id) = @_;
}

sub delete_host_GET {
    my($self, $c, $host_id) = @_;
    my $portal = $c->stash->{entity}->{portal};
    $portal->delete_host($host_id);
    $c->detach('/admin/portal/updated', ['tab_hostnames']);
}


=head2 canoncial_host

Set the hostname as canonical

=cut
sub canonical_host : Chained('base') PathPart('canonical_host') Args(1) ActionClass('REST') {
    my($self, $c, $host_id) = @_;
}

sub canonical_host_GET {
    my($self, $c, $host_id) = @_;
    my $portal = $c->stash->{entity}->{portal};
    $portal->canonical_hostname($host_id);
    $c->detach('/admin/portal/updated', ['tab_hostnames']);
}


=head2 create

Create a new portal with a random name (portal_###)

=cut
sub create :Path('create') {
    my($self, $c) = @_;
    my $portal = $c->model("DB::Portal")->new_portal;
    $c->res->redirect($c->uri_for_action('/admin/portal/index', [$portal->id]));
}

#
# Edit: edit an existing portal 
#

sub edit :Local Path('edit') Args(1) ActionClass('REST') {
    my($self, $c, $id) = @_;
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
    my $fragment = "";

    given ($data{update}) {
        when ('config') {
            $portal->update({
                id                      => $data{id},
                enabled                 => $data{enabled} ? 1 : 0,
                supports_users          => $data{supports_users} ? 1 : 0,
                supports_subscriptions  => $data{supports_subscriptions} ? 1 : 0,
                supports_institutions   => $data{supports_institutions} ? 1 : 0,
                supports_transcriptions => $data{supports_transcriptions} ? 1 : 0,
            });
            $fragment = 'tab_configuration';
        }
        when ('access') {
            foreach my $level (0, 1, 2) {
                my %access = ();
                foreach my $feature (qw(preview content metadata resize download purchase searching browse)) {
                    $access{$feature} = $data{"${feature}_$level"} if (defined($data{"${feature}_$level"}));
                }
                $portal->update_access($level, %access);
            }
            $fragment = 'tab_access';
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
            $fragment = 'tab_features';
        }
        when ('update_languages') {
            # TODO: validate...
            $portal->set_language($data{language_lang}, $data{language_priority}, $data{language_title}, $data{language_description});
            $fragment = 'tab_languages';
        }
        when ('new_host') {
            my $validation = $c->model("DB::PortalHost")->validate($data{new_host});
            if ($validation->{valid}) {
                $portal->create_related("portal_hosts", { id => $data{new_host} });
            } else {
                $c->message({ type => "error", message => $validation->{error} });
            }
            $fragment = 'tab_hostnames';
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

    my $uri = $c->uri_for_action("/admin/portal/index", [$portal->id]);
    $uri->fragment($fragment) if ($fragment);
    $c->res->redirect($uri);
    $c->detach();
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
    my $uri = $c->uri_for_action('admin/index');
    $uri->fragment('tab_portals');
    $c->res->redirect($uri);
    return 1;
}



=head2 updated

Methods that update a portal detach to here to check for success and to genereate messages.

=cut
sub updated :Private {
    my($self, $c, $fragment) = @_;
    my $portal = $c->stash->{entity}->{portal};

    my $uri = $c->uri_for_action('/admin/portal/index', [$portal->id]);
    $uri->fragment($fragment) if ($fragment);
    $c->res->redirect($uri);
    $c->detach();
}


__PACKAGE__->meta->make_immutable;

1;
