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

sub get_url :Path("/ark:") Args(0) {
    my ($self, $c) = @_;
    $c->response->body(42);
    $c->detach()
  
}

__PACKAGE__->meta->make_immutable;

1;
