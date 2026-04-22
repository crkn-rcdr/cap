package CAP::Utils::ArkURL;

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use URI;
use Exporter 'import';

# Allow exporting the get_ark_url function
our @EXPORT_OK = qw(get_ark_url);

# get_ark_url receives the Catalyst context $c and a record_key
sub get_ark_url {
    my ($c, $record_key) = @_;
    return unless $record_key;

    my $ark;
    my $json = JSON->new->utf8->canonical->pretty;
    my $ark_resolver_base     = $c->config->{ark_resolver_base};
    my $ark_resolver_endpoint = "slug";
    my $ark_resolver_url      = $ark_resolver_base . $ark_resolver_endpoint;

    # Initialize a UserAgent object
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);

    # Build query parameters
    my %query_params = ( slug => $record_key );
    my $ark_url_query = URI->new($ark_resolver_url);
    $ark_url_query->query_form(%query_params) if %query_params;

    # Call the Ark-resolver API to retrieve the ark
    eval {
        my $response = $ua->get($ark_url_query);
        if ($response->is_success) {
            my $content = $response->decoded_content;
            my $data    = $json->decode($content);
            $ark = $data->{data}->{ark};
        }
        1;
    } or do {
        $c->stash->{ark_no_found} = "Persistent URL unavailable";
        return;
    };

    unless ($ark){
    $c->stash->{ark_no_found} = "Persistent URL unavailable";
    }
    # Return undef if ark was not retrieved
    return unless $ark;

    # Build the final Persistent URL
    my $ark_url = "https://n2t.net/ark:/" . $ark;
    return $ark_url;
}

1;
