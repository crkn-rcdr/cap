package CAP::Solr;
use strict;
use warnings;
use feature qw(switch);

use Encode;
use LWP::UserAgent;
use Time::HiRes qw/gettimeofday/;
use URI::Escape;
use JSON;
use XML::LibXML;

=head1 NAME

CAP::Solr - Solr interface for CAP

=cut

#
# General methods
#

# Create a new Solr object.
sub new
{
    my($self, $config) = @_;
    my $solr = {};
    $solr->{qtime} = 0;
    $solr->{qcount} = 0;
    $solr->{select_uri} = $config->{select_uri};
    $solr->{update_uri} = $config->{update_uri};
    $solr->{param_default} = {%{$config->{defaults}}};

    $solr->{fl} = {
        ancestors => '*',
        search => '*',
    };
    foreach my $type (keys(%{$config->{fl}})) {
        if (ref($config->{fl}->{$type}) eq 'ARRAY') {
            $solr->{fl}->{$type} = join(',', @{$config->{fl}->{$type}});
        }
        else {
            $solr->{fl}->{$type} = $config->{fl}->{$type};
        }
    }

    $solr->{subset} = {};
    $solr->{subset} = {%{$config->{subset}}} if ($config->{subset});

    $solr->{rows} = $solr->{param_default}->{rows} || 10;

    $solr->{alias} = {};
    foreach my $field (keys(%{$config->{fields}})) {
        if (ref($config->{fields}->{$field}) eq 'ARRAY') {
            $solr->{alias}->{$field} = [@{$config->{fields}->{$field}}];
        }
        else {
            $solr->{alias}->{$field} = [$config->{fields}->{$field}];
        }
    }

    $solr->{agent} = LWP::UserAgent->new();
    $solr->{parser} = XML::LibXML->new();
    $solr->{param} = { %{$solr->{param_default}} };
    $solr->{facet} = {};
    $solr->{wt} = $solr->{param}->{wt};

    $solr->{status} = {
        query_count => 0,
        query_time => 0,
        exec_time => 0,
        queries => [],
    };

    # This should be set to a descriptive message for logging purposes in
    # each query method.
    $solr->{status_msg} = "nil"; 


    return bless($solr);
}

# Retrieve the query status log.
sub status
{
    my($self) = @_;
    return $self->{status};
}

#
# Private methods
# 

# Process standard search parameters.
sub _set_params
{
    my($self, $param) = @_;

    # Reset parameters to their defaults.
    $self->{param} = { %{$self->{param_default}} };

    # For debugging purposes, unset the status message (so we can detect
    # if a method is not setting it properly).
    $self->{status_msg} = "nil"; 

    # Process caller-supplied parameters
    
    # Fields to return
    if ($param->{fl}) {
        $self->{param}->{fl} = join(',', @{$param->{fl}});
    }

    # Faceting
    if ($param->{facets}) {
        $self->{param}->{facet} = 'true';
        $self->{param}->{'facet.sort'} = 'true';
        $self->{param}->{'facet.mincount'} = 1;
        $self->{param}->{'facet.limit'} = -1;
        $self->{param}->{'facet.field'} = $param->{facets};
    }

    # Sorting
    given ($param->{'sort'}) {
        when ('score')  { $self->{param}->{'sort'} = 'score desc' }
        when ('oldest') { $self->{param}->{'sort'} = 'pubmin asc'}
        when ('newest') { $self->{param}->{'sort'} = 'pubmax desc'}
        when ('seq')    { $self->{param}->{'sort'} = 'pkey asc,seq asc'}
    }

    # Starting record (page)
    if ($param->{page}) {
        $self->{param}->{start} = ($self->_int($param->{page}) - 1) * $self->{param}->{rows};
    }

    # Number of rows to return per page
    if ($param->{rows} && $param->{rows} =~ /^\d+$/) {
        $self->{param}->{rows} = $param->{rows};
    }
}

