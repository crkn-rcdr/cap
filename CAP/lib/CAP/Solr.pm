package CAP::Solr;
use strict;
use warnings;

use Encode;
use LWP::UserAgent;
use Time::HiRes qw/gettimeofday/;
use URI::Escape;
use XML::LibXML;
#use XML::LibXML::SAX;
#use CAP::SolrSAX;

our $version = 0.20100107;

=head1 NAME

CAP::Solr;

=head1 DESCRIPTION

Solr interface for CAP.

=head1 SYNOPSIS

=over 4

=item use CAP::Solr;

=item

=item $config->{select_uri} = "http://localhost:89893/solr/select"; # Where to find Solr.

=item $config->{defaults}->{rows => 10, version => "2.2", ...}; 

=item $config->{subset}->{gkey => "my_collection_name"};

=item $config->{text} = ["text_en", "text_fr", "text"];

=item $solr = CAP::Solr->new($config); 

=item

=item $hits = $solr->count({$field => $value, ...});

=item $result = $solr->query($start, {$field => $value, ...}, {$param => $value, ...});

=item $result = $solr->query_grouped($start, {$field => $value, ...}, {$param => $value, ...});

=item $doc = $solr->document($key);

=item $doc = $solr->next_doc($doc);

=item $doc = $solr->prev_doc($doc);

=item

=item $xml = $solr->update($xml_string);

=back

=head1 METHODS

=over 4

=item new($config)

Create a new Solr interface.

=item count($query)

Returns a simple count of the number of hits for $query

=item query($start, $query, $param)

Runs a search for $query. $param includes other parameters which override the defaults. Returns a result object.

A query is a set of $field => $value pairs. If $field begins with an
underscore, it searches $field without escaping value. E.g.: text => "foo
OR bar" becomes text => "foo or bar" while _text => "foo OR BAR" becomes
text => "foo OR bar".

=item query_grouped($start, $query, $param)

Runs a query, but facets based on container (pkey) and returns a
constructed result object consisting of the containers themselves. Each
container document will have an additional field {hits} indicating the
number of matching child objects.

=item document($key)

Returns the document identified by $key.

=item next_doc($doc)

Returns the next-highest sequence sibling document.

=item prev_doc($doc)

Returns the next-lowest sequence sibling document.

=item update($xml)

Sends an update request to the Solr index, sending it the text string $xml as its request.

=back

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
    #$solr->{sax_handler} = CAP::SolrSAX->new();
    #$solr->{sax} = XML::LibXML::SAX->new(Handler => $solr->{sax_handler});
    $solr->{param} = { %{$solr->{param_default}} };
    return bless($solr);
}

# TODO: handle multiple date formats
sub parse_date
{
    my($self, $date, $max) = @_;
    return undef unless ($date);
    return "$date-12-31T23:59:59Z" if ($max);
    return "$date-01-01T00:00:00Z";
}

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
    my $result = $self->query(0, $query, {rows => 0});
    return 0 unless ($result->{hits});
    return $result->{hits};
}

sub query
{
    my($self, $start, $query, $param) = @_;
    $start = $self->_int($start);
    $self->_qparams({fl => "*,score", "sort" => "score desc"}, $param);
    $self->_qquery($query);
    $self->_qexec($start);
    return $self->{result};
}

=head2 $doc = $solr->query_first($query, $param);

    A more convenient way of saying C<$doc = $solr->query(0, $query, $param)->{documents}->[0]>

=cut
sub query_first
{
    my($self, $query, $param) = @_;
    return $self->query(0, $query, $param)->{documents}->[0];
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
    use Data::Dumper;
    if ($self->{result}->{hits} == 0) { return undef }
    return $self->_document(0);
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
    return $self->_document(0);
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
    return $self->_document(0);
}


