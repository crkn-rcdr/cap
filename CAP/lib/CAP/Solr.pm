package CAP::Solr;
use strict;
use warnings;

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
# Public Methods
#

sub new
{
    my($self, $config) = @_;
    my $solr = {};
    $solr->{qtime} = 0;
    $solr->{qcount} = 0;
    $solr->{select_uri} = $config->{select_uri};
    $solr->{update_uri} = $config->{update_uri};
    $solr->{utf8_encode} = $config->{utf8_encode};
    $solr->{param_default} = {%{$config->{defaults}}};

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

    # If set, this will be recorded in the msg field when _qexec is
    # called. The value is reset to 'nil' by _qexec.
    $solr->{status_msg} = "nil"; 


    return bless($solr);
}

sub status
{
    my($self) = @_;
    return $self->{status};
}

sub status_msg
{
    my($self, $status_msg) = @_;
    $self->{status_msg} = $status_msg || "";
    return 1;
}

# TODO: handle multiple date formats
# Deprecated? (might be used in Show.pm)
#sub parse_date
#{
#    my($self, $date, $max) = @_;
#    return undef unless ($date);
#    return "$date-12-31T23:59:59Z" if ($max);
#    return "$date-01-01T00:00:00Z";
#}

sub update
{
    my($self, $data) = @_;

    my $request = HTTP::Request->new(POST => $self->{update_uri});
    $request->header("Content-type" => "text/xml; charset=utf8");
    #$request->content(decode_utf8($data));
    $request->content($data);

    my $xml;
    my $response = {ok => 0};
    
    eval { $xml = $self->{parser}->parse_string($self->{agent}->request($request)->content) };
    if ($@) {
        $response->{error} =  $@;
        return $response;
    }

    # Make sure we got a proper Solr response document with a correct
    # (zero) status code.
    my $status = 1;
    if ($xml->findnodes('/response/lst[@name="responseHeader"]/int[@name="status"]')) {
        $status = $xml->findvalue('/response/lst[@name="responseHeader"]/int[@name="status"]');
    }
    if ($status != 0) {
        $response->{error} = $xml->findnodes('//body')->[0]->toString(1);
        return $response;
    }
    $response->{solr_qtime} = $xml->findvalue('/response/lst[@name="responseHeader"]/int[@name="QTime"]');

    $response->{ok} = 1;
    return $response;
}

sub count
{
    my($self, $query) = @_;
    my $result = $self->query(0, $query, {rows => 0}, {});
    return 0 unless ($result->{hits});
    return $result->{hits};
}

sub query
{
    my($self, $start, $query, $param, $facet) = @_;
    $start = $self->_int($start);
    $self->{facet} = $facet if ($facet);
    $self->_qparams({fl => "*,score", "sort" => "score desc"}, $param);
    $self->_qquery($query);
    $self->_qexec($start);
    return $self->{result};
}

sub query_first
{
    my($self, $query, $param) = @_;
    return $self->query(0, $query, $param, undef, {})->{documents}->[0];
}

sub query_grouped
{
    my($self, $start, $query) = @_;
    $start = $self->_int($start);

    # We have to create our own handmade result set with the same data structure as
    # the one returned by _qexec().
    my $result = {};

    # First, find out how many documents contain matches by counting the
    # facets.
    $self->_qparams({
        rows => 0,
        facet => "true",
        "facet.field" => "pkey",
        "facet.sort" => "true",
        "facet.mincount" => 1,
        "facet.limit" => -1,
    });
    $self->_qquery($query);
    $self->_qexec();

    # Record the number of matching documents.
    $result->{hits} = int(@{$self->{facet_fields}->{pkey}});

    # Take the facet slice corresponding to the page we are interested in.
    my $facet_from = $self->{rows} * ($start - 1); 
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
    $result->{hitsFrom} = $self->{param_default}->{rows} * ($start - 1) + 1;
    $result->{hitsTo} = $result->{hitsPerPage} + $result->{hitsFrom} - 1;
    if ($result->{hitsTo} > $result->{hits}) {
        $result->{hitsTo} = $result->{hits};
    }
    $self->_setPageInfo($result);

    return {hits => 0} unless ($result->{hits});
    return $result;
}

sub document
{
    my($self, $key) = @_;
    $self->_qparams({rows => 1});
    $self->_qquery({key => $key});
    $self->_qexec();
    if ($self->{result}->{hits} == 0) { return undef }
    return $self->{result}->{documents}->[0];
}


sub first_child
{
    my($self, $doc, $type) = @_;

    return undef unless ($doc);
    $self->_qparams({rows => 1, sort => "seq asc"});
    if ($type) {
        $self->_qquery({pkey => $doc->{key}, type => $type});
    }
    else {
        $self->_qquery({pkey => $doc->{key}});
    }
    $self->_qexec();
    return undef unless ($self->{result}->{hits});
    return $self->{result}->{documents}->[0];
}


sub last_child
{
    my($self, $doc, $type) = @_;

    return undef unless ($doc);
    $self->_qparams({rows => 1, sort => "seq desc"});
    if ($type) {
        $self->_qquery({key => $doc->{pkey}, type => $type});
    }
    else {
        $self->_qquery({key => $doc->{pkey}});
    }
    $self->_qexec();
    return undef unless ($self->{result}->{hits});
    return $self->{result}->{documents}->[0];
}