# Run the Solr query.
sub _run_query
{
    my($self) = @_;
    my $time = gettimeofday();

    # Create the parameter string from the query parmeter q, plus any
    # parameters that were specified in the parameter hash.
    my @param = ("q=" . join(" AND ", @{$self->{q}}));

    # Append all other query parameters.
    while (my($param, $value) = each(%{$self->{param}})) {
        if (! defined($value)) {
            ; # Ignore parameters with null, empty, or undefined values.
        }
        elsif (ref($value) eq 'ARRAY') {
            foreach my $aval (@{$value}) {
                if (defined($aval)) {
                    push(@param, join("=", (uri_escape($param), uri_escape($aval))));
                }
            }
        }
        else {
            push(@param, join("=", (uri_escape($param), uri_escape($value))));
        }
    }

    $self->{result} = {};
    my $request;
    my $metrics;

    # Make the request
    if ($self->{wt} eq 'xml') {
        $request = HTTP::Request->new(GET => join("?", $self->{select_uri}, join("&", @param, 'wt=json')));
    }
    else {
        $request = HTTP::Request->new(GET => join("?", $self->{select_uri}, join("&", @param)));
    }
    my $response = $self->{agent}->request($request)->content;

    # Parse the request
    if ($self->{wt} eq 'xml') {
        $metrics = $self->_response_xml($response);
    }
    else {
        $metrics = $self->_response_json($response);
    }
    ++$self->{qcount};
    $self->{qtime} += $metrics->{query_time};
    $self->{result}->{q} = uri_unescape(join("&", @param));
    $self->{result}->{hits} = $metrics->{hits};
    $self->{result}->{hitsPerPage} = $metrics->{hitsPerPage};
    $self->{result}->{hitsFrom} = $metrics->{hitsFrom};
    $self->{result}->{hitsTo} = $self->{result}->{hitsPerPage} + $self->{result}->{hitsFrom} - 1;
    if ($self->{result}->{hitsTo} > $self->{result}->{hits}) {
        $self->{result}->{hitsTo} = $self->{result}->{hits};
    }
    $self->_setPageInfo($self->{result});

    # Record execution metrics
    my $exec_time = sprintf('%5.3f', gettimeofday() - $time);
    ++$self->{status}->{query_count};
    $self->{status}->{query_time} += $metrics->{query_time};
    $self->{status}->{exec_time} += $exec_time;
    push(@{$self->{status}->{queries}}, {
        query => $self->{result}->{q},
        query_time => $metrics->{query_time},
        exec_time => $exec_time,
        hits => $metrics->{hits},
        msg => $self->{status_msg},
    });
    $self->{status_msg} = "nil";

    return 1;
}


sub _set_query
{
    my($self, $query) = @_;
    $self->{q} = [];
    foreach my $param ($query, $self->{subset}) {
        while (my($field, $value) = each(%{$param})) {
            # Field "_foo" means search "foo" without escaping.
            if (substr($field, 0, 1) eq '_') {
                $field = substr($field, 1);
            }
            else {
                $value = $self->_escape($value);
            }

            # Normalize space and skip empty fields.
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            $value =~ s/\s+/ /g;
            next unless($value);

            if ($self->{alias}->{$field}) {
                my @aliases = ();
                foreach my $alias (@{$self->{alias}->{$field}}) {
                    push(@aliases, "($alias:($value))");
                }
                push(@{$self->{q}}, "(" . join(" OR ", @aliases) . ")");
            }
            else {
                push(@{$self->{q}}, "($field:($value))");
            }
        }
    }
}

