package CAP::Schema::ResultSet::Terms;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use utf8;

=head2 create_hierarchy($self, \@keys, \@terms)

Create or update the thesaurus with a hierarchy of terms defined by
\@terms and the corresponding sort \@keys. Terms will be created or
updated based on matching sort keys within the hierarchy, so this will
overwrite any existing term with the same sortkey and the same place in
the hierarchy (same parent key).

Returns a list of all of the row ids.

=cut
sub create_hierarchy {
    my($self, $keys, $terms) = @_;
    my @key = ();
    my @ids = ();
    my $parent = undef;

    die("Uneven number of keys and terms") unless (@{$keys} == @{$terms});
    while(@{$keys}) {
        my($sortkey) = $self->normalize_sortkey(shift(@{$keys}));
        my($term) = shift(@{$terms});

        # Determine if there is a pre-existing entry with the same parent
        # and key. If there is, update it. If not, create a new term.
        my $entry = $self->search({ parent => $parent, sortkey => $sortkey })->first;
        if ($entry) {
            $entry->update({ term => $term });
        }
        else {
            $entry = $self->create({
                parent => $parent,
                sortkey => $sortkey,
                term => $term
            });
        }

        push(@ids, $entry->id);
        $parent = $entry->id;
    }

    return @ids;
}

sub normalize_sortkey {
    my($self, $key) = @_;

    # Normalize space
    $key =~ s/^\s+//;
    $key =~ s/\s+$//;
    $key =~ s/\s+/ /g;

    # Strip accents (TODO: needs more work)
    $key =~ tr/ÀàÁáÂâÄäÃãÅå/a/;
    $key =~ tr/ÈèÉéÊêËë/e/;
    $key =~ tr/ÌìÍíÎîÏï/i/;
    $key =~ tr/ÒòÓóÔôÖöÕõØo/o/;
    $key =~ tr/ÙùÚúÛûÜü/u/;
    $key =~ tr/Çç/c/;
    $key =~ tr/Ññ/n/;
    $key =~ s/[Œœ]/oe/g;
    $key =~ s/[Ææ]/ae/g;

    # Normalize case
    $key = lc($key);

    # Remove characters other than alphanumeric, space, underscore, hyphen
    $key =~ s/[^a-z0-9 _-]//g;

    return $key;
}

# Fetch all top-level thesaurus terms

sub top_level_terms {
    my($self, $portal) = @_;
    my $list = [];

    my $terms = $self->search({ parent => undef }, { order_by  => { -asc => 'sortkey' }});
    while (my $row = $terms->next) {
        push(@{$list}, $row);
    }

    return $list;
}


=head2 narrower_terms($portal, $id)

Retrieve all terms with parent $id containing documents belonging to $portal.

=cut
sub narrower_terms {
    my($self, $portal, $term_id) = @_;
    my $list = [];


    # Get the term we want narrower terms for.
    my $parent = $self->get_term($term_id);
    return undef unless ($parent);

    my $terms = $self->search(
        { parent => $parent->id, 'portals_titles.portal_id' => $portal->id },
        {
            select   => [ 'me.id', 'parent', 'sortkey', 'term', { count => 'me.id' } ],
            as       => [ 'id', 'parent', 'sortkey', 'term', 'count' ],
            join     => { 'titles_terms' => { 'title_id' =>  'portals_titles' }},
            distinct => [ 'id' ],
            order_by => { -asc => 'sortkey' },
        }
    );

    while (my $row = $terms->next) {
        push(@{$list}, $row);
    }

    return $list;
}

sub path {
    my($self, $id) = @_;
    my $path = [];
    my $term = $self->get_term($id);
    return undef unless ($term);

    for(;;) {
        unshift(@{$path}, $term);
        last unless ($term->parent);
        $term = $self->get_term($term->parent);
    }
    return $path;
}


# Retrieve a term based on its unique ID.
sub get_term {
    my($self, $id) = @_;
    my $record = $self->find({ id => $id });
    return undef unless ($record);
    return $record;
}

# Retrieve a term by its name and parent ID.
sub get_child_term {
    my($self, $parent, $term) = @_;
    my $child_term = $self->find({ parent => $parent, term => $term });
    return $child_term;
}

# Add a term to the thesaurus. @path is the full term path and $label is
# the displayable lable text for the term.
sub add_term {
    my($self, $label, @path) = @_;
    my $parent = undef;
    my $term = undef;

    # Make sure we have a path.
    return undef unless (@path);

    # Walk down the path to find the parent for the new term. If the new
    # term already exists but has a different label, update it.
    while(@path) {
        my $term_name = shift(@path);
        $term = $self->get_child_term($parent, $term_name);
        if (! $term) {
            # Only the leaf term is allowed to be missing.
            if (@path) {
                warn("Missing parent term: $term_name\n");
                return undef;
            }
            else {
                warn("Creating $term_name as $label\n");
                my $new_term = $self->create({parent => $parent, term => $term_name, label => $label});
                return $new_term->id;
            }
        }
        elsif (@path == 0) {
            if ($term->label ne $label) {
                warn("Updating $term_name from " . $term->label . " to $label\n");
                $term->update({ label => $label });
            }
            return $term->id;
        }
        else {
            $parent = $term->id;
        }
    }

}

sub term_has_children {
    my($self, $id) = @_;
    return $self->search({ parent => $id })->count() > 0;
}


1;

