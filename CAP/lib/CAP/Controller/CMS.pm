package CAP::Controller::CMS;

use strictures 2;
use base qw/Catalyst::Controller/;

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

sub edit :Path('edit') :Args(1) {
	my ($self, $c, $id) = @_;

	my $doc = $c->model('CMS')->edit($id);

	$c->detach('/error', [404, $doc]) unless ref $doc;

	$c->stash(
		doc => $doc,
		template => 'cms/editor.tt'
	);
}

1;