sub _response_xml {
    my($self, $response) = @_;
    my $xml;
    $self->{facet_fields} = {};
    $self->{result}->{documents} = [];

    # Return an empty set if there is an error.
    eval { $xml = $self->{parser}->parse_string($response); };
    if ($@) {
        return {
            query_time => $xml->{responseHeader}->{QTime} / 1000,
            hits => $xml->{response}->{numFound},
            hitsPerPage => $xml->{responseHeader}->{params}->{rows},
            hitsFrom => $xml->{response}->{start} + 1,
        }
    }

    # Grab the facet fields
    $self->{facet_fields} = {};
    foreach my $field ($xml->findnodes('//lst[@name="facet_counts"]/lst[@name="facet_fields"]/lst')) {
        my $facet_name = $field->getAttribute("name");
        $self->{facet_fields}->{$facet_name} = [];
        foreach my $facet ($field->findnodes('int')) {
            my $name = $facet->getAttribute("name");
            my $count = $facet->findvalue(".");
            push(@{$self->{facet_fields}->{$facet_name}}, {name => $name, count => $count});
        }
    }

    # Construct the documents array, converting the XML structure into a
    # JSON-like one.
    my $docs = $xml->findnodes('//result[@name="response"]/doc');
    my $doc_count = @{$docs};
    $self->{result}->{documents} = [];
    for (my $i = 0; $i < $doc_count; ++$i) {
        my $doc = {};

        foreach my $field ($docs->[$i]->findnodes("child::*")) {
            my $name = decode_utf8($field->getAttribute("name"));

            if ($field->nodeName eq 'arr') {
                $doc->{$name} = [];
                foreach my $subfield ($field->findnodes("child::*")) {
                    push(@{$doc->{$name}}, $subfield->findvalue("."));
                }
            }
            else {
                $doc->{$name} = $field->findvalue(".");
            }
        }
        $self->{result}->{documents}->[$i] = $doc;
    }

    return {
        query_time => $xml->findvalue('/response/lst[@name="responseHeader"]/int[@name="QTime"]') / 1000,
        hits => $xml->findvalue('//result[@name="response"]/@numFound'),
        hitsPerPage => $xml->findvalue('//lst[@name="responseHeader"]//lst[@name="params"]/str[@name="rows"]'),
        hitsFrom => $xml->findvalue('//result[@name="response"]/@start') + 1,
    };
}

sub _response_json {
    my($self, $response) = @_;
    my $json = {};
    $self->{facet_fields} = {};
    $self->{result}->{documents} = [];

    # Return an empty set if there is an error.
    eval { $json = decode_json($response); };
    if ($@) {
        return {
            query_time => $json->{responseHeader}->{QTime} / 1000,
            hits => $json->{response}->{numFound},
            hitsPerPage => $json->{responseHeader}->{params}->{rows},
            hitsFrom => $json->{response}->{start} + 1,
        }
    }


    # Grab the facet fields
    if ($json->{facet_counts}->{facet_fields}) {
        my %facet_fields = %{$json->{facet_counts}->{facet_fields}};
        foreach my $facet_name (keys(%facet_fields)) {
            my @values = @{$facet_fields{$facet_name}};
            while (@values) {
                my $name = shift(@values);
                my $count = shift(@values);
                push(@{$self->{facet_fields}->{$facet_name}}, {name => $name, count => $count});
            }
        }
    }

    # The documents array is already in the format we need.
    $self->{result}->{documents} = $json->{response}->{docs};

    return {
        query_time => $json->{responseHeader}->{QTime} / 1000,
        hits => $json->{response}->{numFound},
        hitsPerPage => $json->{responseHeader}->{params}->{rows},
        hitsFrom => $json->{response}->{start} + 1,
    }
}

