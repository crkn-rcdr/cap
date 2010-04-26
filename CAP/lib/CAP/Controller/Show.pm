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

    # Set the site preview toggle
    if ($c->req->params->{sprev}) {
        $c->session->{show}->{site_preview} = 1 if ($c->req->params->{sprev} eq 'on');
        $c->session->{show}->{site_preview} = 0 if ($c->req->params->{sprev} eq 'off');
    }

    # Set full/brief bib record display preferences
    if ($c->req->params->{rec}) {
        $c->session->{show}->{full_record} = 1 if ($c->req->params->{rec} eq 'on');
        $c->session->{show}->{full_record} = 0 if ($c->req->params->{rec} eq 'off');
    }


    # The 'rel' parameter specifies that the document we want is in
    # relation to the supplied document, rather than the document itself.
    if ($c->req->params->{rel}) {
        if ($c->req->params->{rel} eq 'next') {
            $doc = $solr->next_doc($doc);
        }
        elsif ($c->req->params->{rel} eq 'prev') {
            $doc = $solr->prev_doc($doc);
        }
        elsif ($c->req->params->{rel} =~ /^\d+$/) {
            my $seq = $c->req->params->{rel};
            $c->detach('/error', [404, "NOTFOUND"]) unless ($seq > 0);
            my $sibling_count = $solr->count({ pkey => $doc->{pkey}, type => $doc->{type}});
            $c->detach('/error', [404, "NOTFOUND"]) unless ($seq <= $sibling_count);
            $doc = $solr->query($seq, { pkey => $doc->{pkey}, type => $doc->{type} }, { rows => 1, sort => "seq asc" })->{documents}->[0];
            $c->res->redirect($c->uri_for($c->stash->{root}, 'show', $doc->{key}));
        }
        elsif ($c->req->params->{rel} eq 'image') {
            $doc = $solr->children($doc, 'file', 'master')->[0];
            $c->detach('/error', [404, "NOTFOUND"]) unless ($doc);
            $c->detach('/file/file', [$doc->{key} . ".png"]);
        }

        # Make sure the related document was found.
        $c->detach('/error', [404, "NOTFOUND"]) unless ($doc);
    }

    # Store some things we will need downstream.
    $c->stash->{solr} = $solr;
    $c->stash->{doc} = $doc;
    $c->stash->{title} = $doc->{label};
    $c->stash->{template} = "show_$type.tt"; # TODO: change to view.tt and remove from stdinfo()

    # Detach to a function based on the record type we support.
    $c->detach('monograph') if ($type eq 'monograph');
    $c->detach('serial', [$start]) if ($type eq 'serial');
    $c->detach('issue') if ($type eq 'issue');
    $c->detach('page') if ($type eq 'page');

    # If we got this far, it means we don't know what to do with this
    # document type. # FIXME: use a 404 error...
    $c->response->body("Unsupported type: $type, $doc");
    $c->response->status(500);
    return 1;
}

sub monograph : Private
{
    my($self, $c) = @_;
    my $solr = $c->stash->{solr};
    my $doc = $c->stash->{doc};

    $c->forward('stdinfo');
    $c->stash(
        pages => $solr->children($doc, 'page'),
    );

    return 1;
}

sub serial : Private
{
    my($self, $c, $start) = @_;
    my $solr = $c->stash->{solr};
    my $doc = $c->stash->{doc};

    my $query = {pkey => $doc->{key}, type => 'issue'};
    my $param = {sort => "seq asc"},

    # Limit the issues shown to those published between two specified
    # dates. If the start date is greater than the end date, reverse them
    # but change the sorting options.
    my $df = $solr->parse_date($c->req->params->{df}, 0);
    my $dt = $solr->parse_date($c->req->params->{dt}, 1);
    ($df, $dt) = ($dt, $df) if ($df && $dt && $df > $dt);
    $query->{_pubmax} = "[* TO $dt]" if ($dt);
    $query->{_pubmin} = "[$df TO *]" if ($df);

    if ($c->req->params->{so}) {
        $param->{sort} = "seq desc" if ($c->req->params->{so} eq "seq desc");
    }

    $c->forward('stdinfo');

    # issue_count is a count of all of the available issues for this
    # serial. Issues is a page of issues which match the limiting criteria
    # above.
    $c->stash(
        issue_count => $solr->count({ pkey => $doc->{key}, type => 'issue'}),
        first_issue => $solr->first_child($doc, 'issue'),
        last_issue => $solr->last_child($doc, 'issue'),
        issues => $solr->query($start, $query, $param), 
    );

    return 1;
}

sub issue : Private
{
    my($self, $c) = @_;
    my $solr = $c->stash->{solr};
    my $doc = $c->stash->{doc};
    $c->forward('stdinfo');
    return 1;
}

sub page : Private
{
    my($self, $c) = @_;
    my $solr = $c->stash->{solr};
    my $doc = $c->stash->{doc};

    $c->forward('stdinfo');

    return 1;
}

# Retrieve standard information for every record type
sub stdinfo : Private
{
    my($self, $c) = @_;
    my $solr = $c->stash->{solr};
    my $doc = $c->stash->{doc};

    my $sibling_position = 0;
    if ($doc->{seq}) {
        $sibling_position = $solr->query(0,
            { pkey => $doc->{pkey}, type => $doc->{type}, _seq => "[* TO $doc->{seq}]"},
            { rows => 0, sort=> "seq asc" }
        )->{hits};
    }

    $c->stash(
        ancestors => $solr->ancestors($doc), # document
        template => "view.tt", # document
        resource_download => $solr->children( $doc, 'resource', 'download' ),
        resource_master => $solr->children( $doc, 'resource', 'master' ),
        resource_page => $solr->children( $doc, 'resource', 'page' ),

        file_access => $solr->children($doc, 'file', 'access'), # TODO: should be resources
        file_master => $solr->children($doc, 'file', 'master'), # TODO: should be resources
        sibling_count => $solr->count({ pkey => $doc->{pkey}, type => $doc->{type}}), # document
        sibling_position => $sibling_position, # document
        prev_sibling => $solr->prev_doc($doc), # document
        next_sibling => $solr->next_doc($doc), # document
    );

    return 1;
}


1;