sub next_doc
{
    my($self, $doc) = @_;
    return undef unless ($doc->{seq});
    my $seq = $doc->{seq} + 1;

    # Not sure which is actually better. If there are large gaps between
    # seq's, method 2 can take a long time.
    
    # Method 1
    $self->_qparams({rows => 1, sort => "seq asc"});
    $self->_qquery({pkey => $doc->{pkey}, _seq => "[$seq TO *]"});
    $self->_qexec();
    return $self->_document(0) if ($self->{result}->{hits});
    return undef;

    # Method 2 (Inactive)

    # Find the last item in the database
    my $last = $self->query(1, {pkey => $doc->{pkey}}, {rows => 1, sort => "seq desc"})->{documents}->[0]->{seq};

    # Looking for seq:[$seq TO *] and then sorting can be very
    # time consuming. Since the next one will usually be $seq, it should
    # usually be faster just to iterate one by one until we find what
    # we're looking for.
    for (my $seq = $doc->{seq} + 1; $seq <= $last; ++$seq) {
        $self->_qparams({rows => 1});
        $self->_qquery({pkey => $doc->{pkey}, seq => $seq});
        $self->_qexec();
        return $self->_document(0) if ($self->{result}->{hits});
    }
    return undef;
}

=over 4

=item prev_doc ( I<$doc> )

Returns the document previous in sequence (the document with the next
lowest I<seq> value) to I<$doc>, or undef if no such document exists.

=back
=cut
sub prev_doc
{
    my($self, $doc) = @_;
    return undef unless ($doc->{seq});
    my $seq =  $doc->{seq} - 1;

    # See prev_doc for an explanation of the two alternate strategies
    
    # Method 1
    $self->_qparams({rows => 1, sort => "seq desc"});
    $self->_qquery({pkey => $doc->{pkey}, _seq => "[* TO $seq]"});
    $self->_qexec();
    return $self->_document(0) if ($self->{result}->{hits});
    return undef;
    
   
    # Method 2 (Inactive)
    for (my $seq = $doc->{seq} - 1; $seq > 0; --$seq) {
        $self->_qparams({rows => 1});
        $self->_qquery({pkey => $doc->{pkey}, seq => $seq});
        $self->_qexec();
        return $self->_document(0) if ($self->{result}->{hits});
    }
    return undef;
}

=over 4

=item ancestors ( I<$document> )

Returns an arrayref of documents consisting of all the
ancestor documents for the supplied document, starting with the
oldest ancestor and ending with the immediate parent. Returns an empty
array if $document is not a valid document or if no acnestors exist.

=back
=cut
sub ancestors
{
    my($self, $document) = @_;
    my $ancestors = [];

    # FIXME: we have to prevent circular lookups by stopping if we ever
    # find a key that is equal to our starting key. If that happens, we
    # should return an empty result set. We also need a way to flag that
    # an error has ocurred.
    while($document->{pkey}) {
        $self->_qparams({rows => 1});
        $self->_qquery({key => $document->{pkey}});
        $self->_qexec();
        last unless ($self->{result}->{hits});
        $document = $self->_document(0);
        push(@{$ancestors}, $document);
    }

    return $ancestors;
}

=head2 $children = $solr->children($document, [$type], [$role])

    Returns an arrayref of all the child records of $document. If $type is
    supplied, only records of that type are returned. Likewise with $role.
    Records are returned sorted according to their seq field.

    Note that, if there are a lot of child records, this call can take a
    long time to complete.

