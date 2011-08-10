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

sub access_level :Private {
    my ($self, $c, $doc) = @_;
    my $solr = $c->stash->{solr};

    # The collection flag is part of the document object; if this is a
    # page (which is the most common case) get the collection from the
    # parent object.
    my $collection;
    my $doc_key;
    if ($doc->{type} eq 'page') {
        $collection = $solr->document($doc->{pkey})->{collection} || "";
        $doc_key = $doc->{pkey};
    }
    else {
        $collection = $doc->{collection} || "";
        $doc_key = $doc->{key};
    }


    # Registered user, document purchased: full access
    if ($c->session->{purchased_documents}->{$doc_key}) {
        return 2;
    }

    # Registered user, subscriber: full access
    elsif ($c->session->{is_subscriber}) {
        return 2;
    }

    # Registered user, individual collection subscription: full access
    elsif ($c->session->{subscribed_collections}->{$collection}) {
        return 2;
    }

    # Institutional subscriber: full access
    elsif ($c->session->{subscribing_institution}) {
        return 2;
    }

    # Sponsored collection: view access
    elsif ($c->session->{sponsored_collection}->{$collection}) {
        return 1;
    }

    # Non-subscribed collection: preview access (depends on page position)
    else {
        return 0;
    }

}

__PACKAGE__->meta->make_immutable;

