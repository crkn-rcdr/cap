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
    # information in the session. Otherwise, we want to remember the
    # referring portal and URL, provided that it is also not the secure
    # host.
    if ($c->req->uri->host ne $secure_host) {
        #warn sprintf("Host is %s, so unsetting origin", $c->req->uri->host);
        $c->session('origin' => undef);
    }
    elsif ($c->req->referer) {

        # Get the referer host and domain name.
        my $referer = $c->req->referer; $referer =~ s#.*://##; $referer =~ s#[:/?].*##;
        my($ref_host, $ref_domain) = split(/\./, $referer, 2);
        #warn "Referer URL is $referer. Host is $ref_host. Domain is $ref_domain";

        # If the referer is not the secure host, check to see if it is
        # from a portal within our domain.
        if ($referer ne $secure_host) {

            # Get our host and domain name.
            my($my_host, $my_domain) = split(/\./, $c->req->uri->host, 2);
            #warn "My host is $my_host. Domain is $my_domain";

            # See if the domains match. If they do, and if there is a portal
            # that maps to the referer's host, then we conclude that the
            # request came from one of our non-secure portals. If this is the
            # case, we must remember the portal name and URL.
            if ($my_domain eq $ref_domain) {
                #warn("The domains are the same, so we check the portal name");
                if ($c->model('DB::PortalHost')->find($ref_host)) {
                    #warn("Found a portal for $ref_host so we remember the referer");
                    $c->session('origin' => { portal => $ref_host, uri => $c->req->referer || undef } );
                }
            }
        }

    }
    else {
        #warn "Arrived at secure host with no referer";
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
    foreach my $secure_path (qw( /user/ /admin/ /content/ /reports/ /institution/ /cms/ )) {
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
