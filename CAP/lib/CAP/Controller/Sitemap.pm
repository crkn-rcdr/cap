package CAP::Controller::Sitemap;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Sitemap - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Find all document and series records for this portal.
    my $subset = $c->stash->{search_subset};
    my $query = $c->model('Solr')->query;
    $query->limit_type('default');
    my $resultset = $c->model('Solr')->search($subset)->query($query->to_string, options => { fl => "key,type,contributor,label,canonicalUri", rows => 0, sort => 'key asc' });
    my $hits = $resultset->hits;

    # Calculate the number of pages of results.
    my $results_per_page = 50;
    my $pages = int($hits / $results_per_page);
    ++$pages if ($hits % $results_per_page);

    my $out = "";
    for (my $i = 0; $i <= $pages; ++$i) {
        $out .= "<sitemap><loc>" . $c->uri_for_action('sitemap/page', [$i]) . "</loc></sitemap>\n";
    }

    $c->res->header('Content-Type' => 'application/xml');
    $c->response->body('<?xml version="1.0" encoding="UTF-8"?>' . "\n" . '<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n" . $out . "</sitemapindex>\n");
}

sub page :Path :Args(1) {
    my($self, $c, $page) = @_;
    $page = int($page); # TODO: check for /[^\d]/ and force to 0

    $c->res->header('Content-Type' => 'application/xml');

    if ($page == 0) {
        my $static = "<url><loc>static_url</loc></url>\n";
        $c->response->body('<?xml version="1.0" encoding="UTF-8"?>' . "\n" . '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">' . "\n" . $static . "</urlset>\n");
        return 1;
    }

    my $results_per_page = 50;

    # Get the current page of results
    my $subset = $c->stash->{search_subset};
    my $query = $c->model('Solr')->query;
    $query->limit_type('default');
    my $resultset = $c->model('Solr')->search($subset)->query($query->to_string, options => { fl => "key,type,contributor,label,canonicalUri", rows => $results_per_page, start => $results_per_page * ($page - 1), sort => 'key asc' });

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


=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
