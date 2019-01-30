package CAP::Controller::Sitemap;
use Moose;
use namespace::autoclean;
use XML::LibXML;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Sitemap - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

Generate a sitemap page. Takes an argument "$n.xml" where $n is a number.

=cut
sub index :Path('') Args(1) {
    my($self, $c, $file) = @_;

    # Get the page number to generate from the file
    my($page, $suffix) = split(/\./, $file);
    unless ($page =~ /^\d+$/ && $page > 0 && $suffix eq 'xml') {
        $c->detach('/error', [500]);
    }

    my $titles;
    eval {
        $titles = $c->model('Access::Presentation')->title_list($c->portal_id, $page);
    };
    $c->detach('/error', [500, $@]) if $@;

    # Create the sitemap file
    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $root = $doc->createElement('urlset');
    $root->setAttribute('xmlns', 'http://www.sitemaps.org/schemas/sitemap/0.9');
    $doc->setDocumentElement($root);

    foreach my $title (@$titles) {
        my $url = $doc->createElement('url');
        my $loc = $doc->createElement('loc');

        $loc->appendChild($doc->createTextNode($c->uri_for_action('view/index', $title->{key})));
        $url->appendChild($loc);

        # Add an update time if there is one
        if ($title->{updated}) {
            my $lastmod = $doc->createElement('lastmod');
            $lastmod->appendChild($doc->createTextNode($title->{updated}));
            $url->appendChild($lastmod);
        }

        $root->appendChild($url);
    }

    $c->res->header('Content-Type', 'application/xml');
    $c->res->body($doc->toString(1));
    return 1;
}


=head 2 static

Generate the file of static pages for the site

=cut
sub static :Path('static.xml') Args(0) {
    my($self, $c) = @_;

    # Create the sitemap file
    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $root = $doc->createElement('urlset');
    $root->setAttribute('xmlns', 'http://www.sitemaps.org/schemas/sitemap/0.9');
    $root->setAttribute('xmlns:xhtml', 'http://www.w3.org/1999/xhtml');
    $doc->setDocumentElement($root);

    my $url = $doc->createElement('url');
    my $loc = $doc->createElement('loc');
    $loc->appendChild($doc->createTextNode($c->uri_for_action('index')));
    $url->appendChild($loc);
    $root->appendChild($url);

    my $nodes = $c->model('CMS')->sitemap($c->portal_id);
    foreach my $path (sort keys %$nodes) {
        $url = $doc->createElement('url');
        $loc = $doc->createElement('loc');
        $loc->appendChild($doc->createTextNode($c->uri_for("/$path")));
        $url->appendChild($loc);
        foreach my $alternate (@{ $nodes->{$path} }) {
            my $link = $doc->createElement('xhtml:link');
            $link->setAttribute('rel', 'alternate');
            $link->setAttribute('hreflang', $alternate->[0]);
            $link->setAttribute('href', $c->uri_for("/$alternate->[1]"));
            $url->appendChild($link);
        }
        $root->appendChild($url);
    }

    $c->res->header('Content-Type', 'application/xml');
    $c->res->body($doc->toString(1));
    return 1;
}


=head2 sitemapindex

Generate the sitemap index file

=cut
sub sitemapindex :Path('sitemap.xml') Args(0) {
    my($self, $c) = @_;
    my $map;
    my $loc;

    # Create the sitemap root file
    my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $root = $doc->createElement('sitemapindex');
    $root->setAttribute('xmlns', 'http://www.sitemaps.org/schemas/sitemap/0.9');
    $doc->setDocumentElement($root);

    # Add a link to the static sitemap
    $map = $doc->createElement('sitemap');
    $loc = $doc->createElement('loc');
    $loc->appendChild($doc->createTextNode($c->uri_for_action('sitemap/static')));
    $map->appendChild($loc);
    $root->appendChild($map);

    # Determine how many sitemap files we need
    my $map_length = $c->model('Access::Presentation')->sitemap_node_limit;
    my $title_count;
    eval {
        $title_count = $c->model('Access::Presentation')->title_count($c->portal_id);
    };
    $c->detach('/error', [500, $@]) if $@;

    for (my $i = 0; $title_count > 0; $title_count -= $map_length) {
        $map = $doc->createElement('sitemap');
        $loc = $doc->createElement('loc');
        $loc->appendChild($doc->createTextNode($c->uri_for_action('sitemap/index', [ sprintf("%d.xml", ++$i) ])));
        $map->appendChild($loc);
        $root->appendChild($map);
    }

    $c->res->header('Content-Type', 'application/xml');
    $c->res->body($doc->toString(1));
    return 1;
}


=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
