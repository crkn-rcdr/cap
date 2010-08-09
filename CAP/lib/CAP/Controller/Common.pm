package CAP::Controller::Common;
use Moose;
use namespace::autoclean;
use CAP::Ingest;

BEGIN {extends 'Catalyst::Controller'; }

# Build the item structure for $doc. If $set is true, several unecessary
# values are left undefined in order to boost performance.
sub build_item :Private
{
    my($self, $c, $solr, $doc, $set) = @_;

    my $counts = {
        pages => 0,
        gpages => 0,
        docs => 0,
        gdocs => 0,
        issues => 0,
        siblings => 0,
    };
    my $ancestors = undef;
    my $position  = 0;
    my $prev      = undef;
    my $next      = undef;

    # If we're retrieving a set of records, we only get what we need for
    # the search results page, in order to save time.
    if ($set) {
        $ancestors = $solr->ancestors($doc);
    }

    # Otherwise, if we're fetching a single record, we get additional
    # information.
    else {
        $ancestors = $solr->ancestors($doc);
        $counts->{pages} = $solr->count({ type => 'page', pkey => $doc->{key}}, "pages belonging to parent $doc->{key}");
        $counts->{gpages} = $solr->count({ type => 'page', gkey => $doc->{key}}, "pages belonging to group $doc->{key}");
        $counts->{docs} = $solr->count({ _type => 'collection OR monograph OR serial', pkey => $doc->{key} }, "titles belonging to parent $doc->{key}");
        $counts->{gdocs} = $solr->count({ _type => 'collection OR monograph OR serial', gkey => $doc->{key} }, "titles belonging to group $doc->{key}");
        $counts->{issues} = $solr->count({ type => 'issue', pkey => $doc->{key}}, "issues belonging to parent $doc->{key}");
        if ($doc->{pkey})
            { $counts->{siblings} = $solr->count({type => $doc->{type}, pkey => $doc->{pkey}}, "siblings of $doc->{key} ($doc->{type})"); }
        if ($doc->{seq})
            { $position = $solr->position($doc); }
        $prev = $solr->prev_doc($doc);
        $next = $solr->next_doc($doc);
    }

    # Pages are considered to be sub-records. If $doc is a
    # sub-record, find the first main record ancestor. Only if no such
    # record exists do we use the document record.
    my $main_record = $doc->{key};
    if ($doc->{type} eq 'page') {
        foreach my $ancestor (@{$ancestors}) {
            if ($ancestor->{type} ne 'page') {
                $main_record = $ancestor->{key};
                last;
            }
        }
    }

    return {
        doc => $doc,
        ancestors => $ancestors,
        counts => $counts,
        position => $position,
        'next' => $next,
        prev => $prev,
        main_record => $main_record,
    };
}

sub repos_path2 :Private
{
    my ( $self, $c, $doc ) = @_;

    # Create a subdirectory tree using a standardized algorithm to put
    # files in predictable places and keep directory sizes reasonable:
    my $subdir = substr( $doc->{key}, length( $doc->{contributor} ) + 1 ); # remove the leading "$contributor."
    my @components = split(/\./, $subdir);
    if ( @components > 2 ) {
        pop( @components );
        pop( @components );
    }
    $subdir = join( '/', @components );

    # Join with the base dir + contributor dir and return the full path to
    # the file.
    return join('/', $c->config->{content}, $doc->{contributor}, $subdir);
}

sub repos_path :Private
{
    my($self, $c, $doc) = @_;
    my $content=$c->config->{content};
    my $ingest = new Ingest($content);
    my $path=$ingest->get_path($doc->{file}, $doc->{contributor});
    warn("[debug] Repository path is $path\n");
    
    return $path;

    #my $digest = md5_hex($doc->{file});
    #my $path = join('/', $c->config->{content}, $doc->{contributor}, substr($digest, 0, 2), substr($digest, 2, 2));

    #warn("[debug] Repository path is $path\n");

    #return $path;
}

__PACKAGE__->meta->make_immutable;

