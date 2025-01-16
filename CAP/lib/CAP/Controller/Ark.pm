package CAP::Controller::Ark;
use Moose;
use namespace::autoclean;
use JSON qw(decode_json encode_json);
use LWP::UserAgent;

BEGIN { extends 'Catalyst::Controller'; }

__PACKAGE__->config(namespace => 'ark:');

# Receives an ARK parameter, calls the FastAPI service to retrieve the corresponding URL

sub index :Path('') :Args(2) {
    my ($self, $c, $naan, $noid) = @_;
    my $json = JSON->new->utf8->canonical->pretty;
    my $ark = "$naan/$noid";
    my $ark_resolver_base = $c->config->{ark_resolver_base};
    my $ark_resolver_endpoint = "ark:/$ark";
    my $ark_resolver_url = $ark_resolver_base . $ark_resolver_endpoint;

    # Initialize a UserAgent object
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    # Call ark-resolver to get a redirect url
    my $response = $ua->get($ark_resolver_url);
    if ($response->is_success) {
        my $data; 
        my $content = $response->decoded_content;
        eval {
            $data = $json->decode($content);
        };
        if ($@) {
            $c->detach('/error', [500, "JSON parsing error"]);
            return;
        }
        my $url = $data->{url};
        if ($url) {
            $c->response->redirect($url);
            $c->detach();
            return;
        } 
        else {
            $c->detach('/error', [500, "URL not found"]);
            return;
        }
        # $c->response->content_type('application/json');
        # $c->response->body($content);    
    }
    else {
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