# Calculate some paging information for the $result set.
sub _setPageInfo
{
    my($self, $result) = @_;

    # The total number of pages in the result set, and the page we are
    # currently looking at. We need to check for
    # the condition where rows=0 to avoid a division by zero error. We
    # also need to round up all fractional values, since a partial page of
    # results still counts as a page. Pages are given as ordinal values:
    # the first page is 1, not 0.
    if ($result->{hitsPerPage}) {
        $result->{pages} = int($result->{hits} / $result->{hitsPerPage});
        if ($result->{hits} % $result->{hitsPerPage}) {
            ++$result->{pages};
        }
        $result->{page} = int($result->{hitsFrom} / $result->{hitsPerPage}) + 1;
    }
    else {
        $result->{pages} = 0;
        $result->{page} = 0;
    }

    # The page number of the previous results page (0 = no previous page).
    if ($result->{page} > 1) {
        $result->{pagePrev} = $result->{page} - 1; # TODO: deprecated
        $result->{prev_page} = $result->{page} - 1;
    }
    else {
        $result->{pagePrev} = 0; # TODO: deprecated
        $result->{prev_page} = 0;
    }

    # The page number of the net results page (0 = no next page).
    if ($result->{page} < $result->{pages}) {
        $result->{pageNext} = $result->{page} + 1; # TODO: deprecated
        $result->{next_page} = $result->{page} + 1;
    }
    else {
        $result->{pageNext} = 0; # TODO: deprecated
        $result->{next_page} = 0;
    }

    return $result;
}

