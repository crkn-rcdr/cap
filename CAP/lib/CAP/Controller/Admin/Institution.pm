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
        $c->message({ type => "error", message => "institution_not_found" });
        $self->status_not_found( $c, message => "No such institution");
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
sub edit :Chained('base') :PathPart('edit') :Args(0) ActionClass('REST') {
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




####################

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
    unless ($name) {
        $c->message({ type => "error", message => "institution_name_required" });
        $c->res->redirect($c->uri_for_action("/admin/institution/index"));
    }

    if ($c->model('DB::Institution')->code_exists($code)) {
        $c->message({ type => "error", message => "institution_code_exists" });
        $c->res->redirect($c->uri_for_action("/admin/institution/index"));
        return 1;
    }

    my $institution = $c->model('DB::Institution')->create({
        name => $name,
        code => $code,
    });
    $c->res->redirect($c->uri_for_action('admin/institution/edit', [$institution->id]));
}

#
# Edit: edit an existing institution
#

sub edit2 :Local Path('edit') Args(1) ActionClass('REST') {
    my($self, $c, $id) = @_;
}

sub edit2_GET {
    my($self, $c, $id) = @_;
    my $institution = $c->model('DB::Institution')->find({ id => $id });
    if (! $institution) {
        $c->message({ type => "error", message => "institution_not_found" });
        $self->status_not_found( $c, message => "No such institution");
        return 1;
    }
    
    #my @c_portals = $c->model("DB::Portal")->with_feature("contributors")->with_names($c->stash->{lang});
    #my @s_portals = $c->model("DB::Portal")->with_feature("institutions")->with_names($c->stash->{lang});
    #my %names = $c->model("DB::PortalString")->names($c->stash->{lang});
    my @contributed = ();
    foreach ($institution->search_related('contributors', { lang => $c->stash->{lang} })) {
        push @contributed, $_->get_column('portal_id');
    }
    my @subscriptions = ();
    foreach ($institution->search_related('institution_subscriptions')) {
        push @subscriptions, $_->get_column('portal_id');
    }

    $c->stash(
        entity => {
            id => $institution->id,
            name => $institution->name,
            code => $institution->code ? $institution->code : '',
            ip_addresses => $institution->ip_addresses,
            aliases => $institution->aliases,
            },
        #portal_names => \%names,
        #c_portals => \@c_portals,
        #s_portals => \@s_portals,
        contributed => \@contributed,
        subscriptions => \@subscriptions
    );

    $self->status_ok($c, entity => $c->stash->{entity});
    return 1;
}

sub edit2_POST {
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
            if ($institution->code ne $data{code} && $c->model('DB::Institution')->code_exists($data{code})) {
                $c->message({ type => "error", message => "institution_code_exists" });
                $c->res->redirect($c->uri_for_action("/admin/institution/edit", $id));
                return 1;
            }

            foreach my $key (grep(/^alias_/, keys(%data))) {
                if ($key =~ /^alias_(\w{2,3})/) {
                    $institution->set_alias($1, $data{$key});
                }
            }

            $institution->update({
                name => $data{name},
                code => $data{code} ? $data{code} : undef,
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

    $c->message({ type => "success", message => "institution_updated" });
    $c->res->redirect($c->uri_for_action("/admin/institution/edit", $id));
    return 1;
}


sub subscribe2 :Path('subscribe') Args(1) {
    my($self, $c, $id) = @_;
    my $institution = $c->model('DB::Institution')->find({ id => $id });
    $institution->find_or_create_related('institution_subscriptions', { portal_id => $c->req->body_params->{portal} });
    $c->message({ type => 'success', message => 'institution_subscribed' });
    $c->response->redirect($c->uri_for_action("/admin/institution/edit", $id));
    return 1;
}

sub delete_subscription :Path('delete_subscription') Args(1) {
    my($self, $c, $id) = @_;
    my $institution = $c->model('DB::Institution')->find({ id => $id });
    $institution->delete_related('institution_subscriptions', { portal_id => $c->req->params->{portal} });
    $c->message({ type => 'success', message => 'institution_unsubscribed' });
    $c->response->redirect($c->uri_for_action("/admin/institution/edit", $id));
    return 1;
}

#
# Contributor: edit contributor information for the institution
#

sub contributor :Path('contributor') Args(1) ActionClass('REST') {
}

sub contributor_GET {
    my($self, $c, $id) = @_;
    my $portal = $c->request->params->{portal};
    my $institution = $c->model('DB::Institution')->find($id);
    if (! $institution) {
        $c->message({ type => "error", message => "institution_not_found" });
        $self->status_not_found( $c, message => "No such institution");
        return 1;
    }

    $c->stash(entity => $institution->portal_contributor($portal));
}

sub contributor_POST {
    my($self, $c, $id) = @_;
    my %data = %{$c->req->body_params};

    my $institution = $c->model('DB::Institution')->find({ id => $id });
    if (! $institution) {
        $c->message({ type => "error", message => "institution_not_found" });
        $self->status_not_found( $c, message => "No such institution");
        return 1;
    }

    my @langs = ref($data{lang}) eq 'ARRAY' ? @{$data{lang}} : ($data{lang});
    my @urls = ref($data{url}) eq 'ARRAY' ? @{$data{url}} : ($data{url});
    my @descriptions = ref($data{description}) eq 'ARRAY' ? @{$data{description}} : ($data{description});


    foreach (0 .. (scalar(@langs) - 1)) {
        $institution->update_or_create_related('contributors', {
            portal_id => $data{portal},
            logo => $data{logo} ? 1 : 0,
            logo_filename => $data{logo_filename},
            lang => $langs[$_],
            url => $urls[$_],
            description => $descriptions[$_],
            });
    }
    $c->message({ type => "success", message => "contributor_updated" });
    $c->response->redirect($c->uri_for_action("/admin/institution/edit", $id));

    return 0;
}

sub delete_contributor :Path('delete_contributor') Args(1) {
    my ($self, $c, $id) = @_;
    my $portal = $c->request->params->{portal};
    my $institution = $c->model('DB::Institution')->find({ id => $id });
    if (! $institution) {
        $c->message({ type => "error", message => "institution_not_found" });
        $self->status_not_found( $c, message => "No such institution");
        return 1;
    }

    $institution->delete_related('contributors', { portal_id => $portal });
    $c->message({ type => "success", message => "contributor_deleted" });
    $c->response->redirect($c->uri_for_action("/admin/institution/edit", $id));
    return 0;
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
