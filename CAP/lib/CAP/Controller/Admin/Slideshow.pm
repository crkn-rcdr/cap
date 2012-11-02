package CAP::Controller::Admin::Slideshow;
use Moose;
use namespace::autoclean;
use Encode;
use feature "switch";
use List::MoreUtils qw/ uniq /;
use Data::Dumper;

__PACKAGE__->config(
    map => {
        'text/html' => [ 'View', 'Default' ],
    },
);

BEGIN { extends 'Catalyst::Controller::REST'; }


#
# Index: list extant slideshows, start new ones
#


sub index :Path :Args(0) ActionClass('REST') {
    my($self, $c) = @_;
}

sub index_GET {
    my($self, $c) = @_;
    my $list = {};
    my $slideshows = [$c->model('DB::Slide')->search({}, {
                order_by => { -asc => [qw/ portal slideshow /] },
                group_by => [qw/ portal slideshow /],
                '+select' => [ {'count' => '*'} ],
                '+as' => [ 'count' ]
            })];
    my %portals = ();
    foreach($c->model("DB::PortalString")->search({ lang => $c->stash->{lang}, label => 'name'})) {
        $portals{$_->get_column('portal_id')} = $_->get_column('string');
    }
    $c->stash(
        {
            slideshows => $slideshows,
            portals => \%portals
        }
    );
    $self->status_ok($c, entity => $list);
    return 1;
}

sub delete :Path('delete') :Args(0) {
    my($self, $c) = @_;
    my $portal = $c->req->params->{portal};
    my $slideshow = $c->req->params->{show};
    $c->model('DB::Slide')->search({ portal => $portal, slideshow => $slideshow })->delete_all();
    $c->message({ type => "success", message => "slideshow_deleted" });
    $c->response->redirect($c->uri_for_action("/admin/slideshow/index"));
    return 1;
}

sub show :Path('show') :Args(0) {
    my ($self, $c) = @_;
    my $portal = $c->req->params->{portal};
    my $slideshow = $c->req->params->{show};
    unless ($portal && $slideshow) {
        $c->response->redirect($c->uri_for_action("/admin/slideshow/index"));
        return 1;
    }

    $c->stash(
        {
            slides => $c->model('DB::Slide')->get_slides($portal, $slideshow),
            show_portal => $portal,
            show_location => $slideshow
        }
    );
    return 1;
}

#
# create_slide: add a new slide to a slideshow
#

sub create_slide :Path('create_slide') :Args(0) {
    my($self, $c) = @_;
    my %data = %{$c->req->body_params};
    my $slide_count = $c->model('DB::Slide')->search({ portal => $data{portal}, slideshow => $data{slideshow} })->count;
    
    my $slide = $c->model('DB::Slide')->create(
        {
            portal => $data{portal},
            slideshow => $data{slideshow},
            'sort' => $slide_count + 1,
            url => $data{url},
            thumb_url => $data{thumb_url},
        }
    );

    foreach my $key (grep(/^text_/, keys(%data))) {
        if ($key =~ /^text_(\w{2,3})/ && $data{$key}) {
            $slide->update_or_create_related('slide_descriptions', { lang => $1, description => $data{$key} });
        }
    }

    $c->response->redirect($c->uri_for_action("/admin/slideshow/show", { portal => $data{portal}, show => $data{slideshow} }));
}

sub swap_slide :Path('swap_slide') :Args(2) {
    my($self, $c, $id, $new_sort) = @_;
    my $slide = $c->model("DB::Slide")->find($id);
    if ($slide) {
        my $portal = $slide->get_column("portal");
        my $show = $slide->get_column("slideshow");
        my $other_slide = $c->model("DB::Slide")->search({ portal => $portal, slideshow => $show, 'sort' => $new_sort })->first();
        if ($other_slide) {
            my $old_sort = $slide->get_column("sort");
            eval {
                my $txn = sub {
                    $slide->update({ 'sort' => $new_sort });
                    $other_slide->update({ 'sort' => $old_sort });
                };
                $c->model("DB")->txn_do($txn);
            };
            $c->detach("/error", [500]) if ($@);
        }
        $c->response->redirect($c->uri_for_action("/admin/slideshow/show", { portal => $portal, show => $show }));
    } else {
        $c->message({ type => "error", message => "slide_not_found" });
        $c->response->redirect($c->uri_for_action("/admin/slideshow/index"));
    }
    return 1;
}

sub edit_slide :Path('edit_slide') :Args(1) :ActionClass('REST') {
}

sub edit_slide_GET {
    my ($self, $c, $id) = @_;
    my $slide = $c->model("DB::Slide")->find($id);
    if ($slide) {
        my $descriptions = {};
        foreach my $description ($slide->search_related('slide_descriptions')) {
            $descriptions->{$description->lang} = $description->description;
        }
        $c->stash({ slide => $slide, descriptions => $descriptions });

    } else {
        $c->message({ type => "error", message => "slide_not_found" });
        $c->response->redirect($c->uri_for_action("/admin/slideshow/index"));
    }
    return 1;
}

sub edit_slide_POST {
    my ($self, $c, $id) = @_;
    my %data = %{$c->req->body_params};
    my $slide = $c->model("DB::Slide")->find($id);
    $slide->update(
        {
            url => $data{url},
            thumb_url => $data{thumb_url},
        }
    );

    foreach my $key (grep(/^text_/, keys(%data))) {
        if ($key =~ /^text_(\w{2,3})/ && $data{$key}) {
            $slide->update_or_create_related('slide_descriptions', { lang => $1, description => $data{$key} });
        }
    }

    $c->message({ type => "success", message => "slide_updated" });
    $c->response->redirect($c->uri_for_action("/admin/slideshow/show", { portal => $slide->get_column('portal'), show => $slide->get_column('slideshow') }));
}

#
# delete_slide: delete a slide from a slideshow
#

sub delete_slide :Path('delete_slide') :Args(1) {
    my ($self, $c, $id) = @_;
    my $slide = $c->model("DB::Slide")->find($id);
    if ($slide) {
        my $portal = $slide->get_column("portal");
        my $show = $slide->get_column("slideshow");
        $slide->delete;
        $c->message({ type => "success", message => "slide_deleted" });
        $c->response->redirect($c->uri_for_action("/admin/slideshow/show", { portal => $portal, show => $show }));
    } else {
        $c->message({ type => "error", message => "slide_not_found" });
        $c->response->redirect($c->uri_for_action("/admin/slideshow/index"));
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
