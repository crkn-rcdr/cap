package CAP::Controller::Sitemap;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Find all document and series records for this portal.
    my $subset = $c->stash->{search_subset};
    my $query = $c->model('Solr')->query;
    $query->limit_type('default');
    my $resultset = $c->model('Solr')->search($subset)->query($query->to_string, options => { fl => "key,type,contributor,label,canonicalUri", rows => 0, sort => 'key asc' });
    my $hits = $resultset->hits;

    # Calculate the number of pages of results.
    my $pages = int($hits / $c->config->{sitemap_url_limit});
    ++$pages if ($hits % $c->config->{sitemap_url_limit});

    my $out = "";
    for (my $i = 0; $i <= $pages; ++$i) {
        $out .= "<sitemap><loc>" . $c->uri_for_action('sitemap/page', [$i . ".xml"]) . "</loc></sitemap>\n";
    }

    $c->res->header('Content-Type' => 'application/xml');
    $c->response->body('<?xml version="1.0" encoding="UTF-8"?>' . "\n" . '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n" . $out . "</sitemapindex>\n");
}

sub page :Path :Args(1) {
    my($self, $c, $page) = @_;
    $page =~ /^(\d+)/;
    if ($1) { $page = int($1) } else { $page = 0 }

    $c->res->header('Content-Type' => 'application/xml');

    # The first page contains some static pages. TODO: this is really
    # messy; find a more elegant way to generate this.
    if ($page == 0) {
        my @urls = ();

        # The root url
        push(@urls, sprintf("<url><loc>%s</loc></url>", $c->uri_for_action('index')));

    
        # Support
        foreach my $support (keys(%{$c->stash->{support}})) {
            push(@urls, sprintf("<url><loc>%s</loc></url>", $c->uri_for_action('support', $support))) if
                $c->stash->{support}->{$support};
        }

        my $static = "<url><loc>static_url</loc></url>\n";
        $c->response->body('<?xml version="1.0" encoding="UTF-8"?>' . "\n" . '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n" . join("\n", @urls) . "</urlset>\n");
        return 1;
    }


    # Get the current page of results
    my $subset = $c->stash->{search_subset};
    my $query = $c->model('Solr')->query;
    $query->limit_type('default');
    my $resultset = $c->model('Solr')->search($subset)->query($query->to_string, options => { fl => "key,type,contributor,label,canonicalUri", rows => $c->config->{sitemap_url_limit}, start => $c->config->{sitemap_url_limit} * ($page - 1), sort => 'key asc' });

    my $out = "";
    foreach my $doc (@{$resultset->docs}) {
        $out .= "<url><loc>" . $c->uri_for_action('view/key', [$doc->key]) . "</loc></url>\n";
    }
    $c->response->body('<?xml version="1.0" encoding="UTF-8"?>' . "\n" . '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n" . $out . "</urlset>\n");
    return 1;

}


# Sort by key
# Don't facet
# Don't fetch parents, etc.


__PACKAGE__->meta->make_immutable;

1;
