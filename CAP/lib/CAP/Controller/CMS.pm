package CAP::Controller::CMS;

use strictures 2;
use base qw/Catalyst::Controller/;
use Text::MultiMarkdown qw/markdown/;
use HTML::Entities qw/encode_entities/;

sub auto :Private {
    my($self, $c) = @_;

    # Only allow administrators to access any of these functions. Everyone
    # else gets a login screen.
    unless ($c->has_role('administrator')) {
        #$c->session->{login_redirect} = $c->req->uri;
        $c->res->redirect($c->uri_for_action('user/login'));
        $c->detach();
    }

    return 1;
}

sub index :Path('') {
    my ($self, $c) = @_;

    $c->stash(
        portals => [$c->model('DB::Portal')->list]
    );
}

sub portal :Local :Args(1) {
    my ($self, $c, $portal_id) = @_;

    my $portal = $c->model("DB::Portal")->find($portal_id);

    $c->detach('/error', [404], "no portal: $portal_id") unless $portal;

    $c->stash(
        portal_row => $portal,
        nodes => $c->model('CMS')->nodes({
            portal => $portal_id,
            lang => $c->stash->{lang},
        }),
        redirects => $c->model('CMS')->redirects({
            portal => $portal_id,
            lang => $c->stash->{lang}
        }),
        blocks => $c->model('CMS')->blocks({
            portal => $portal_id
        })
    );
}

sub new_block :Local :Args(1) {
    my ($self, $c, $portal_id) = @_;

    my $portal = $c->model("DB::Portal")->find($portal_id);

    $c->detach('/error', [404], "no portal: $portal_id") unless $portal;

    $c->stash(portal_row => $portal);
}

sub submit_new_block :Local {
    my ($self, $c) = @_;

    my $block = $c->model('CMS')->new_block($c->req->body_parameters);
    $c->detach('/error', [500, $block]) unless ref $block;

    $c->response->redirect($c->uri_for_action('cms/edit', [$block->{id}]));
}

sub create :Local {
    my ($self, $c) = @_;
    my $doc = $c->model('CMS')->empty_document();
    $c->detach('editor', [$doc]);
}

sub edit :Local :Args(1) {
	my ($self, $c, $id) = @_;

	my $doc = $c->model('CMS')->edit($id);
    $c->detach('editor', [$doc]);
}

sub editor :Private {
    my ($self, $c, $doc) = @_;

    $c->detach('/error', [404, $doc]) unless ref $doc;

    $c->stash(
        doc => $doc,
        portals => [$c->model('DB::Portal')->list],
        template => 'cms/editor.tt'
    );
}

sub submit :Local {
    my ($self, $c) = @_;
    my $data = $c->req->body_parameters;

    # invalidate the block cache if you are submitting a block
    if ($data->{is_block}) {
        $c->model('CouchCache')->revalidate('cms_blocks');
    }

    # do the same with updates
    if ($data->{is_update}) {
        $c->model('CouchCache')->revalidate('cms_updates');
    }

    my ($l, $ext);
    foreach my $md_file (grep /.+\.md/, keys %$data) {
        ($l) = ($md_file =~ /(.+)\.md/);

        # Encode entities for weird characters, but leave newlines, brackets, etc. alone
        $data->{$md_file} = encode_entities($data->{$md_file}, '^\r\n\x20-\x7e');
        $data->{"$l.html"} = markdown($data->{$md_file});
    }

    foreach my $file (grep /.+\..+/, keys %$data) {
        ($l, $ext) = ($file =~ /(.+)\.(.+)/);
        my $args = {
            id => $data->{id},
            rev => $data->{rev},
            content_type => $ext eq 'html' ? 'text/html' : 'text/plain',
            filename => $file,
            data => $data->{$file}
        };

        my $response = $c->model('CMS')->submit_attachment($args);

        $c->detach('/error', [500, $response]) unless ref $response;

        $data->{rev} = $response->{rev};
    }

    if (defined $data->{update_view}) {
        $c->response->redirect($data->{update_view});
    } else {
        $c->response->redirect($c->uri_for_action('cms/edit', [$data->{id}]));
    }
}

1;