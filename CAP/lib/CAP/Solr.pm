package CAP::Solr;
use strict;
use warnings;
use utf8;
#use feature qw(switch);


use Encode;
use LWP::UserAgent;
use Time::HiRes qw/gettimeofday/;
use URI::Escape;
use JSON;
use XML::LibXML;

=head1 NAME

CAP::Solr - Solr interface for CAP

=cut

# Create a new Solr object.
sub new
{
    my($self, $url, $config, $subset) = @_;
    my $solr = {};

    # Initialize internal metrics and debugging information.
    $solr->{status} = {
        count       => 0,      # total number of queries run
        query_time  => 0,      # total time running Solr queries (seconds)
        exec_time   => 0,      # total time spent in solr_query()
        queries     => [],     # log of all queries run
        message     => 'nil',  # status message to attach to next query log entry
    };

    #
    # Configure the Solr object
    #
    
    $solr->{url} = $url;

    # Default Solr parameters. We need to restore true/false values to
    # boolean string values for a couple parameters.
    $solr->{defaults} = {%{$config->{defaults}}};
    if ($solr->{defaults}->{facet}) {
        $solr->{defaults}->{facet} = 'true';
    }
    else {
        $solr->{defaults}->{facet} = 'false';
    }
    if ($solr->{defaults}->{'facet.sort'}) {
        $solr->{defaults}->{'facet.sort'} = 'true';
    }
    else {
        $solr->{defaults}->{'facet.sort'} = 'false';
    }

    # A subset restriction on all searches (except those using
    # solr_query() directly). Must be a Solr query (q) fragment. E.g.:
    # 'foo:bar OR baz'
    $solr->{subset} = $subset || "";

    # A mapping of field aliases to Solr query fragments, with '%' as a
    # placeholder for the query text. E.g.:
    # 'su' => 'su:(%) OR su_en:(%) OR su_fr:(%)'
    $solr->{'fields'} = {};
    $solr->{'fields'} = {%{$config->{'fields'}}} if ($config->{'fields'});

    # A list of query fields that should be interpreted as text fields
    # (not string fields).
    $solr->{'textfields'} = $config->{'textfields'};

    # A mapping of sort rules to Solr sort rules. E.g.:
    # 'oldest' => 'pubmin asc'
    $solr->{'sort'} = {};
    $solr->{'sort'} = {%{$config->{'sort'}}} if ($config->{'sort'});

    # A mapping of rules to restrict by arbitrary type. E.g.:
    # 'titles' => 'type:monograph OR serial'
    $solr->{'type'} = {};
    $solr->{'type'} = {%{$config->{'type'}}} if ($config->{'type'});

    # A user agent for making Solr requests and a LibXML object for
    # processing XML responses.
    $solr->{agent} = LWP::UserAgent->new();
    $solr->{parser} = XML::LibXML->new();

    return bless($solr);
}


# Called by solr_query() to decode XML responses from Solr.
sub _decode_xml {
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


# Called by solr_query() to decode JSON responses from Solr.
sub _decode_json {
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
        $result->{prev_page} = $result->{page} - 1;
    }
    else {
        $result->{prev_page} = 0;
    }

    # The page number of the net results page (0 = no next page).
    if ($result->{page} < $result->{pages}) {
        $result->{next_page} = $result->{page} + 1;
    }
    else {
        $result->{next_page} = 0;
    }

    return $result;
}


# Return a Lucene-escaped string. This disables Lucene features we don't
# want to support, and makes safe constructs we don't want to parse out
# more carefully.
#sub _escape
#{
#    my($self, $string) = @_;
#    return "" unless ($string);

    #$string =~ s/([:+!(){}\\[\]^"~*?\\-])/\\$1/g; # Escapes everything

    # Escape most special Lucene characters. We will allow * for
    # wildcards, and also " for quoting (but see below).
#    $string =~ s/([:+!(){}\\[\]^~?\\-])/\\$1/g;

    # If the string contains an even number of double quotes, let them
    # pass through as-is. Otherwise, escape the last quote to
    # prevent an open string.
#    my $nquotes = ($string =~ tr/"//);
#    if ($nquotes % 2 == 1) {
#        $string =~ s/(.*)"/$1\\"/;
#    }

    # Downcase AND, OR, NOT to turn them into ordinary keywords.
#    $string =~ s/\bAND\b/and/g;
#    $string =~ s/\bOR\b/or/g;
#    $string =~ s/\bNOT\b/not/g;
#    return $string;
#}

