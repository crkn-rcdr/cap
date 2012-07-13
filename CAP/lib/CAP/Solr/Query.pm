package CAP::Solr::Query;
use strict;
use warnings;
use feature qw(switch);
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;
use utf8;

has 'query'         => (is => 'ro', isa => 'ArrayRef', default => sub{[]});
has 'fields'        => (is => 'ro', isa => 'HashRef', required  => 1);
has 'types'         => (is => 'ro', isa => 'HashRef', required  => 1);
has 'sorting'       => (is => 'ro', isa => 'HashRef', required => 1);
has 'default_field' => (is => 'ro', isa => 'Str', required => 1);


method append (Maybe [Str] $fragment = "", Int :$parse = 0, Str :$base_field = '') {
    return 0 unless ($fragment);
    my @query = ();
    if ($parse) {

        my $or_terms = 0; # Join the next parameter with the previous using the OR operator
        while ($fragment =~ /
            ((?!:^|\s)[\-])?         # boolean prefix operator (optional); cannot be in the middle of a string
            (?:([a-z]+):)?           # field prefix
            (                        # the search term or phrase:
              (?:".+?") |            # double-quoted phrase
              (?:[^\"\s]+)           # single keyword
            )      
        /gx) {
                my $prefix = $1 || "";                # Negation operator (optional)
                my $field  = $2 || ""; chomp($field); # Field name (optional)
                my $token  = $3;                      # Query term or phrase, or the OR (|) operator

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

            # Set the field to query. If not explicitly specified, the
            # base_field parameter is used.
            if (! $field) {
                $field = $base_field;
            }
            else {
                $field = $self->default_field unless ($self->fields->{$field});
            }

            # If a wildcard (? or *) is used, Solr does not apply any
            # filters (e.g. ISOLAtin1Accent) so we need to do it
            # ourselves. :(
            # This filter should only be applied to fields that are
            # indexed as normalized text; not literal string fields.
            # TODO: this list is not exhaustive.
            if ($self->fields->{$field}->{type} eq 'text') {
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

            my $template = $self->fields->{$field}->{template};
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
    else {
        push(@query, $fragment);
    }

    push (@{$self->{query}}, join(" AND ", @query));
    return 1;
}


# Rewrite query to remove parameterized field queries and add them to the
# base query object. Parameters in $params that are not field query
# parameters are kept intact, so (e.g.) an entire set of request
# parameters can be passed to this method and only the relevant ones will
# be altered.
method rewrite_query (HashRef $params) {
    my @field_params = ();
    my $query_field  = "";
    foreach my $field (keys (%{$params})) {
        if ($self->fields->{$field}) {
            if ($self->fields->{$field}->{canonical}) {
                $query_field = $field;
            }
            else {
                push(@field_params, $field) if ($params->{$field});
            }
        }
    }

    my $query_string = $params->{$query_field};

    foreach my $field (@field_params) {
        if ($params->{$field}) {
            my @value = ();

            while ($params->{$field} =~ /
                ((?!:^|\s)[\-])?         # boolean prefix operator (optional); cannot be in the middle of a string
                (                        # the search term or phrase:
                  (?:".+?") |            # double-quoted phrase
                  (?:[^\"\s]+)           # single keyword
                )      
            /gx) {
                my $bool = $1 || "";
                my $query = $2 || "";

                push(@value, "$bool$field:$query");
            }

            $query_string = join(" ", $query_string, @value);
        }
    }

    return $query_string;
}

method limit_type (Maybe [Str] $type) {
    if ($type && exists($self->types->{$type})) {
        $self->append($self->types->{$type});
    }
    else {
        $self->append($self->types->{default});
    }
}

method limit_date (Maybe [Str] $from, Maybe [Str] $to) {
    # New as of 13 July 2012: treat date values independently of each other
    return unless ($to || $from);
    if ($from) {
        $from =~ s/\s+//gs;
        if ($from =~ /^\d{4}$/) {
            $self->append("pubmax:[$from-01-01T00:00:00.000Z TO * ]");
        }
    }
    if ($to) {
        $to   =~ s/\s+//gs;
        if ($to  =~ /^\d{4}$/) {
            $self->append("pubmin:[* TO $to-12-31T23:59:59.999Z]");
        }
    }
}

method sort_order (Maybe [Str] $sort) {
    return $self->sorting->{default} unless ($sort && $self->sorting->{$sort});
    return $sort && $self->sorting->{$sort};

}

method to_string {
    return join(' AND ', @{$self->query});
}

method list_fields {
    return keys(%{$self->fields});
}

__PACKAGE__->meta->make_immutable;


