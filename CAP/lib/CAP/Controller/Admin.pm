package CAP::Controller::Admin;
use Moose;
use namespace::autoclean;
use Net::IP;
use feature "switch";

BEGIN {extends 'Catalyst::Controller'; }

sub auto :Private {
    my($self, $c) = @_;

    # Require SSL for all operations
    $c->require_ssl;

    # Only allow administrators to access any of these functions. Everyone
    # else gets a 404.
    unless ($c->user_exists && $c->user->admin) {
        $c->session->{login_redirect} = $c->req->uri;
        $c->response->redirect($c->uri_for('/user', 'login'));
        return 0;
    }

    return 1;
}

sub index :Path :Args(0) {
    my($self, $c) = @_;
    $c->stash->{users} = $c->model('DB::User')->count;
    $c->stash->{subscribers} = $c->model('DB::User')->subscribers;
    return 1;
}

#
# Institution functions
#

# List current institutions
sub institutions :Path('list/institutions') :Args(0) {
    my($self, $c) = @_;
    $c->stash->{institutions} = [$c->model('DB::Institution')->all];
    return 1;
}

# Create a new institution, then forward to the edit institution page.
sub create_institution :Path('create/institution') {
    my($self, $c, $id) = @_;
    my $institution = $c->model('DB::Institution')->create({});
    $c->res->redirect($c->uri_for_action('admin/edit_institution', [$institution->id]));
}

# Edit an institution
sub edit_institution :Path('edit/institution') :Args(1) {
    my ($self, $c, $id) = @_;
    my $institution;

    $institution = $c->model('DB::Institution')->find({ id => $id });

    if (! $institution) {
        $c->detach('/error', [404, "No institution matches identifier"]);
    }

    $c->stash->{institution} = $institution;

    if ($c->request->params->{update}) {
        if ($c->request->params->{update} eq 'institution') {
            $institution->update({
                name       => $c->request->params->{name},
                subscriber => $c->request->params->{subscriber},
            });
        }
        elsif ($c->request->params->{update} eq 'collection_add') {
            $c->model('DB::InstitutionCollection')->sponsor_collection($institution->id, $c->request->params->{collection});
        }
        elsif ($c->request->params->{update} eq 'collection_delete') {
            if (ref($c->request->params->{collection}) eq 'ARRAY') {
                $c->model('DB::InstitutionCollection')->unsponsor_collection(@{$c->request->params->{collection}});
            }
            else {
                $c->model('DB::InstitutionCollection')->unsponsor_collection($c->request->params->{collection});
            }
        }
        elsif ($c->request->params->{update} eq 'ip_add') {
            my $ip_addr = Net::IP->new($c->request->params->{address});
            my $cidr = $ip_addr->print();
            my $start = $ip_addr->intip();
            my $end = $ip_addr->last_int();

            # Make sure we don't overlap with an existing range.
            foreach my $row ($c->model('DB::InstitutionIpaddr')->all) {
                my $db_addr = Net::IP->new($row->cidr);
                if ($ip_addr->version eq $db_addr->version) {
                    if ($ip_addr->overlaps($db_addr) != $IP_NO_OVERLAP) {
                        die("Address overlaps with " . $row->cidr . "\n");
                    }
                }
            }

            # Try to add the address range
            $c->model('DB::InstitutionIpaddr')->create({
                cidr           => $cidr,
                institution_id => $institution->id,
                start          => $start,
                end            => $end,
            });
        }
        elsif ($c->request->params->{update} eq 'ip_delete') {
            if (ref($c->request->params->{address}) eq 'ARRAY') {
                $c->model('DB::InstitutionIpaddr')->delete_address(@{$c->request->params->{address}});
            }
            else {
                $c->model('DB::InstitutionIpaddr')->delete_address($c->request->params->{address});
            }
        }
        elsif ($c->request->params->{update} eq 'delete') {
            $institution->delete;
            $c->response->redirect($c->uri_for('/admin'));
            return 0;
        }

    }

    # Fetch a list of IP addresses that belong to this institution and
    # sponsored collections
    $c->stash->{ip_addresses} = $c->model('DB::InstitutionIpaddr')->ip_for_institution($institution->id);
    $c->stash->{sponsored_collections} = $c->model('DB::InstitutionCollection')->sponsored_collections($institution->id);

    return 1;
}





sub collections :Path('collections') :Args(0) {
    my($self, $c, $id) = @_;

    if ($c->request->params->{update}) {
        if ($c->request->params->{update} eq 'collection') {
            my $collection = $c->model('DB::Collection')->find({ id => $c->request->params->{id} });
            if ($collection) {
                $collection->update({
                    price => $c->request->params->{price},
                });
            }
        }
        elsif ($c->request->params->{update} eq 'add_collection') {
            $c->model('DB::Collection')->create({
                id    => $c->req->params->{id},
                price => $c->req->params->{price},
            });
        }
    }

    # Get a list of all collections
    $c->stash->{collections} = [$c->model('DB::Collection')->all];

    return 1;
}

sub user :Path('user') :Args(1) {
    my ($self, $c, $id) = @_;
    given($c->request->method) {
        when ("GET") {
            if ($id eq 'new') {
                $c->stash->{template} = "admin/user_new.tt";
            } else {
                my $user = $c->model('DB::User')->find({ id => $id });
                $c->detach($c->uri_for_action("error"), [404, "No user with id #" . $id]) if (!$user);
                $c->stash->{user} = $user;
            }
        } when ("POST") {
            if ($id eq 'new') {
                #$c->model('DB::User')->create($c->forward("user_attributes_from_params"));
                $c->message({ type => "error", message => "Would have created a new user, but I'm not sure how to go about doing this just yet." });
                $c->response->redirect($c->uri_for_action("admin/users"));
            } else { # would love to use PUT here but we need Catalyst::Action::REST for that
                my $user = $c->model('DB::User')->find({ id => $id });
                $c->detach($c->uri_for_action("error"), [404, "No user with id #" . $id]) if (!$user);
                $user->update($c->forward("user_attributes_from_params"));
                $c->response->redirect($c->uri_for_action("admin/users"));
            }
        } default {
            $c->detach($c->uri_for_action("error"), [404, "Invalid admin/user request"]);
        }
    }

    return 1;
}

sub user_attributes_from_params :Private {
    my ($self, $c) = @_;
    my $attributes = {
        username    => $c->request->params->{username},
        name        => $c->request->params->{name},
        confirmed   => ($c->request->params->{confirmed} ? 1 : 0),
        active      => ($c->request->params->{active} ? 1 : 0),
        admin       => ($c->request->params->{admin} ? 1 : 0),
    };
    $attributes->{subexpires} = join(" ", $c->request->params->{subexpires}, "00:00:00") if ($c->request->params->{subscriber});
    return $attributes;
}

sub users :Path('users') :Args(0) {
    my ($self, $c, $id) = @_;
    my $rs = $c->model('DB::User');
    $c->stash->{users} = [$rs->all];
    return 1;
}

sub promocodes :Path('promocodes') :Args(0) {
    my($self, $c) = @_;

    # TODO: this does not do ANY validity checking...
    if ($c->req->params->{action} eq 'add') {
        $c->model('DB::Promocode')->create({
            id => $c->req->params->{id},
            expires => $c->req->params->{expires},
            amount => $c->req->params->{amount},
        });

    }

    $c->stash->{promocodes} = [$c->model('DB::Promocode')->all];

    return 1;
}


__PACKAGE__->meta->make_immutable;

