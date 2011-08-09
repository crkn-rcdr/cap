package CAP::Controller::Admin;
use Moose;
use namespace::autoclean;
use Net::IP;

BEGIN {extends 'Catalyst::Controller'; }

sub auto :Private {
    my($self, $c) = @_;

    # Only allow administrators to access any of these functions. Everyone
    # else gets a 404.
    unless ($c->user_exists && $c->user->admin) {
        $c->response->redirect($c->uri_for('/index'));
        return 0;
    }
    return 1;
}

sub index :Path :Args(0) {
    my($self, $c) = @_;
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
    my $user;

    if ($id eq 'new') {
    }
    else {
        $user = $c->model('DB::User')->find({ id => $id });
    }

    if (! $user) {
        $c->detach('/error', [404, "No user matches identifier"]);
    }

    $c->stash->{user} = $user;

    if ($c->request->params->{update}) {
        if ($c->request->params->{update} eq 'user') {
            $user->update({
                username    => $c->request->params->{username},
                name        => $c->request->params->{name},
                confirmed   => $c->request->params->{confirmed},
                active      => $c->request->params->{active},
                admin       => $c->request->params->{admin},
                lastseen    => $c->request->params->{lastseen},
                subscriber  => $c->request->params->{subscriber},
                #subexpires  => $c->request->params->{subexpires},  # Can't just take a date string, must pass as Unix time INT
            });
        }
    }

    return 1;
}

sub users :Path('users') :Args(0) {
    my ($self, $c, $id) = @_;
    $c->stash->{users} = [$c->model('DB::User')->all];
    return 1;
}


sub institution :Path('institution') :Args(1) {
    my ($self, $c, $id) = @_;
    my $institution;

    if ($id eq 'new') {
        $institution = $c->model('DB::Institution')->create({ name =>  'New Institution' });
        $c->response->redirect($c->uri_for('/admin', 'institution', $institution->id));
    }
    else {
        $institution = $c->model('DB::Institution')->find({ id => $id });
    }

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

sub institutions :Path('institutions') :Args(0) {
    my($self, $c) = @_;
    $c->stash->{institutions} = [$c->model('DB::Institution')->all];
    return 1;
}


__PACKAGE__->meta->make_immutable;

