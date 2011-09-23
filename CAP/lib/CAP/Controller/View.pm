package CAP::Controller::View;
use Moose;
use namespace::autoclean;
use POSIX qw(strftime);

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

    # Redirect requests for page-level items to the parent object, or to
    # the page itself if this portal is the content host.
    if ($doc->{type} eq 'page') {
        my $parent = $doc->{pkey};
        if ($parent) {
            if ($hosted) {
                $c->res->redirect($c->uri_for('/view', $doc->{pkey}, $doc->{seq}));
            }
            else {
                $c->res->redirect($c->uri_for('/view', $parent));
                $c->detach();
            }
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

    # Get the first page of the item if the item is a hosted document
    if ($hosted && $doc->{type} eq 'document') {
        $c->stash->{response}->{first_page} = $c->forward('get_page', [$doc->{key}, 1]);
    }

    # Get the credit cost to purchase this document.
    $c->stash->{credit_cost} = $c->forward('/user/credit_cost', [$doc]);

    my $template;

    if ($hosted) {
        if ($doc->{type} eq 'series') {
            $template = 'view_sh.tt';
        }
        elsif ($doc->{type} eq 'document') {
            $c->stash->{access_level} = $c->forward('/user/access_level', [$doc]);
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
    my $page = $c->forward('get_page', [$key, $seq]);

    $c->stash->{template}         = 'view_ph.tt';
    $c->stash->{response}->{page} = $page;

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

sub get_page :Private
{
    my($self, $c, $key, $seq) = @_;
    my $solr = $c->stash->{solr};
    my $result = $solr->query({}, { type => 'page', field => { pkey => $key , seq => $seq } });
    my $page = $result->{documents}->[0];
    $c->detach('/error', [404, "Page not found: seq $seq for $key"]) unless ($page);

    # can we view the page at this size?
    my $size   = $c->config->{derivative}->{default_size};
    if ($c->req->params->{s} && $c->config->{derivative}->{size}->{$c->req->params->{s}}) {
        $size = $c->config->{derivative}->{size}->{$c->req->params->{s}};
    }

    $c->stash->{derivative_access} = $c->forward('/user/has_access', [$page, $key, 'derivative', $size]);
    $c->stash->{download_access} = $c->forward('/user/has_access', [$page, $key, 'download', $size]);
    return $page;
}

sub is_hosted :Private
{
    my($self, $c, $doc) = @_;
    my $hosted = $c->stash->{hosted};
    return 1 if ($hosted->{contributor} && $doc->{contributor} eq $hosted->{contributor});
    return 0;
}

# Perform user-related functions
#sub user_annotate :Private
#{
#    my($self, $c) = @_;
#    my $annotation = $c->request->params->{annotation} || "";
#    my $annotation_delete = $c->request->params->{annotation_delete} || "";
#    return 1 unless ($c->user_exists);
#
#    # Delete an old annotation
#    if ($annotation_delete) {
#        my $old_annotation = $c->model('DB::Annotation')->find({
#            id      => $annotation_delete,
#            user_id => $c->user->id
#        });
#
#        $old_annotation->delete if ($old_annotation);
#    }
#
#    # Save a user's new annotation
#    if ($annotation) {
#        $c->model('DB::Annotation')->create({
#            user_id     => $c->user->id,
#            record_key  => $c->stash->{response}->{page}->{key},
#            record_pkey => $c->stash->{response}->{page}->{pkey},
#            timestamp   => strftime("%Y-%m-%d %H:%M:%S", localtime(time())),
#            annotation  => $annotation
#        });
#    }
#
#    # Retrieve saved annotations
#    $c->stash->{annotations} = [ $c->model('DB::Annotation')->search({
#        user_id => $c->user->id,
#        record_key => $c->stash->{response}->{page}->{key}
#    })->all ];

#}

__PACKAGE__->meta->make_immutable;

