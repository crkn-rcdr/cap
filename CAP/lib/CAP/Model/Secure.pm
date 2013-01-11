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

    # Don't do any secure/insecure routing if the secure host is not
    # configured.
    return unless ($c->config->{secure});

    my $secure_protocol = $c->config->{secure}->{protocol} || die("In cap.conf: missing protocol directive in <secure>");
    my $secure_host     = $c->config->{secure}->{host} || die("In cap.conf: missing host directive in <secure>");

    
    # Get the action path and determine if it needs to be secure.
    my $secure_action = 0;
    my $action_path = $c->action->private_path;
    foreach my $secure_path (qw( /user/ /admin/ /reports/ )) {
        if (substr($action_path, 0, length($secure_path)) eq $secure_path) {
            $secure_action = 1;
            last;
        }
    }

    # This request should be handled using the secure host
    if ($secure_action) {
        if ($c->req->uri->host eq $secure_host) {
            if ($c->session->{portal_host}) {
                return 1; # Process request
            }
            else {
                $c->detach('/error', [400, "Request to secure host with no source portal_host defined"]);
            }
        }
        else {
            $c->req->uri->scheme($secure_protocol);
            $c->req->uri->host($secure_host);
            $c->res->redirect($c->req->uri);
        }
    }

    # This request should be handled using the non-secure portal host
    else {
        if ($c->req->uri->host eq $secure_host) {
            if ($c->session->{portal_host}) {
                $c->req->uri->scheme('http');
                $c->req->uri->host($c->session->{portal_host});
                $c->res->redirect($c->req->uri);
            }
            else {
                $c->detach('/error', [400, "Attempt to redirect back to non-HTTPS site with no portal_host defined"]);
            }
        }
        else {
            return 1; # Process request
        }
    }

}

1;