# Force $param to be an integer >= $min. Returns $param or $min, if $param
# does not meet these criteria. If $min is not specified, a value of 1 is
# assumed. TODO: this is only used in one place, so we should move it
# there.
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
# Methods
#


# A raw Solr query. Use this if you need absolute control over the Solr
# query. No escaping (other than URL encoding) is done.
sub solr_query
{
    my($self, @params) = @_;
    my $time = gettimeofday();
    my $metrics;
    my $wt = "";

    $self->{result} = {};

    # Construct the query string. We expect @params to contain a list of
    # arrays containing [$field, $value] pairs.
    my @query_params = ();
    foreach my $param (@params) {
        # Try to determine what kind of output we're going to get from
        # Solr based on the first wt found.
        $wt = $param->[1] if (! $wt && $param->[0] eq 'wt' && $param->[1]);
        push(@query_params, join('=', uri_escape_utf8($param->[0]), uri_escape_utf8($param->[1])));
    }

    # Run the query
    my $request = HTTP::Request->new(GET => join("?", $self->{url}, join('&', @query_params)));
    my $http_response = $self->{agent}->request($request);
    return undef unless ($http_response->is_success);
    my $response = $http_response->content;

    # Parse the response based on the output writer we expect to be used.
    if ($wt eq 'json') {
        $metrics = $self->_decode_json($response);
    } else {
        $metrics = $self->_decode_xml($response);
    }

    $self->{status}->{qtime} += $metrics->{query_time};
    #$self->{result}->{q} = uri_unescape(join("&", @query_params));
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
    ++$self->{status}->{count};
    $self->{status}->{query_time} += $metrics->{query_time};
    $self->{status}->{exec_time} += $exec_time;
    push(@{$self->{status}->{queries}}, {
        query => $self->{result}->{q},
        query_time => $metrics->{query_time},
        exec_time => $exec_time,
        hits => $metrics->{hits},
        msg => $self->{status}->{message},
    });
    $self->{status}->{message} = "nil";

    return $self->{result};
}


