package CAP::Controller::Show;

use strict;
use warnings;
use parent 'Catalyst::Controller';

sub index : Chained('/base') PathPart('show') Args()
{
    my($self, $c, $key, $start) = @_;
    $start = 1 unless ($start);
    $key = $c->req->params->{key} if ($c->req->params->{key});

    my $solr = CAP::Solr->new($c->config->{solr});
    my $doc = $solr->document($key);
    $c->detach('/error', [404, "NOTFOUND"]) unless ($doc);
    my $type = $doc->{type};

    # Set the index of the first preview thumbnail to show
    if ($c->req->params->{spr} && $c->req->params->{spr} =~ /^\d+$/) {
        $c->session->{show}->{spr} = int($c->req->params->{spr});
    }
    else {
        $c->session->{show}->{spr} = 0;
    }

    # Set the site preview toggle - DEPRECATED (probably)
    if ($c->req->params->{sprev}) {
        $c->session->{show}->{site_preview} = 1 if ($c->req->params->{sprev} eq 'on');
        $c->session->{show}->{site_preview} = 0 if ($c->req->params->{sprev} eq 'off');
    }

    # Set full/brief bib record display preferences - DEPRECATED (probably)
    if ($c->req->params->{rec}) {
        $c->session->{show}->{full_record} = 1 if ($c->req->params->{rec} eq 'on');
        $c->session->{show}->{full_record} = 0 if ($c->req->params->{rec} eq 'off');
    }


    # The 'rel' parameter specifies that the document we want is in
    # relation to the supplied document, rather than the document itself.
    if ($c->req->params->{rel}) {
        # Next sibling
        if ($c->req->params->{rel} eq 'next') {
            $doc = $solr->next_doc($doc);
            $c->res->redirect($c->uri_for($c->stash->{root}, 'show', $doc->{key})) if ($doc);
        }
        # Previous sibling
        elsif ($c->req->params->{rel} eq 'prev') {
            $doc = $solr->prev_doc($doc);
            $c->res->redirect($c->uri_for($c->stash->{root}, 'show', $doc->{key})) if ($doc);
        }
        # The sibling at the specified ordinal position (1 = 1st)
        elsif ($c->req->params->{rel} =~ /^\d+$/) {
            if ($c->req->params->{rel} > 0) {
                $doc = $solr->sibling($doc, $c->req->params->{rel});
                $c->res->redirect($c->uri_for($c->stash->{root}, 'show', $doc->{key})) if ($doc);
            }
        }
        # First page of the document. Only valid for monographs and
        # issues (things that have pages).
        elsif ($c->req->params->{rel} eq 'start') {
            if ($doc->{type} eq 'monograph' || $doc->{type} eq 'issue') {
                $doc = $solr->child($doc, 'page', 1);
                $c->res->redirect($c->uri_for($c->stash->{root}, 'show', $doc->{key})) if ($doc);
            }
        }

        # If we tried any of the above and got nothing back as a result,
        # forward to a 404.
        $c->detach('/error', [404, "NOTFOUND"]) unless ($doc);
    }
    

    ################### Retrieve the item:
    

    $c->stash->{response}->{type} = 'item';
    $c->stash(
        facet => $solr->{facet_fields},
        title => $doc->{label},
        template => "view.tt",
    );

    $c->stash->{response}->{item} = $c->forward('/common/build_item', [$solr, $doc]); 

    $c->stash->{response}->{solr} = $solr->status();

    return 1;
}


1;
