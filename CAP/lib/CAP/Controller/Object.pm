package CAP::Controller::Object;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Object - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub main :Private
{
    my($self, $c, $key) = @_;
    my $solr =  $c->stash->{solr};

    my $doc = $solr->document($key);
    $c->detach('/error', [404, "Record not found: $key"]) unless ($doc);
    $c->stash->{response}->{doc} = $doc;

    $c->stash->{response}->{type} = 'object';

    # Get some information about the parent item, if it exists.
    $c->stash->{response}->{parent} = $solr->document($doc->{pkey}, 'label', 'key', 'canonicalUri') if ($doc->{pkey});

    # Count the number of child documents and pages
    $c->stash->{response}->{children} = {
        pages => $solr->count({pkey => $doc->{key}}, {type => 'page'}),
        docs  => $solr->count({pkey => $doc->{key}}, {type => 'document'}),
    };

    $c->stash->{template} = 'object.tt';
    return 1;
}

__PACKAGE__->meta->make_immutable;

