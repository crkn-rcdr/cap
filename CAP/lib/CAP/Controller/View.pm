package CAP::Controller::View;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::View - Catalyst Controller

=cut

sub index :Path('') {
    my($self, $c, $key, $seq) = @_;

    my $doc;
    eval {
        $doc = $c->model('Access::Presentation')->fetch($key, $c->portal->id);
    };
    $c->detach('/error', [404, "Presentation fetch failed on document $key: $@"]) if $@;

    if ($doc->is_type('series')) {
        $c->detach('view_series', [$doc]);
    } elsif ($doc->is_type('document')) {
        $c->detach('view_item', [$doc, $seq]);
    } elsif ($doc->is_type('page')) {
        if (defined $c->request->query_params->{fmt} && $c->request->query_params->{fmt} eq 'ajax') {
            $c->detach('view_component', [$doc]);
        } else {
            $c->response->redirect($c->uri_for_action('view/index', $doc->record->{pkey}, $doc->record->{seq}));
        }
        $c->detach();
    } else {
        $c->detach('/error', [404, "Presentation document has unsupported type $doc->record->{type}: $key"]);
    }
}

sub view_component :Private {
    my ($self, $c, $component) = @_;

    $c->stash(
        component => $component,
        tag_types => [qw/tag tagPerson tagName tagPlace tagDate tagNotebook/],
        description_types => [qw/tagDescription/],
        template => "view_component.tt"
    );
}

sub view_item :Private {
    my ($self, $c, $item, $seq) = @_;

    $item->authorize_item($c->auth);

    if ($item->has_children) {
        $seq = $item->first_component_seq unless ($seq && $seq =~ /^\d+$/);
        
        # Make sure the requested page exists.
        $c->detach("/error", [404, "Page not found: $seq"]) unless $item->has_child($seq);

        # Set image size and rotation
        my $size = 1;
        my $rotate = 0;
        if (defined($c->request->query_params->{s}) && defined($item->derivative->{config}->{size}->{$c->request->query_params->{s}})) {
            $size = int($c->request->query_params->{s});
        }
        if (defined($c->request->query_params->{r}) && defined($item->derivative->{config}->{rotate}->{$c->request->query_params->{r}})) {
            $rotate = int($c->request->query_params->{r});
        }

        $c->stash(
            item => $item,
            seq => $seq,
            rotate => $rotate,
            size => $size,
            template => "view_item.tt",
        );
    } else { # we don't have a item with components
        $c->stash(
            item => $item,
            template => "view_item.tt"
        );
    }
    return 1;
}

sub view_series :Private {
    my ($self, $c, $series) = @_;
    $c->stash(
        series => $series,
        template => "view_series.tt"
    );
    
    return 1;
}

# Select a random document
sub random : Path('/viewrandom') Args() {
    my($self, $c) = @_;

    my $doc;
    eval {
        $doc = $c->model('Access::Search')->random_document({
            root_collection => $c->portal->id
        })->{resultset}{documents}[0];
    };
    $c->detach('/error', [503, "Solr error: $@"]) if ($@);

    $c->res->redirect($c->uri_for_action('view/index', $doc->{key}));
    $c->detach();
}

__PACKAGE__->meta->make_immutable;

