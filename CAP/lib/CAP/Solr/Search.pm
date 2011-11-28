package CAP::Solr::Search;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;
use WebService::Solr;
use CAP::Solr::ResultSet;

# Properties from parameters passed to the constructor
has 'server'     => (is => 'ro', isa => 'Str', required => 1);
has 'options'    => (is => 'ro', isa => 'HashRef');
has 'subset'     => (is => 'ro', isa => 'Str', default => '');

has 'resultset'  => (is => 'ro', isa => 'CAP::Solr::ResultSet');

method query (Str $query, HashRef :$options = {}, Str :$page = 0) {

    # Merge any supplied options with the default options.
    $options = { %{$self->options}, %{$options} };

    # If a page number is specified, calculate the starting record based
    # on the page number and number of rows per page.
    $options->{start} = ($page - 1) * $options->{rows} if ($page);
    
    my $solr = new WebService::Solr($self->server);
    $query = join('', $query, ' AND (', $self->subset, ')') if ($self->subset);
    my $response = $solr->search($query, $options);
    return undef unless ($response->ok);
    my $resultset = new CAP::Solr::ResultSet({ server => $self->server, response => $response});

    return $resultset;
}

# Get the earliest publication date in the result set for $query
method pubmin (Str $query) {
    my $solr = new WebService::Solr($self->server);
    $query = join('', $query, ' AND (', $self->subset, ')') if ($self->subset);
    my $result = $solr->search($query, { 'start' => 0, 'rows' => 1, 'sort' => 'pubmin asc', 'fl' => 'pubmin' });
    if ($result->docs->[0]) {
        return $result->docs->[0]->value_for('pubmin');
    }
    else {
        return "";
    }
}

# Get the latest publication date in the result set for $query
method pubmax (Str $query) {
    my $solr = new WebService::Solr($self->server);
    $query = join('', $query, ' AND (', $self->subset, ')') if ($self->subset);
    my $result = $solr->search($query, { 'start' => 0, 'rows' => 1, 'sort' => 'pubmax desc', 'fl' => 'pubmax' });
    if ($result->docs->[0]) {
        return $result->docs->[0]->value_for('pubmax');
    }
    else {
        return "";
    }
}


# Return a count of records for $query
method count (Str $query) {
    my $response = $self->query($query, options => { rows => 0 });
    return undef unless ($response);
    return $response->hits;
}

# Returns the $pos'th record in the result set (e.g. $pos = 2 == 2nd
# record in the result set). Returns a CAP::Solr::Document object.
method nth_record (Str $query, Int $pos) {
    my $response = $self->query($query, options => { start => $pos, rows => 1 });
    return undef unless ($response);
    return $response->docs->[0];
}

__PACKAGE__->meta->make_immutable;

