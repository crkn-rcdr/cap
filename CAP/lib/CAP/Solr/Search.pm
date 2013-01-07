package CAP::Solr::Search;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;
use WebService::Solr;
use CAP::Solr::Query;
use CAP::Solr::ResultSet;

# Properties from parameters passed to the constructor
has 'solr'    => (is => 'ro', isa => 'WebService::Solr', required => 1);
has 'params'  => (is => 'rw', isa => 'HashRef');
has 'options' => (is => 'rw', isa => 'HashRef');
has 'sorting' => (is => 'rw', isa => 'HashRef');
has 'subset'  => (is => 'rw', isa => 'Str', default => '');
has 'query'   => (is => 'rw', isa => 'CAP::Solr::Query');

method BUILD {
    $self->_initialize();
}

method _initialize () {
    # Create empty q,tx parameters if none were specified.
    $self->params->{q} ||= "";
    $self->params->{tx} ||= "";

    # Limit the query when necessary
    $self->query->limit_type($self->params->{t});
    $self->query->limit_date($self->params->{df}, $self->params->{dt});

    # Set up the query
    my $query_string = $self->query->rewrite_query($self->params);
    my $base_field = $self->params->{field} || 'q';
    $self->query->append($query_string, parse => 1, base_field => $base_field);
    $self->query->append($self->subset);

    # Add sorting to options
    $self->options->{sort} = $self->_sort_order($self->params->{so});
}

method run (HashRef :$options = {}, Str :$page = 0, Str :$raw = 0) {

    # Merge any supplied options with the default options.
    $options = { %{$self->options}, %{$options} };

    # If a page number is specified, calculate the starting record based
    # on the page number and number of rows per page.
    $options->{start} = ($page - 1) * $options->{rows} if ($page);
    
    my $response = $self->solr->search($self->query->to_string(), $options);

    # Return either the parsed ResultSet (default) or the HTTP::Response
    # object, depending on what was requested.
    if ($raw) {
        return $response->raw_response if ($raw);
    }
    else {
        return undef unless ($response->ok);
        my $resultset = new CAP::Solr::ResultSet({ solr => $self->solr, response => $response});
        return $resultset;
    }
}

# Get the earliest publication date in the result set for $query
method pubmin () {
    return $self->_pubbound('pubmin', 'pubmin asc');
}

# Get the latest publication date in the result set for $query
method pubmax () {
    return $self->_pubbound('pubmax', 'pubmax desc');
}

method _pubbound (Str $field, Str $sort) {
    my $result = $self->solr->search($self->query->to_string(), { 'start' => 0, 'rows' => 1, 'sort' => $sort, 'fl' => $field });
    if ($result->docs->[0]) {
        return $result->docs->[0]->value_for($field) || "";
    }
    else {
        return "";
    }
}


# Return a count of records for $query
method count () {
    my $response = $self->run(options => { rows => 0 });
    return undef unless ($response);
    return $response->hits;
}

# Returns the $pos'th record in the result set (e.g. $pos = 2 == 2nd
# record in the result set). Returns a CAP::Solr::Document object.
method nth_record (Int $pos) {
    my $response = $self->run(options => { start => $pos, rows => 1 });
    return undef unless ($response);
    return $response->docs->[0];
}

method _sort_order (Maybe [Str] $sort) {
    return $self->sorting->{$sort} || $self->sorting->{default};
}

__PACKAGE__->meta->make_immutable;

