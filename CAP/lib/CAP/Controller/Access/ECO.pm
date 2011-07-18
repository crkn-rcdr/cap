package CAP::Controller::Access::ECO;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Access::ECO - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub has_access :Private {
    my ($self, $c, $doc) = @_;
    my $solr = $c->stash->{solr};

    # The collection flag is part of the document object; if this is a
    # page (which is the most common case) get the collection from the
    # parent object.
    my $collection;
    if ($doc->{type} eq 'page') {
        $collection = $solr->document($doc->{pkey})->{collection} || "";
    }
    else {
        $collection = $doc->{collection} || "";
    }

    # TODO: check for individual document ownership here
    return 1 if ($c->session->{bookshelf}->{$doc->{key}});

    # Records that belong to no collection are not accessible via
    # subscription.
    return 0 unless($collection);

    # Otherwise, check whether the user subscribes to this collection.
    return 1 if ($c->session->{subscriptions}->{$collection});

    return 0;

}

__PACKAGE__->meta->make_immutable;

