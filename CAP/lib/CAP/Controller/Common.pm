package CAP::Controller::Common;
use Moose;
use namespace::autoclean;
use CAP::Ingest;

BEGIN {extends 'Catalyst::Controller'; }

# Build the item structure for $doc.
sub build_item :Private
{
    my($self, $c, $solr, $doc) = @_;

    my $info = {};
    $solr->status_msg("Common::build_item: ancestors for $doc->{key}");
    my $ancestors = $solr->ancestors($doc);

    # Count the number of records of various types that have this record
    # as a parent or group.
    my $counts = {};
    $solr->status_msg("Common:build_item: count pages with pkey $doc->{key}");
    $counts->{pages} = $solr->count({ type => 'page', pkey => $doc->{key}});
    if ($doc->{type} ne 'page') {
        $solr->status_msg("Common:build_item: count pages with gkey $doc->{key}");
        $counts->{gpages} = $solr->count({ type => 'page', gkey => $doc->{key}});
        $solr->status_msg("Common:build_item: count documents with pkey $doc->{key}");
        $counts->{docs} = $solr->count({ _type => 'collection OR monograph OR serial', pkey => $doc->{key}});
        $solr->status_msg("Common:build_item: count documents with gkey $doc->{key}");
        $counts->{gdocs} = $solr->count({ _type => 'collection OR monograph OR serial', gkey => $doc->{key}});
    }
    if ($doc->{type} eq 'serial') {
        $solr->status_msg("Common:build_item: count issues with pkey => $doc->{key}");
        $counts->{issues} = $solr->count({ type => 'issue', pkey => $doc->{key}});
    }
    if ($doc->{pkey}) {
        $solr->status_msg("Common:build_item: count number of siblings: pkey => $doc->{pkey}, type => $doc->{type}");
        $counts->{siblings} = $solr->count({type => $doc->{type}, pkey => $doc->{pkey}});
    }
    else {
        $counts->{siblings} = 0;
    }

    my $position = 0;
    if ($doc->{seq}) {
        $solr->status_msg("Common:build_item: locate position of $doc->{key} among siblings");
        $position = $solr->query(0,
            { pkey => $doc->{pkey}, type => $doc->{type}, _seq => "[* TO $doc->{seq}]"},
            { rows => 0, sort=> "seq asc" }
        )->{hits};
    }
    $solr->status_msg("Common:build_item: find previous sibling for $doc->{key}");
    my $prev = $solr->prev_doc($doc);
    $solr->status_msg("Common:build_item: find next sibling for $doc->{key}");
    my $next = $solr->next_doc($doc);
    
    # Pages and issues are considered to be sub-records. If $doc is a
    # sub-record, find the first main record ancestor. Only if no such
    # record exists do we use the document record.
    my $main_record = $doc->{key};
    if ($doc->{type} !~ /^(monograph)|(issue)|(serial)|(collection)$/) { # FIXME: shouldn't issue be removed here and below? need to check.
        foreach my $ancestor (@{$ancestors}) {
            if ($ancestor->{type} =~ /^(monograph)|(issue)|(serial)|(collection)$/) {
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

