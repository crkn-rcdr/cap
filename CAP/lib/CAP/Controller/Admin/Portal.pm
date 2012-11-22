package CAP::Controller::Admin::Portal;
use Moose;
use namespace::autoclean;
use Encode;
use feature "switch";

__PACKAGE__->config(
    map => {
        'text/html' => [ 'View', 'Default' ],
    },
);

BEGIN { extends 'Catalyst::Controller::REST'; }


#
# Index: list portals 
#


sub index :Path :Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub index_GET {
    my($self, $c) = @_;
    my $list = {};
    foreach my $portal ($c->model("DB::Portal")->all()) {
        $list->{$portal->id} = {
            enabled => $portal->enabled,
        };
    }
    $c->stash->{entity} = $list;
    $self->status_ok($c, entity => $list);
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
    my @all_collections = $c->model('DB::Collection')->all();

    $c->stash(entity => {
        id => $portal->id,
        enabled => $portal->enabled,
        hosts => $portal->hosts(),
        collections => $portal->collections(),
        all_collections => \@all_collections,
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
        when ('update_portal') {
            $portal->update({
                enabled => $data{enabled} ? 1 : 0
            });
        } when ('delete_hosts') {
            my @list = to_list($data{delete_hosts});

            foreach my $host (@list) {
                my $record = $c->model("DB::PortalHost")->find({ id => $host });
                $record->delete() if ($record);
            }
        } when ('new_host') {
            my $validation = $c->model("DB::PortalHost")->validate($data{new_host});
            if ($validation->{valid}) {
                $portal->create_related("portal_hosts", { id => $data{new_host} });
            } else {
                $c->message({ type => "error", message => $validation->{error} });
            }
        } when ('update_collections') {
            my @collections = to_list($data{collections});
            my @hosted = to_list($data{hosted_collections});
            my @delete = to_list($data{delete_collections});
            foreach my $collection (@collections) {
                my $ss = $portal->search_related("portal_collections", { collection_id => $collection });
                if (grep /^$collection$/, @delete) {
                    $ss->delete();
                } else {
                    $ss->update({ hosted => (scalar(grep(/^$collection$/, @hosted)) ? 1 : 0) });
                }
            }
        } when ('new_collection') {
            $portal->find_or_create_related("portal_collections", {
                collection_id => $data{new_collection_id},
                hosted => defined($data{new_collection_hosted})
            });
        } default {
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
