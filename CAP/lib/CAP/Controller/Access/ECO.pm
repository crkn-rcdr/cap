package CAP::Controller::Access::ECO;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub has_access :Private {
    my ($self, $c, $doc, $key, $resource_type, $size) = @_;
    my $access_level = $c->forward('access_level', [$doc]);

    # Access level 2: always grant access
    if ($access_level == 2) {
        return 1;
    }
    
    # Access level 1: grant access for derivatives only.
    if ($access_level == 1) {
        if ($resource_type eq 'derivative') {
            return 1;
        }
        return 0;
    }
    
    # Otherwise, only allow restricted preview access:

    # Only derivative images are allowed; no PDF downloads
    return 0 if ($resource_type ne 'derivative');

    # Only show the first 10 pages maximum
    return 0 if ($doc->{seq} > 10);

    # Maximum image width is 1200 pixels
    my($width, $height) = split(/x/, $size);
    return 0 if int($width) > 800;


    # Grant preview access
    return 1;

}

sub access_level :Private {
    my ($self, $c, $doc) = @_;
    my $solr = $c->stash->{solr};
#TEMPORARY (though this whole controller is going away, so....)
return 1; 

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
    elsif ($c->session->{sponsored_collections}->{$collection}) {
        return 1;
    }

    # Non-subscribed collection: preview access (depends on page position)
    else {
        return 0;
    }

}

# Determine the number of credits required to purchase the selected document.
sub credit_cost :Private {
    my ($self, $c, $doc) = @_;

    # Only documents can be purchased; not pages or series.
    return 0 unless ($doc->type_is('document'));

    # Number of pages:
    #my $pages = int(@{$doc->record->pg_label});
    return 0 if ($doc->child_count == 0); # Shouldn't ever happen, but...
    return 1 if ($doc->child_count <= 50);
    return 2 if ($doc->child_count <= 500);
    return 3;
}

__PACKAGE__->meta->make_immutable;

