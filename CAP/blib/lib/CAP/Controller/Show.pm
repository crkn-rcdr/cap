package CAP::Controller::Show;

use strict;
use warnings;
use parent 'Catalyst::Controller';

sub show : Chained('/base') PathPart('show') Args()
{
    my($self, $c, $key, $start) = @_;
    $start = 1 unless ($start);

    my $solr = CAP::Solr->new($c->config->{Solr});
    my $doc = $solr->document($key);
    my $type = $doc->{type};

    $c->detach('/error', [404, "NOTFOUND"]) unless ($doc);

    # The 'rel' parameter specifies that the document we want is in
    # relation to the supplied document, rather than the document itself.
    if ($c->req->params->{rel}) {
        if ($c->req->params->{rel} eq 'next') {
            $doc = $solr->next_doc($doc);
        }
        elsif ($c->req->params->{rel} eq 'prev') {
            $doc = $solr->prev_doc($doc);
        }

        # Make sure the related document was found.
        $c->detach('/error', [404, "NOTFOUND"]) unless ($doc);
    }

    # Store some things we will need downstream.
    $c->stash->{solr} = $solr;
    $c->stash->{doc} = $doc;
    $c->stash->{title} = $doc->{label};
    $c->stash->{template} = "show/$type.tt";

    # Detach to a function based on the record type we support.
    $c->detach('monograph') if ($type eq 'monograph');
    $c->detach('serial', [$start]) if ($type eq 'serial');
    $c->detach('issue') if ($type eq 'issue');
    $c->detach('page') if ($type eq 'page');

    # If we got this far, it means we don't know what to do with this
    # document type. # FIXME: use a 404 error...
    $c->response->body("Unsupported type: $type");
    $c->response->status(500);
    return 1;
}

sub monograph : Private
{
    my($self, $c) = @_;
    my $solr = $c->stash->{solr};
    my $doc = $c->stash->{doc};

    $c->stash(
        ancestors => $solr->ancestors($doc),
        children=> $solr->children($doc),
    );

    # Retrieve preview images for the first $max_preview child pages, or
    # for all child pages if $max_preview is < 0. (Note: doing this can
    # take several seconds if hundreds of previews are retrieved.)
    my $previews = {};
    #my $limit = $c->config->{portal}->{$c->stash->{portal}}->{max_preview} || 0;
    my $limit = $c->stash->{pconf}->{max_preview} || 0;
    my $count = 0;
    foreach my $child (@{$c->stash->{children}}) {
        next unless ($child->{type} eq 'page');
        last if ($limit > -1 && ++$count > $limit);
        $previews->{$child->{key}} = $solr->query_first({pkey => $child->{key}, type => 'file', _role => 'master OR thumbnail'});
    }
    $c->stash->{previews} = $previews;

}

sub serial : Private
{
    my($self, $c, $start) = @_;
    my $solr = $c->stash->{solr};
    my $doc = $c->stash->{doc};
    $c->stash->{issue_count} = $solr->count({pkey => $doc->{key}});
    $c->stash->{result} = $solr->nchildren($doc, $c->config->{children_per_page}, $start);
    $c->stash->{issues} = $c->stash->{result}->{documents};
}

sub issue : Private
{
    my($self, $c) = @_;
    my $solr = $c->stash->{solr};
    my $doc = $c->stash->{doc};
    $c->stash->{pages} = $solr->nchildren($doc, 5)->{documents};
    $c->stash->{prev} = $solr->prev_doc($doc);
    $c->stash->{next} = $solr->next_doc($doc);
}

sub page : Private
{
    my($self, $c) = @_;
    my $solr = $c->stash->{solr};
    my $doc = $c->stash->{doc};

    if ($doc->{type} ne 'page') {
        $c->response->body("Not a page");
        $c->response->status(404);
        return;
    }

    $c->stash(
        children => $solr->children($doc),
        ancestors => $solr->ancestors($doc),
        prevPage => $solr->prev_doc($doc),
        nextPage => $solr->next_doc($doc),
        pageCount => $solr->count({pkey => $doc->{pkey}, type => 'page'}),
        parentPdf => $solr->query_first({pkey => $doc->{pkey}, type => 'file', role => 'access', mime => 'application/pdf'}),
    );

    if ($c->stash->{nextPage}) {
        $c->stash->{nextImage} = 
            $solr->query_first({pkey => $c->stash->{nextPage}->{key}, type => 'file', role => 'master'});
    }
    if ($c->stash->{prevPage}) {
        $c->stash->{prevImage} = 
            $solr->query_first({pkey => $c->stash->{prevPage}->{key}, type => 'file', role => 'master'});
    }
}

1;
