package CAP::Controller::Ark;
use Moose;
use namespace::autoclean;
use JSON qw(decode_json encode_json);
use LWP::UserAgent;
use URI;

BEGIN { extends 'Catalyst::Controller'; }

#__PACKAGE__->config(namespace => 'ark:');

# Receives an ARK parameter, calls the FastAPI service to retrieve the corresponding URL

sub index :Path('/ark:/69429/foobar') :Args(2) {
    my ($self, $c, $naan, $noid) = @_;
    my $json = JSON->new->utf8->canonical->pretty;
    my $user_agent = $c->request->user_agent;
    my $client_ip = $c->request->address;
    
    # Load COUNTER bots for check
    my $counter_robots_file = '/opt/cap/CAP/conf/COUNTER_Robots_list.txt';
    my @bot_patterns = grep { $_ !~ /^\s*#/ && $_ ne '' } read_file($counter_robots_file, chomp => 1);
    foreach my $pattern (@bot_patterns) {
        if ($user_agent =~ /\Q$pattern\E/i) {
            $c->response->body('Access denied for web scrapers.');
            return;
        }
    }
    #if ($client_ip eq '47.82.60.48' || $client_ip eq '47.82.60.157') {
    #    $c->response->body('Access denied for suspicious IP.');
    #    return;
    #}
    my $ark = "$naan/$noid";
    my $ark_resolver_base = $c->config->{ark_resolver_base};
    my $ark_resolver_endpoint = "ark:/$ark";
    my $ark_resolver_url = $ark_resolver_base . $ark_resolver_endpoint;
  
    # Initialize a UserAgent object
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    # Get subfix from domain host if it exists
    my $current_host = $c->request->uri->host;
    my @split_parts = split /\./,$current_host;
    my $first_part = $split_parts[0];
    my $subfix;
    if ($first_part =~ /-([^-]+)/) {
        $subfix = $1
    }

    # Build a query param
    my %query_params = ();
    if (defined $subfix ){
        $query_params{q} = $subfix;
    }

    # Build an url with a query params
    my $ark_url_query = URI->new($ark_resolver_url);
    $ark_url_query->query_form(%query_params) if %query_params; 
    
    # Call ark-resolver to get a redirect url
    my $response = $ua->get($ark_url_query);
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
        } 
        else {
            $c->detach('/error', [500, "URL not found"]);
            return;
        }
         
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
