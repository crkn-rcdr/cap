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

    my $info = {};
    my $ancestors = $solr->ancestors($doc);

    # Count the number of records of various types that have this record
    # as a parent or group.
    my $counts = {};
    
    if ($doc->{type} ne 'page') {
        $counts->{pages} = $solr->count({ type => 'page', pkey => $doc->{key}}, "pages belonging to parent $doc->{key}");
        $counts->{gpages} = $solr->count({ type => 'page', gkey => $doc->{key}}, "pages belonging to group $doc->{key}");
        $counts->{docs} = $solr->count({ _type => 'collection OR monograph OR serial', pkey => $doc->{key} }, "titles belonging to parent $doc->{key}");
        $counts->{gdocs} = $solr->count({ _type => 'collection OR monograph OR serial', gkey => $doc->{key} }, "titles belonging to group $doc->{key}");
    }
    if ($doc->{type} eq 'serial') {
        $counts->{issues} = $solr->count({ type => 'issue', pkey => $doc->{key}}, "issues belonging to parent $doc->{key}");
    }
    if ($doc->{pkey}) {
        $counts->{siblings} = $solr->count({type => $doc->{type}, pkey => $doc->{pkey}}, "siblings of $doc->{key} ($doc->{type})");
    }
    else {
        $counts->{siblings} = 0;
    }

    my $position = 0;
    if ($doc->{seq} && ! $set) {
        $position = $solr->position($doc);
    }
    my $prev = undef;
    my $next = undef;
    if (! $set) {
        $prev = $solr->prev_doc($doc);
        $next = $solr->next_doc($doc);
    }
    
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

