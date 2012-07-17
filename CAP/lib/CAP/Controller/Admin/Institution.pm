package CAP::Controller::Admin::Institution;
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
# Index: list institutions
#


sub index :Path :Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub index_GET {
    my($self, $c) = @_;
    my $list = {};
    my $institutions = [$c->model('DB::Institution')->search({}, { order_by => 'name' })];
    foreach my $institution (@{$institutions}) {
        $list->{$institution->name} = {
            code => $institution->code ? $institution->code : '',
            subscriber => $institution->subscriber,
            url => $c->uri_for_action('admin/institution/edit', [$institution->id])->as_string(),
        };
    }
    $c->stash->{entity} = $list;
    $self->status_ok($c, entity => $list);
    return 1;
}

sub batch :Path('batch') :Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub batch_GET {
    my($self, $c) = @_;
    $c->stash->{export} = $c->model('DB::Institution')->export(sort keys %{$c->config->{languages}});
    return 0;
}

sub batch_POST {
    my($self, $c) = @_;
    my $data = $c->req->body_parameters->{data};
    my $txn = $c->model('DB::Institution')->import($data, sort keys %{$c->config->{languages}});
    eval { $c->model('DB')->txn_do($txn); };
    $c->detach("/error", [500]) if ($@);

    $c->response->redirect($c->uri_for_action("/admin/institution/batch"));
    return 0;
}

#
# Create: add a new institution
#

sub create :Path('create') {
    my($self, $c) = @_;
    my $name = $c->req->body_parameters->{name};
    my $code = $c->req->body_parameters->{code} ? $c->req->body_parameters->{code} : undef;
    my $subscriber = $c->req->body_parameters->{subscriber} ? 1 : 0;
    unless ($name) {
        $c->message({ type => "error", message => "institution_name_required" });
        $c->res->redirect($c->uri_for_action("/admin/institution/index"));
    }

    my $institution = $c->model('DB::Institution')->create({
        name => $name,
        code => $code,
        subscriber => $subscriber,
    });
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

    $c->stash(entity => {
        id => $institution->id,
        name => $institution->name,
        code => $institution->code ? $institution->code : '',
        subscriber => $institution->subscriber,
        ip_addresses => $institution->ip_addresses,
        aliases => $institution->aliases,
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

    my %data = %{$c->req->body_params};

    given ($data{update}) {
        when ('update_institution') {
            foreach my $key (grep(/^alias_/, keys(%data))) {
                if ($key =~ /^alias_(\w{2,3})/) {
                    $institution->set_alias($1, $data{$key});
                }
            }

            $institution->update({
                name => $data{name},
                code => $data{code} ? $data{code} : undef,
                subscriber => $data{subscriber} ? 1 : 0
            });
        } when ('delete_ip') {
            $c->model('DB::InstitutionIpaddr')->delete_address($data{delete_ip_range});
        } when ('new_ip') {
            $data{new_ip_range} =~ s/^\s+//;
            $data{new_ip_range} =~ s/\s+$//;
            foreach my $range (split(/\s+/, $data{new_ip_range})) {
                my $conflict;
                if (! $c->model('DB::InstitutionIpaddr')->add($institution->id, $range, \$conflict)) {
                    if ($conflict) {
                        $c->message(Message::Stack::Message->new(level => "error", msgid => "ip_range_conflict", params => [$range, $conflict]));
                    } else {
                        $c->message({ type => "error", message => "ip_range_error" });
                    }
                }
            }
        } default {
            warn "No update parameter passed";
        }
    }

    $c->res->redirect($c->uri_for_action("/admin/institution/edit", $id));
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
