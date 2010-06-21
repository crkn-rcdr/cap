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
    if ($doc->{type} ne 'page') {
        $solr->status_msg("Common:build_item: count pages with pkey $doc->{key}");
        $counts->{pages} = $solr->count({ type => 'page', pkey => $doc->{key}});
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
    
    # Pages and issues are considered to be sub-records. If $doc is a
    # sub-record, find the first main record ancestor. Only if no such
    # record exists do we use the document record.
    my $main_record = $doc->{key};
    if ($doc->{type} !~ /^(monograph)|(issue)|(serial)|(collection)$/) {
        foreach my $ancestor (@{$ancestors}) {
            if ($ancestor->{type} =~ /^(monograph)|(serial)|(collection)$/) {
                $main_record = $ancestor->{key};
                last;
            }
        }
    }

    return {
        doc => $doc,
        ancestors => $ancestors,
        counts => $counts,
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

