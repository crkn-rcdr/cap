package CAP::Controller::Link;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

# Log and redirect to the canonical URI for document $key.
sub index :Path :Args(1) {
    my ( $self, $c, $key ) = @_;

    my $doc = $c->model("Solr")->document($key, subset => $c->portal->subset);
    $c->detach("/error", [404, "Record not found: $key"]) unless $doc && $doc->found && $doc->record->canonicalUri;

    $c->model('DB::OutboundLink')->create({
        portal_id => $c->portal->id,
        contributor => $doc->record->contributor,
        document => $doc->key,
        url => $doc->record->canonicalUri,
    });

    $c->res->redirect($doc->record->canonicalUri);
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;
