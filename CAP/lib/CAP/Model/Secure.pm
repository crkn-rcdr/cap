package CAP::Model::Secure;

=head1 CAP::Model::Secure

Handles moving between http and https and between the secure site and individual portal sites.

=cut

use strict;
use warnings;
use Moose;
use MooseX::Method::Signatures;
use namespace::autoclean;
extends 'Catalyst::Model';

method routeRequest ($c) {

    my $secure_protocol = $c->config->{secure}->{protocol} || die("In cap.conf: missing protocol directive in <secure>");
    my $secure_host     = $c->config->{secure}->{host} || die("In cap.conf: missing host directive in <secure>");

    # If this is not the secure host, we need to forget any origin
    # information in the session.
    if ($c->req->uri->host ne $secure_host) {
        $c->session('origin' => undef);
    }

    # The secure host must handle https requests only (unless protcol is
    # http, in the case of local installs). Other hosts must only handle
    # http requests. Redirect requests with incorrect protocols.
    if ($secure_protocol eq 'https' && $c->req->uri->host eq $secure_host && ! $c->req->secure) {
        $c->req->uri->scheme('https');
        $c->res->redirect($c->req->uri);
        $c->detach();
    }
    elsif ($c->req->uri->host ne $secure_host && $c->req->secure) {
        $c->req->uri->scheme('http');
        $c->res->redirect($c->req->uri);
        $c->detach();
    }

    # Get the action path and determine if it needs to be secure.
    my $secure_action = 0;
    my $action_path = $c->action->private_path;
    foreach my $secure_path (qw( /user/ /admin/ /content/ /reports/ /institution/ )) {
        if (substr($action_path, 0, length($secure_path)) eq $secure_path) {
            $secure_action = 1;
            $c->stash->{secure_action} = 1;
            last;
        }
    }

    # This request should be handled using the secure host
    if ($secure_action > 0) {
        if ($c->req->uri->host eq $secure_host) {
            return 1; # Process request
        }
        else {
            # Record the portal and URI we came from
            $c->session('origin' => { portal => $c->portal->id, uri => $c->req->referer } );
            $c->req->uri->scheme($secure_protocol);
            $c->req->uri->host($secure_host);
            $c->res->redirect($c->req->uri);
            $c->detach();
        }
    }

    # Otherwise this request can be handled using either secure or non-secure
    return 1;

}

1;
