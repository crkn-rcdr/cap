package CAP::Schema::ResultSet::Thesaurus;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

sub top_level_terms {
    my($self) = @_;
    my $list = [];

    my $terms = $self->search({ parent => undef }, { order_by => { -asc => 'term' } });
    while (my $row = $terms->next) {
        push(@{$list}, { term => $row });
    }

    return $list;
}

sub narrower_terms {
    my($self, $id) = @_;
    my $list = [];

    # Get the term we want narrower terms for.
    my $parent = $self->get_term($id);
    return undef unless ($parent);

    my $terms = $self->search({ parent => $parent->id }, { order_by => { -asc => 'term' } });
    while (my $row = $terms->next) {
        push(@{$list}, { term => $row });
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


1;

