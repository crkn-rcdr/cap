package CAP::Controller::View;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::View - Catalyst Controller

=cut

sub main :Private
{
    my($self, $c, $key) = @_;
    my $solr   = $c->stash->{solr};
    my $doc    = $c->forward('get_doc',   [$key]);
    my $hosted = $c->forward('is_hosted', [$doc]);

    # Redirect requests with a seq parameter to that page.
    if ($c->req->params->{seq}) {
        $c->res->redirect($c->uri_for('/view', $key, $c->req->params->{seq}));
    }

    # Redirect requests for page-level items to the parent object.
    if ($doc->{type} eq 'page') {
        my $parent = $doc->{pkey};
        if ($parent) {
            $c->res->redirect($c->uri_for('/view', $parent));
            $c->detach();
        }
        else {
            $c->detach('/error', [404, "Page document has no parent: $key"]);
        }
    }

    # Get some information about the parent item, if it exists.
    $c->stash->{response}->{parent} = $solr->document($doc->{pkey}, 'label', 'key', 'canonicalUri') if ($doc->{pkey});

    # Count the number of child documents and pages.
    $c->stash->{response}->{children} = {
        pages => $solr->count({pkey => $doc->{key}}, {type => 'page'}),
        docs  => $solr->count({pkey => $doc->{key}}, {type => 'document'}),
    };

    my $template;

    if ($hosted) {
        if ($doc->{type} eq 'series') {
            $template = 'view_sh.tt';
        }
        elsif ($doc->{type} eq 'document') {
            $template = 'view_dh.tt';
        }
    }
    else {
        if ($doc->{type} eq 'series') {
            $template = 'view_s.tt';
        }
        elsif ($doc->{type} eq 'document') {
            $template = 'view_d.tt';
        }
    }

    $c->stash->{template} = $template;
    return 1;
}

sub page :Private
{
    my($self, $c, $key, $seq) = @_;
    my $solr   =  $c->stash->{solr};
    my $doc    = $c->forward('get_doc',   [$key]);
    my $hosted = $c->forward('is_hosted', [$doc]);


    # If this document is not hosted by this portal, redirect to the basic
    # record view.
    if (! $hosted) {
        $c->res->redirect($c->uri_for('/view', $key));
        $c->detach();
    }

    # Retrieve the requested page.
    my $page = $solr->query({}, { type => 'page', field => { pkey => $key, seq => $seq } });
    $c->detach('/error', [404, "Page not found: seq $seq for $key"]) unless ($page->{documents}->[0]);

    $c->stash->{response}->{page} = $page->{documents}->[0];
    $c->stash->{template}         = 'view_ph.tt';
    return 1;
}

sub get_doc :Private
{
    my($self, $c, $key) = @_;
    my $solr =  $c->stash->{solr};
    my $doc = $solr->document($key);
    $c->detach('/error', [404, "Record not found: $key"]) unless ($doc);
    $c->stash->{response}->{doc} = $doc;
    $c->stash->{response}->{type} = 'object';
    return $doc;
}

sub is_hosted :Private
{
    my($self, $c, $doc) = @_;
    my $hosted = $c->stash->{hosted};
    return 1 if ($hosted->{contributor} && $doc->{contributor} eq $hosted->{contributor});
    return 0;
}

__PACKAGE__->meta->make_immutable;

