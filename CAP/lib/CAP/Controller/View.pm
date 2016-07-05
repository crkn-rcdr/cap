package CAP::Controller::View;
use Moose;
use namespace::autoclean;
use POSIX qw(strftime);
use feature "switch";
no warnings "experimental::smartmatch";
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

=head1 NAME

CAP::Controller::View - Catalyst Controller

=cut

sub index :Path('') {
    my($self, $c, $key, $seq) = @_;

    my $doc;
    eval {
        $doc = $c->model('Access::Presentation')->fetch($key);
    };
    $c->detach('/error', [404, "Presentation fetch failed on document $key: $@"]) if $@;

    if ($doc->is_type('series')) {
        $c->detach('view_series', [$doc]);
    } elsif ($doc->is_type('document')) {
        $c->detach('view_item', [$doc, $seq]);
    } elsif ($doc->is_type('page')) {
        $c->response->redirect($c->uri_for_action('view', $doc->record->{pkey}, $doc->record->{seq}));
        $c->detach();
    } else {
        $c->detach('/error', [404, "Presentation document has unsupported type $doc->record->{type}: $key"]);
    }
}

sub view_item :Private {
    my ($self, $c, $item, $seq) = @_;

    $seq = $item->first_component_seq unless ($seq && $seq =~ /^\d+$/);

    if ($item->has_children) {
        # Make sure the requested page exists.
        $c->detach("/error", [404, "Page not found: $seq"]) unless $item->has_child($seq);

        # Set image size and rotation
        my $size = 1;
        my $rotate = 0;
        if (defined($c->request->query_params->{s}) && defined($item->content->{derivative_config}->{size}->{$c->request->query_params->{s}})) {
            $size = int($c->request->query_params->{s});
        }
        if (defined($c->request->query_params->{r}) && defined($item->content->{derivative_config}->{rotate}->{$c->request->query_params->{r}})) {
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

    # TODO: figure out a better solution than hardcoding this
    if ($c->portal->id eq 'parl') {
        my @tree = $c->model('DB::Terms')->term_tree($c->portal);
        $c->stash(
            browse => \@tree,
            id_prefix => "oop.",
        );
    }
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