# General Solr query
sub query
{
    #TODO: check for undefined $query, $params
    # don't run a search if there are no query parameters in $query.

    my($self, $field, $param) = @_;
    my @query = ();
    my @params = ();

    # Load the default solr parameters
    my %solr = (%{$self->{defaults}});

    # Create arrays to hold terms for each allowed field.
    my %fields = ();
    foreach my $field (keys(%{$self->{fields}})) {
        $fields{$field} = [];
    }

    my $or_terms = 0; # Flag to OR together a pair of terms

    # Add all recognized fields to the query.
    while (my($key, $value) = each(%{$field})) {
        if ($self->{fields}->{$key}) {

            my @terms = ();
            while ($value =~ /
                ((?!:^|\s)[\-])?         # boolean prefix operator (optional); cannot be in the middle of a string
                (?:([a-z]+):)?           # field prefix
                (                        # the search term or phrase:
                  (?:".+?") |            # double-quoted phrase
                  (?:[^\"\s]+)           # single keyword
                )      
            /gx) {
                my $prefix = $1 || "";   # Negation operator (TODO: possibly others as well)
                my $field  = $2 || "";   # Field name
                my $token  = $3;         # Query term or phrase

                # | is the OR operator. If specified by itself and an OR
                # is allowed at this point, set the or_terms flag so that
                # we OR the next token with the previous.
                if ($prefix eq '' && $field eq '' && $token eq '|' && int(@query) > 0) {
                    $or_terms = 1;
                    next;
                }

                # Escape the token. Depending on whether it is a phrase or
                # single term, we use a different set of escapes.
                if (substr($token, 0, 1) eq '"') {
                    $token =~ s/[*?-]/ /g;
                    $token =~ s/([+:!(){}\\[\]^~\\])/\\$1/g;
                    $token =~ s/\bOR\b/or/g;
                    $token =~ s/\bAND\b/and/g;
                    $token =~ s/\bNOT\b/not/g;
                }
                else {
                    $token =~ s/(["+:!(){}\\[\]^~\\])/\\$1/g;
                    $token =~ s/\bOR\b/or/g;
                    $token =~ s/\bAND\b/and/g;
                    $token =~ s/\bNOT\b/not/g;
                }

                
                # Select which Solr field to use based on $field, the
                # query parameter $key, and the default field, in that
                # order of preference.
                my $solr_field = $self->{default_field};
                if ($self->{fields}->{$field}) {
                    $solr_field = $field;
                }
                elsif ($self->{fields}->{$key}) {
                    $solr_field = $key;
                }

                # If a wildcard (? or *) is used, Solr does not apply any
                # filters (e.g. ISOLAtin1Accent) so we need to do it
                # ourselves. :(
                # This filter should only be applied to fields that are
                # indexed as normalized text; not literal string fields.
                # TODO: this list is not exhaustive.
                if ($self->{'textfields'}->{$solr_field}) {
                    $token =~ tr/ÀàÁáÂâÄäÃãÅå/a/;
                    $token =~ tr/ÈèÉéÊêËë/e/;
                    $token =~ tr/ÌìÍíÎîÏï/i/;
                    $token =~ tr/ÒòÓóÔôÖöÕõØo/o/;
                    $token =~ tr/ÙùÚúÛûÜü/u/;
                    $token =~ tr/Çç/c/;
                    $token =~ tr/Ññ/n/;
                    $token =~ s/[Œœ]/oe/g;
                    $token =~ s/[Ææ]/ae/g;
                    $token = lc($token);
                }

                # Some fields have separately indexed phrase versions:
                #if (substr($token, 0, 1) eq '"' && $self->{fields}->{uc($solr_field)}) {
                #    $solr_field = uc($solr_field);
                #}


                # Add the term to the query by applying the Solr search
                # template to it.
                my $template = $self->{fields}->{$solr_field};
                $template =~ s/\%/$token/g;
                if ($or_terms) {
                    $query[-1] = '(' . $query[-1] . ' OR ' . "$prefix($template)" . ')';
                    $or_terms = 0;
                }
                else {
                    push(@query, "$prefix($template)");
                }
            }

        }
    }
    

    # Add terms to the respective fields
    foreach my $field (keys(%fields)) {
        my @terms = @{$fields{$field}};
        if (int(@terms)) {
            my @subquery = ();
            foreach my $term (@terms) {
                my $template = $self->{fields}->{$field};
                $template =~ s/\%/$term/g;
                push(@subquery, $template);
            }
            push(@query, '(' . join(' ', @subquery) . ')');
        }
    }


    #
    # Modify the query based on additional directives in $param
    #

    # Sort according to the sorting rule
    if ($param->{'sort'} && ($self->{'sort'}->{$param->{'sort'}})) {
        $solr{'sort'} = $self->{'sort'}->{$param->{'sort'}};
    }

    # Limit by type
    if ($param->{'type'} && ($self->{'type'}->{$param->{'type'}})) {
        push(@query, "($self->{'type'}->{$param->{'type'}})");
    }
    elsif ($self->{'type'}->{'default'}) {
        push(@query, "($self->{'type'}->{'default'})");
    }

    # Limit by date
    if ($param->{'date'}) {
        my $min = $param->{date}->[0];
        my $max = $param->{date}->[1];

        # We'll only accept dates as 4-digit years. (We may need to expand
        # on this at a later, um, date.)
        if ($min =~ /^\d{4}$/ && $max =~ /^\d{4}$/) {
            push(@query, "pubmin:[* TO $max-12-31T23:59:59.999Z]");
            push(@query, "pubmax:[$min-01-01T00:00:00.000Z TO *]");
        }
    }

    # Add all of the pairs under field as "($key:$value)" to the query.
    # Note that $value will not be escaped or otherwise altered.
    if ($param->{'field'}) {
        while (my($key, $value) = each(%{$param->{'field'}})) {
            push(@query, "($key:$value)");
        }
    }

    # Append additional fields to retrieve
    if ($param->{allfields}) {
        $solr{fl} = '*';
    }

    # Append additional Solr query parameters.
    if ($param->{solr}) {
        while (my($key, $value) = each(%{$param->{solr}})) {
            $solr{$key} = $value;
        }
    }

    # If a start page is specified, calculate the Solr start parameter.
    if ($param->{page}) {
        $solr{start} = (int($param->{page}) - 1) * $solr{rows} if (int($param->{page}) > 0);
    }


    # Translate the key->value pairs in %solr (defaults +
    # additions/overrides from $param->{solr}) into a list of query
    # parameters.
    while (my($param, $value) = each(%solr)) {
        if (ref($value) eq 'ARRAY') {
            foreach my $listval (@{$value}) {
                push(@params, [$param, $listval]);
            }
        }
        else {
            push(@params, [$param, $value]);
        }
    }

    # The $solr->{subset} field further limits every search.
    push(@query, "($self->{subset})") if ($self->{subset});

    # Add the query itself to the parameter list.
    push(@params, ['q', join(' ', @query)]);

    # Execute the query and return the result.
    return $self->solr_query(@params);
}


# Return an array of all the ancestors (if any) of $document, starting
# with the parent and working up the hierarchy.
#sub ancestors
#{
#    my($self, $doc) = @_;
#    my $ancestors = [];
#    my %keys = ( $doc->{key} => 1 ); # Keep track of keys we've seen to avoid circular references
#    while($doc->{pkey}) {
#        $self->{status}->{message} = "ancestors(): $doc->{key} (pkey = $doc->{pkey})";
#        my $result = $self->query(
#            { key => $doc->{pkey} },
#            { solr => { rows => 1, facet => 'false' } }
#        );
#        last unless ($result->{hits});
#        $doc= $result->{documents}->[0];
#        last if ($keys{$doc->{key}}); # Abort on circular reference
#        $keys{$doc->{key}} = 1;
#        push(@{$ancestors}, $doc);
#    }
#
#    return $ancestors;
#}


# Count the number of records found. $what is optional and will be
# appended to the status message for debugging purposes.
sub count
{
    my($self, $field, $param, $what) = @_;
    $what = "" unless ($what);

    $param->{solr}          = {} unless ($param->{solr});
    $param->{solr}->{rows}  = 0 unless ($param->{solr}->{rows});
    $param->{solr}->{facet} = 'false' unless ($param->{solr}->{facet});

    $self->{status}->{message} = "count(): $what";
    my $result = $self->query($field, $param);
    return $result->{hits} or 0;
}


# Retrieve a single document by key. Return only the fields named in
# @fields, or all fields if omitted.
sub document
{
    my($self, $key, @fields) = @_;
    $self->{status}->{message} = "document(): $key";
    my $result = $self->query(
        { key => $key },
        {
            solr => {
                rows => 1,
                facet => 'false',
            },
            type => 'any',
        }
    );

    return undef unless ($result->{hits});
    my $doc = $result->{documents}->[0];
    if (@fields) {
        my $fields = {};
        foreach my $f (@fields) { $fields->{$f} = $doc->{$f} || undef; }
        return $fields;
    }
    return $doc;
}


# Retrieve the record for the child document $seq for document $key.
sub child {
    my($self, $key, $seq) = @_;
    $self->{status}->{message} = "child(): $key";
    my $result = $self->query(
        { pkey => $key },
        {
            solr => {
                rows => 1,
                facet => 'false',
            },
            type => 'any',
            field => { seq => $seq },
        }
    );

    return undef unless ($result->{hits});
    return $result->{documents}->[0];
}


# Retreives the $field from the document in the query set with the lowest
# or highest (depending on whether $max is nonzero) value of $field.
sub limit
{
    my($self, $query, $field, $max) = @_;
    my $direction = 'asc';
    $direction = 'desc' if ($max);
    $self->{status}->{message} = "limit(): $field $direction";

    my $result = $self->query(
        $query,
        { solr => { rows => 1, 'sort' => "$field $direction" } }
    );
    return "" unless ($result->{hits});
    return $result->{documents}->[0]->{$field};
}

#sub next_doc
#{
#    my($self, $doc) = @_;
#    return undef unless ($doc->{seq});
#    my $seq = $doc->{seq} + 1;
#    $self->{status}->{message} = "next_doc(): $doc->{key}";

#    my $result = $self->query(
#        { pkey => $doc->{pkey} },
#        {
#            solr => {
#                rows => 0,
#                facet => 'false',
#                'sort' => 'seq asc',
#            },
#            field => {
#                seq => "[$seq TO *]",
#            }
#        }
#    );
#
#    return undef unless ($result->{documents}->[0]);
#    return $result->{documents}->[0];
#}

#sub prev_doc
#{
#    my($self, $doc) = @_;
#    return undef unless ($doc->{seq});
#    my $seq =  $doc->{seq} - 1;
#    $self->{status}->{message} = "prev_doc(): $doc->{key}";

#    my $result = $self->query(
#        { pkey => $doc->{pkey} },
#        {
#            solr => {
#                rows => 0,
#                facet => 'false',
#                'sort' => 'seq desc',
#            },
#            field => {
#                seq => "[* TO $seq]"
#            },
#        }
#    );

#    return undef unless ($result->{documents}->[0]);
#    return $result->{documents}->[0];
#}


# Retrieve the query status log.
sub status
{
    my($self) = @_;
    return $self->{status};
}

1;
