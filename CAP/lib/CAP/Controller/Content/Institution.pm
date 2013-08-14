package CAP::Controller::Content::Institution;
use Moose;
use namespace::autoclean;
use CAP::Util;


__PACKAGE__->config(
    map => {
        'text/html' => [ 'View', 'Default' ],
    },
);

BEGIN { extends 'Catalyst::Controller::REST'; }

=head1 NAME

CAP::Controller::Content::Institution - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/') PathPart('content/institution') CaptureArgs(1) {
    my($self, $c, $institution_id) = @_;

    my $institution = $c->model('DB::Institution')->find({ id => $institution_id});
    if (! $institution) {
        $c->message({ type => "error", message => "institution_not_found" });
        $self->status_not_found( $c, message => "No such institution");
        $c->res->redirect($c->uri_for_action('/content/index'));
        $c->detach();
    }
    my $page = int($c->req->params->{page} || 1);

    $c->stash(
        entity => $institution,
        page => $page,
        portal_list => [$c->model('DB::Portal')->list]
    );
    return 1;
}

sub index : Chained('base') :PathPart('') :Args(0) {
    my($self, $c)  = @_;
    my $institution = $c->stash->{entity};

    my $portal_counts = [];
    foreach my $portal (($c->model('DB::Portal')->list)) {
        my $hosted = $c->model('DB::Titles')->titles_for_institution($institution, portal => $portal, hosted => 1)->count;
        my $not_hosted = $c->model('DB::Titles')->titles_for_institution($institution, portal => $portal, hosted => 0)->count;
        my $indexed = $c->model('DB::Titles')->titles_for_institution($institution, portal => $portal)->count;
        push(@{$portal_counts}, { portal => $portal, hosted => $hosted, not_hosted => $not_hosted, indexed => $indexed });
    }

    $c->stash(
        titles => $c->model('DB::Titles')->titles_for_institution($institution)->count,
        unassigned => $c->model('DB::Titles')->titles_for_institution($institution, unassigned => 1)->count,
        portal_counts => $portal_counts
    );
    return 1;
}

sub titles : Chained('base') :Path('titles') {
    my($self, $c) = @_;
    my $institution = $c->stash->{entity};
    my $page = $c->stash->{page};
    my $titles;

    my $identifier = $c->req->params->{identifier};
    my $label = $c->req->params->{label};
    my $portal;
    my $unassigned;
    my $hosted;
    if ($c->req->params->{portal}) {
        if ($c->req->params->{portal} eq '!') {
            $unassigned = 1;
        }
        else {
            $portal = $c->model('DB::Portal')->find($c->req->params->{portal});
        }
    }
    if ($c->req->params->{hosted}) {
        $hosted = 1 if ($c->req->params->{hosted} eq 'hosted');
        $hosted = 0 if ($c->req->params->{hosted} eq 'indexed');
    }
    $titles = $c->model('DB::Titles')->titles_for_institution(
        $institution,
        page => $page,
        identifier => $identifier,
        label => $label,
        portal => $portal,
        unassigned => $unassigned,
        hosted => $hosted
    );

    # Update these titles if the update action is selected.
    if ($c->req->params->{submit} && $c->req->params->{submit} eq 'update') {
        foreach my $title ($titles->all) {
            $title->update_if_valid({
                level => $c->req->params->{level},
                transcribable => $c->req->params->{transcribable}
            });
        }
    }

    $c->stash(
        pager  => $titles->pager,
        titles => [$titles->all],
    );
    return 1;
}

sub assign : Chained('base') :Path('assign') :Args(0) {
    my($self, $c) = @_;
    my $institution = $c->stash->{entity};
    my $portal_id = $c->req->params->{portal} || "";
    my $hosted = $c->req->params->{hosted} || 0;
    my $titles = $c->req->params->{titles};
    my $batch = $c->req->params->{batch} || "";
    $hosted = 1 if ($hosted);

    my $portal = $c->model('DB::Portal')->find({ id => $portal_id });
    if (! $portal) {
        $c->message({ type => "error", message => "portal_not_found" });
        $self->status_not_found( $c, message => "No such portal");
        $c->res->redirect($c->uri_for_action('/content/institution/index', [ $institution->id ]));
        $c->detach();
    }

    my $title_list;
    my $title_count = 0;
    if (! $titles) {
        my @notfound = ();
        foreach my $identifier (split(/\s+/s, $batch)) {
            warn "Adding $identifier\n";
            my $title = $c->model('DB::Titles')->find({ identifier => $identifier });
            if ($title) {
                $c->model('DB::PortalsTitles')->update_or_create({
                    portal_id => $portal->id,
                    title_id => $title->id,
                    hosted => $hosted
                });
                ++$title_count;
            }
            else {
                push(@notfound, $identifier);
            }
        }
        if ($title_count > 0) {
            $c->message({ type => "success", message => "added_titles", params => [ $title_count, $portal->title($c->stash->{lang}) ] });
        }
        if (@notfound) {
            $c->message({ type => "failure", message => "identifier_not_found", params => [ join(", ", @notfound) ] });
        }
    }
    elsif ($titles eq 'all') {
        $title_list = $c->model('DB::Titles')->titles_for_institution($institution);
        $title_count = $title_list->count;
        while (my $title = $title_list->next) {
            $c->model('DB::PortalsTitles')->update_or_create({
                portal_id => $portal->id,
                title_id => $title->id,
                hosted => $hosted
            });
        }
        $c->message({ type => "success", message => "added_titles", params => [ $title_count, $portal->name($c->stash->{lang}) ] });
    }
    elsif ($titles eq 'unassigned') {
        $title_list = $c->model('DB::Titles')->titles_for_institution($institution, unassigned => 1);
        $title_count = $title_list->count;
        while (my $title = $title_list->next) {
            $c->model('DB::PortalsTitles')->update_or_create({
                portal_id => $portal->id,
                title_id => $title->id,
                hosted => $hosted
            });
        }
        $c->message({ type => "success", message => "added_titles", params => [ $title_count, $portal->title($c->stash->{lang}) ] });
    }

    $c->res->redirect($c->uri_for_action('/content/institution/index', [ $institution->id ]));
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