sub next_doc
{
    my($self, $doc) = @_;
    return undef unless ($doc->{seq});
    my $seq = $doc->{seq} + 1;

    $self->{facet} = {};
    $self->_qparams({rows => 1, sort => "seq asc"});
    $self->_qquery({pkey => $doc->{pkey}, _seq => "[$seq TO *]"});
    $self->_qexec();
    return $self->{result}->{documents}->[0] if ($self->{result}->{hits});
    return undef;
}

sub prev_doc
{
    my($self, $doc) = @_;
    return undef unless ($doc->{seq});
    my $seq =  $doc->{seq} - 1;

    $self->{facet} = {};
    $self->_qparams({rows => 1, sort => "seq desc"});
    $self->_qquery({pkey => $doc->{pkey}, _seq => "[* TO $seq]"});
    $self->_qexec();
    return $self->{result}->{documents}->[0] if ($self->{result}->{hits});
    return undef;
}

sub ancestors
{
    my($self, $document) = @_;
    my $ancestors = [];
    my %keys = ( $document->{key} => 1 ); # Keep track of keys we've seen to avoid circular references

    # FIXME: we have to prevent circular lookups by stopping if we ever
    # find a key that is equal to our starting key. If that happens, we
    # should return an empty result set. We also need a way to flag that
    # an error has ocurred.
    while($document->{pkey}) {
        $self->{facet} = {};
        $self->_qparams({rows => 1});
        $self->_qquery({key => $document->{pkey}});
        $self->_qexec();
        last unless ($self->{result}->{hits});
        $document = $self->{result}->{documents}->[0];
        last if ($keys{$document->{key}}); # Abort on circular reference
        $keys{$document->{key}} = 1;
        push(@{$ancestors}, $document);
        $self->status_msg("Solr::ancestors: ancestor for $document->{key}"); # For next iteration
    }

    return $ancestors;
}

sub children
{
    my($self, $document, $type, $role) = @_; # TODO: is $role deprecated?
    my $documents = [];
    my $time = gettimeofday();
    my $page;

    for ($page = 1;;) {
        # 20 records per page seems to be about the optimal compromise
        # between minimizing database lookups and keeping the resulting
        # XML responses small and quick to parse.
        $self->_qparams({ rows => 20 });
        $self->_qquery({ pkey => $document->{key}, type => $type || "", role => $role || "" });
        $self->_qexec($page);

        push(@{$documents}, @{$self->{result}->{documents}});
        my $count = int($self->{result}->{hits});
        last if ($page >= $self->{result}->{pages});
        ++$page;
        $self->{status_msg} = "Solr::children get child page docs for $document->{key} (result page $page)";
    }

    $time = sprintf("%8f", gettimeofday() - $time);
    warn "[info] Solr:children(key=$document->{key}, children=" . int(@{$documents}) . ") took ${time}s\n";
    return $documents;
}

sub nchildren
{
    my($self, $doc, $limit, $start) = @_;
    $start = $self->_int($start);
    $limit = $self->_int($limit, 0);

    # If a limit isn't specified, we find how many children $doc has and
    # set $n to that many so as to retrieve all children.
    if (! $limit) {
        $self->_qparams({rows => 0});
        $self->_qquery({pkey => $doc->{key}});
        $self->_qexec();
        return {} unless ($self->{result}->{hits});
        $limit = int($self->{result}->{hits});
    }

    $self->_qparams({rows => $limit, sort => "seq asc"});
    $self->_qquery({pkey => $doc->{key}});
    $self->_qexec($start);
    return {} unless ($self->{result}->{hits});
    return $self->{result};
}

#
# Private Methods
#

sub _qquery
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

sub _qparams
{
    my($self, $func, $user) = @_;

    # Start with the global default parameters.
    $self->{param} = { %{$self->{param_default}} };

    # Apply any method-specific overrides.
    while (my($key, $value) = each(%{$func})) {
        $self->{param}->{$key} = $value;
    }
    
    # Apply user-supplied parameters
    while (my($key, $value) = each(%{$user})) {
        $self->{param}->{$key} = $value;
    }
}


# Run the Solr query, returning results page $page, or page 1 if $page is
# not speficied.
sub _qexec
{
    my($self, $page) = @_;
    my $time = gettimeofday();

    if ($page) {
        $self->{param}->{start} = ($page - 1) * $self->{param}->{rows};
    }

    # Create the parameter string from the query parmeter q, plus any
    # parameters that were specified in the parameter hash. We also
    # specify the response format (by default, json).
    my @param = ("q=" . join(" AND ", @{$self->{q}}));
    # Append non-facet query parameters
    while (my($param, $value) = each(%{$self->{param}})) {
        push(@param, join("=", (uri_escape($param), uri_escape($value))));
    }
    # Append facet query parameters, if any.
    if ($self->{facet}->{'facet'}) {
        push(@param, join('=', 'facet', $self->{facet}->{'facet'}));
        push(@param, join('=', 'facet.mincount', $self->{facet}->{'facet.mincount'}));
        push(@param, join('=', 'facet.limit', $self->{facet}->{'facet.limit'}));
        push(@param, join('=', 'facet.sort', $self->{facet}->{'facet.sort'}));
        foreach my $field (@{$self->{facet}->{'facet.field'}}) {
            push(@param, join('=', 'facet.field', $field));
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

sub _response_xml {
    my($self, $response) = @_;

    my $xml = $self->{parser}->parse_string($response);

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
    
    my $json = decode_json($response);

    # Grab the facet fields
    $self->{facet_fields} = {};
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

1;