# Escape Lucene characters.
sub _escape
{
    my($self, $string) = @_;
    return "" unless ($string);

    #$string =~ s/([:+!(){}\\[\]^"~*?\\-])/\\$1/g; # Escapes everything

    # Escape most special Lucene characters. We will allow * for
    # wildcards, and also " for quoting (but see below).
    $string =~ s/([:+!(){}\\[\]^~?\\-])/\\$1/g;

    # If the string contains an even number of double quotes, let them
    # pass through as-is. Otherwise, escape the last quote to
    # prevent an open string.
    my $nquotes = ($string =~ tr/"//);
    if ($nquotes % 2 == 1) {
        $string =~ s/(.*)"/$1\\"/;
    }

    # Downcase AND, OR, NOT to turn them into ordinary keywords.
    $string =~ s/\bAND\b/ and /g;
    $string =~ s/\bOR\b/ or /g;
    $string =~ s/\bNOT\b/ not /g;
    return $string;
}

# Force $param to be an integer >= $min. Returns $param or $min, if $param
# does not meet these criteria. If $min is not specified, a value of 1 is
# assumed.
sub _int
{
    my($self, $param, $min) = @_;
    $min = 1 unless (defined($min));
    $param = 0 unless ($param);
    $param =~ s/[^\d-]//g;
    $param = int($param);
    $param = $min unless ($param > $min);
    return $param;
}



#
# Database query methods
#


# Return an array of all the ancestors (if any) of $document, starting
# with the parent and working up the hierarchy.
sub ancestors
{
    my($self, $doc) = @_;
    my $ancestors = [];
    my %keys = ( $doc->{key} => 1 ); # Keep track of keys we've seen to avoid circular references
    while($doc->{pkey}) {
        $self->_set_query({key => $doc->{pkey}});
        $self->_set_params({});
        $self->{param}->{rows} = 1;
        $self->{param}->{fl} = $self->{fl}->{ancestors};
        $self->{status_msg} = "ancestors(): $doc->{key}";
        $self->_run_query();
        last unless ($self->{result}->{hits});
        $doc= $self->{result}->{documents}->[0];
        last if ($keys{$doc->{key}}); # Abort on circular reference
        $keys{$doc->{key}} = 1;
        push(@{$ancestors}, $doc);
    }

    return $ancestors;
}

# Run a general search of the database and return the number of records
# found.
sub count
{
    my($self, $query, $what) = @_;
    $what = "" unless ($what);
    $self->_set_query($query);
    $self->_set_params({});
    $self->{param}->{rows} = 0;
    $self->{param}->{'sort'} = undef;
    $self->{status_msg} = "count(): $what";
    $self->_run_query();
    return 0 unless ($self->{result}->{hits});
    return $self->{result}->{hits};
}

# Retrieves a single document by key.
sub document
{
    my($self, $key) = @_;
    $self->_set_query({key => $key});
    $self->_set_params({});
    $self->{param}->{rows} = 1;
    $self->{param}->{sort} = undef;
    $self->{status_msg} = "document(): $key";
    $self->_run_query();
    if ($self->{result}->{hits} == 0) { return undef }
    return $self->{result}->{documents}->[0];
}

# Retreives the $field from the document in the query set with the lowest
# or highest (depending on whether $max is nonzero) value of $field.
sub limit
{
    my($self, $query, $field, $max) = @_;
    my $direction = 'asc';
    $direction = 'desc' if ($max);
    $self->_set_query($query);
    $self->_set_params({});
    $self->{param}->{rows} = 1;
    $self->{param}->{'sort'} = "$field $direction";
    $self->{status_msg} = "limit(): $field $direction";
    $self->_run_query();
    return "" unless ($self->{result}->{hits});
    return $self->{result}->{documents}->[0]->{$field};
}

sub next_doc
{
    my($self, $doc) = @_;
    return undef unless ($doc->{seq});
    my $seq = $doc->{seq} + 1;
    $self->_set_query({pkey => $doc->{pkey}, _seq => "[$seq TO *]"});
    $self->_set_params({}); # Set paremeter defaults
    $self->{param}->{rows} = 1;
    $self->{param}->{'sort'} = "seq asc";
    $self->{status_msg} = "next_doc(): $doc->{key}";
    $self->_run_query();
    return $self->{result}->{documents}->[0] if ($self->{result}->{hits});
    return undef;
}

sub prev_doc
{
    my($self, $doc) = @_;
    return undef unless ($doc->{seq});
    my $seq =  $doc->{seq} - 1;
    $self->_set_query({pkey => $doc->{pkey}, _seq => "[* TO $seq]"});
    $self->_set_params({}); # Set paremeter defaults
    $self->{param}->{rows} = 1;
    $self->{param}->{'sort'} = "seq desc";
    $self->{status_msg} = "prev_doc(): $doc->{key}";
    $self->_run_query();
    return $self->{result}->{documents}->[0] if ($self->{result}->{hits});
    return undef;
}

# Return the document that is the $pos'th sibling of $doc (the document
# in position $pos with the same pkey and type as $doc).
sub sibling
{
    my($self, $doc, $pos) = @_;
    $self->_set_query({ pkey => $doc->{pkey}, type => $doc->{type}});
    $self->_set_params({});
    $self->{param}->{'sort'} = "seq asc";
    $self->{param}->{'rows'} = 1;
    $self->{param}->{'start'} = $pos - 1;
    $self->{status_msg} = "sibling(): $doc->{key} ($doc->{type}) @ $pos";
    $self->_run_query();
    return $self->{result}->{documents}->[0] if ($self->{result}->{hits});
    return undef;
}

sub child
{
    my($self, $doc, $type, $pos) = @_;
    $self->_set_query({ pkey => $doc->{key}, type => $type});
    $self->_set_params({});
    $self->{param}->{'rows'} = 1;
    $self->{param}->{'start'} = $pos - 1;
    $self->{param}->{'sort'} = "seq asc";
    $self->{status_msg} = "child(): $doc->{key} ($doc->{type}) @ $pos";
    $self->_run_query();
    return $self->{result}->{documents}->[0] if ($self->{result}->{hits});
    return undef;
}

# Returns the ordinal position of $doc among its siblings (documents of
# the same type and belonging to the same parent).
sub position
{
    my($self, $doc) = @_;
    $self->_set_query({ pkey => $doc->{pkey}, type => $doc->{type}, _seq => "[* TO $doc->{seq}]" });
    $self->_set_params({}); # Set parameter defaults
    $self->{param}->{rows} = 0;
    $self->{param}->{sort} = "seq asc";
    $self->{status_msg} = "position(): $doc->{key} (type=$doc->{type})";
    $self->_run_query();
    return 0 unless ($self->{result}->{hits}); # This shouldn't happen if $doc is actually in the database
    return $self->{result}->{hits};
}

# Run a general search of the database.
sub search
{
    my($self, $query, $param) = @_;
    $self->_set_query($query);
    $self->_set_params($param);
    # Retrieve the default fields if none are supplied.
    $self->{param}->{fl} = $self->{fl}->{search} unless ($param->{fl});
    $self->{status_msg} = "search(): main query";
    $self->_run_query();
    return $self->{result};
}

# Run a search and return a result set consisting of the parent objects,
# sorted by the number of matching child objects. (E.g.,
# monographs/serials ordered by number of child pages which matched the
# query.)
sub search_grouped
{
    my($self, $query, $param) = @_;

    # This is our starting page for the grouped result set.
    my $start = ($self->_int($param->{page}) - 1) * $self->{param}->{rows};

    # We are going to create a result set that follows the same structure
    # as the one returned by _run_query().
    my $result = {};

    # First, find out how many documents contain matches by counting the
    # facets.
    $self->_set_query($query);
    $self->_set_params($param);
    $self->{param}->{rows} = 0;
    $self->{param}->{facet} = 'true';
    $self->{param}->{'facet.field'} = 'pkey';
    $self->{param}->{'facet.sort'} = 'true';
    $self->{param}->{'facet.mincount'} = 1;
    $self->{param}->{'facet.limit'} = -1;
    $self->{status_msg} = "search_parent(): main query";
    $self->_run_query();

    return {hits => 0} unless ($self->{facet_fields}->{pkey});

    # Record the number of matching documents.
    $result->{hits} = int(@{$self->{facet_fields}->{pkey}});

    # Take the facet slice corresponding to the page we are interested in.
    my $facet_from = $start;
    my $facet_to = $facet_from + $self->{rows} - 1;
    $facet_to = $result->{hits} - 1 if ($facet_to >= $result->{hits});
    my @docs = @{$self->{facet_fields}->{pkey}}[$facet_from .. $facet_to];

    # Fetch each document in this "page" and add it to the result
    # documents. We also copy over the number of pages matched in this
    # document.
    $result->{documents} = [];
    foreach my $doc (@docs) {
        my $record = $self->document($doc->{name});
        $record->{hits} = $doc->{count};
        push(@{$result->{documents}}, $record);
    }

    #use Data::Dumper;
    #warn Dumper($result);

    # Set some additional result data.
    $result->{hitsPerPage} = $self->{param_default}->{rows};
    $result->{hitsFrom} = $start + 1;
    $result->{hitsTo} = $result->{hitsPerPage} + $result->{hitsFrom} - 1;
    if ($result->{hitsTo} > $result->{hits}) {
        $result->{hitsTo} = $result->{hits};
    }
    $result = $self->_setPageInfo($result);

    return $result;
}


# Return various counts by contributor
sub stats_contributor
{
    my($self) = @_;
    my $stats = { record => {} };
    
    $self->_set_params({
        rows => 0,
        facets => [ 'contributor' ],
    });

    foreach my $type (("page", "monograph", "issue", "serial", "collection")) {
        $self->_set_query({type => $type});
        $self->{status_msg} = "stats_contributor(): $type";
        $self->_run_query();
        $stats->{$type} = {};
        foreach my $facet (@{$self->{facet_fields}->{contributor}}) {
            my $name = $facet->{name};
            my $count = $facet->{count};
            $stats->{$type}->{$name} = $count;
            if ($stats->{record}->{$name}) {
                $stats->{record}->{$name} = $stats->{record}->{$name} + $count;
            }
            else {
                $stats->{record}->{$name} = $count;
            }
        }
    }
    return $stats;
}

# Counts the number of occurrences of each specified facet within the
# entire collection and returns a hash mapping of name-value pairs for
# each one.
sub facet_counts
{
    my($self, @facets) = @_;
    my $facets = {};

    $self->_set_query({_key => '[* TO *]'});
    $self->_set_params({ rows => 0, facets => [ @facets ]});
    $self->_run_query();
    foreach my $facet (@facets) {
        $facets->{$facet} = {};
        foreach my $value (@{$self->{facet_fields}->{$facet}}) {
            my $name = $value->{name};
            my $count = $value->{count};
            $facets->{$facet}->{$name} = $count;
        }
    }

    return $facets;
}

1;