=cut
sub children
{
    my($self, $document, $type, $role) = @_;
    my $documents = [];
    my $time = gettimeofday();
    my $page;

    for ($page = 1; ; ++$page) {
        # 20 records per page seems to be about the optimal compromise
        # between minimizing database lookups and keeping the resulting
        # XML responses small and quick to parse.
        $self->_qparams({ rows => 20 });
        $self->_qquery({ pkey => $document->{key}, type => $type || "", role => $role || "" });
        $self->_qexec($page);

        push(@{$documents}, @{$self->{result}->{documents}});

        my $count = int($self->{result}->{hits});

        last if ($page >= $self->{result}->{pages});
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
    # parameters that were specified in the parameter hash.
    # It seems that URLencoding breaks Jetty's URL handling, so we don't
    # do that.
    #my @param = ("q=" . uri_escape(join(" AND ", @{$self->{q}})));
    #warn("[debug]: Solr q=" . uri_escape(join(" AND ", @{$self->{q}})));
    my @param = ("q=" . join(" AND ", @{$self->{q}}));
    warn("[debug]: Solr q=" . join(" AND ", @{$self->{q}}));
    while (my($param, $value) = each(%{$self->{param}})) {
        push(@param, join("=", (uri_escape($param), uri_escape($value))));
    }


    my $request = HTTP::Request->new(GET => join("?", $self->{select_uri}, join("&", @param)));
    my $response = $self->{agent}->request($request)->content;
    my $xml = $self->{parser}->parse_string($response);

    # TODO: check for failure here.
    
    # Update the query time and counts.
    ++$self->{qcount};
    $self->{qtime} += $xml->findvalue('/response/lst[@name="responseHeader"]/int[@name="QTime"]');

    $self->{result} = {};
    $self->{result}->{q} = uri_unescape(join("&", @param));

    # The number of hits, the number of hits displayed per page, and the
    # ordinal value (start at 1) of the first and last result on the
    # current results page.
    $self->{result}->{hits} = $xml->findvalue('//result[@name="response"]/@numFound');
    $self->{result}->{hitsPerPage} = $xml->findvalue('//lst[@name="responseHeader"]//lst[@name="params"]/str[@name="rows"]');
    $self->{result}->{hitsFrom} = $xml->findvalue('//result[@name="response"]/@start') + 1;

    $self->{result}->{hitsTo} = $self->{result}->{hitsPerPage} + $self->{result}->{hitsFrom} - 1;
    if ($self->{result}->{hitsTo} > $self->{result}->{hits}) {
        $self->{result}->{hitsTo} = $self->{result}->{hits};
    }

    $self->_setPageInfo($self->{result});

    # Record all facet fields.
    $self->{facet_fields} = {};
    foreach my $field ($xml->findnodes('//lst[@name="facet_counts"]/lst[@name="facet_fields"]/lst')) {
        my $facet_name = $self->_encode_utf8($field->getAttribute("name"));
        $self->{facet_fields}->{$facet_name} = [];
        foreach my $facet ($field->findnodes('int')) {
            my $name = $self->_encode_utf8($facet->getAttribute("name"));
            my $count = $self->_encode_utf8($facet->findvalue("."));
            push(@{$self->{facet_fields}->{$facet_name}}, {name => $name, count => $count});
        }
    }

    $self->{docs} = $xml->findnodes('//result[@name="response"]/doc');
    $self->{doc_count} = @{$self->{docs}};

    $self->{result}->{documents} = [];
    for (my $i = 0; $i < $self->{doc_count}; ++$i) {
        $self->{result}->{documents}->[$i] = $self->_document($i);
    }

    $time = sprintf("%8f", gettimeofday() - $time);
    #warn "[info] Solr:_qexec(" . join("&", @param) . ", p. $self->{param}->{start} took ${time}s\n";
    return 1;
}

# Calculate some paging informatin for the $result set.
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

# Get the document from $self->{result} at index $pos and return the
# corresponding Perl data structure.
sub _document
{
    my($self, $pos) = @_;
    my $doc = {};

    foreach my $field ($self->{docs}->[$pos]->findnodes("child::*")) {
        my $name = decode_utf8($field->getAttribute("name"));

        if ($field->nodeName eq 'arr') {
            $doc->{$name} = [];
            foreach my $subfield ($field->findnodes("child::*")) {
                push(@{$doc->{$name}}, $self->_encode_utf8($subfield->findvalue(".")));
            }
        }
        else {
            $doc->{$name} = $self->_encode_utf8($field->findvalue("."));
        }
    }

    return $doc;
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

sub _encode_utf8
{
    my($self, $string) = @_;
    return encode_utf8($string) if ($self->{utf8_encode});
    return $string;
}

1;
