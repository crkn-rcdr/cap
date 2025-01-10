package CAP::Controller::Ark;
use Moose;
use namespace::autoclean;

use strict;
use warnings;

use JSON qw(decode_json);
use LWP::UserAgent;
use Try::Tiny;

BEGIN { extends 'Catalyst::Controller'; }

# Receives an ARK parameter, calls the FastAPI service to retrieve the corresponding URL

sub get_url :Path("/ark:") Args(1) {
    my ($self, $c, $ark) = @_;
    $c->log->debug("Entering get_url action with ARK: $ark");
    # Validate ARK
    unless ($ark =~ /^\d+\/[A-Za-z0-9]+$/) {
        $c->detach('/error', [400, "Invalid ark parameter"]);
        return;
    }
    
    my $ark_resolver_base = $c->config->{ark_resolver_base};
    my $ark_resolver_endpoint = "/ark:$ark";
    my $ark_resolver_url = $ark_resolver_base . $ark_resolver_endpoint;
    $c->log->debug("Constructed ARK resolver URL: $ark_resolver_url");
    # Initialize a UserAgent object
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    
    # Call ark-resolver endpoint
    $c->log->debug("Sending GET request to ARK resolver URL");
    my $response = $ua->get($ark_resolver_url);
    
    if ($response->is_success) {
        my $content = $response->decoded_content;
        my $data;
    
        # Parse JSON Response
        try {
            $data = decode_json($content);
        }
        catch {
            $c->detach("/error", [500, "Parse data error"]);
            return;
        };
    
        # Get return URL from ark resolver
        if ($data->{url}) {
            my $redirect_url = $data->{url};
            $c->log->debug("Redirecting to URL: $redirect_url");
            $c->response->redirect($redirect_url);
            $c->detach();
            return;
        }
        else {
            $c->detach('/error', [404, "URL not found for the provided ARK"]);
        }
    }
    else {
        $c->log->error("FastAPI request failed for ark: $ark - " . $response->status_line);
        if ($response->code == 404) {
            $c->detach('/error', [404, "ARK not found"]);
        }
        else {
            $c->detach('/error', [500, "FastAPI service error"]);
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
