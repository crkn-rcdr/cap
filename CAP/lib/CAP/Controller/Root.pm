package CAP::Controller::Root;
use Moose;
use namespace::autoclean;

use strict;
use warnings;
use parent qw/Catalyst::Controller::ActionRole/;
use Config::General;
use utf8;

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
__PACKAGE__->config->{namespace} = '';

BEGIN {extends 'Catalyst::Controller::ActionRole'; }


sub auto :Private
{
    my($self, $c) = @_;

    # Create a session if we don't already have one.
    $c->initialize_session;

    # Initialize util class
    $c->set_util;
    
    # Determine which portal to use and configure it.
    $c->set_portal;

    # Set the institution associated with this request.
    $c->set_institution;

    # Set various per-request configuration variables.
    $c->stash($c->model('Configurator')->configAll($c->portal, $c->req, $c->config));

    # Set the content type and template paths based on the view and portal.
    $c->response->content_type($c->stash->{content_type});
    $c->stash->{additional_template_paths} = [
        join('/', $c->config->{root}, 'templates', $c->stash->{current_view}, $c->portal->id),
        join('/', $c->config->{root}, 'templates', $c->stash->{current_view}, 'Common')
    ];

    # Configure the interface language. Stash the language in a separate
    # cookie with a long expiration time so that the user's language
    # preference is stored long-term on their browser.
    $c->languages([$c->stash->{lang}]);
    $c->res->cookies->{$c->config->{cookies}->{lang}} = {
        domain => $c->stash->{cookie_domain},
        value => $c->stash->{lang},
        expires => time() + 7776000,
        httponly => 1
    }; 
    $c->stash(
        collections    => $c->model('Collections')->all->{$c->portal->id} || {},
        label          => $c->model('DB::Labels')->get_labels($c->stash->{lang}),
        content_blocks => $c->model('CMS')->cached_blocks({
            portal => $c->portal->id,
            lang   => $c->stash->{lang},
            action => $c->action->private_path
        })
    );

    # If this is an anonymous request, check for a persistence token and,
    # if valid, automatically login the user.
    if (! $c->user_exists) {
        if ($c->request->cookie($c->config->{cookies}->{persist})) {
            my $id = $c->model('DB::User')->validate_token($c->request->cookie($c->config->{cookies}->{persist})->value);
            if ($id) {
                $c->set_authenticated($c->find_user({id => $id}));
                $c->persist_user();
                $c->user->update({ last_login => DateTime->now() });
                $c->user->log('RESTORE_SESSION', sprintf("from %s", $c->req->address));
            }
        }
    }

    # Create or update the session and increment the session counter
    $c->update_session();

    # throw JSON requests to error page
    if (exists $c->request->query_params->{fmt} && lc($c->request->query_params->{fmt}) eq 'json') {
        $c->detach('/error', [404, 'API Unavailable -- API non disponible']);
    }

    # Route this request to/from the secure host if necessary
    $c->model('Secure')->routeRequest($c);

    # Get the return portal and return URI, if there is one.
    if ($c->session->{origin}) {
        $c->stash( 'origin' => {
            portal => $c->model('DB::Portal')->find($c->session->{origin}->{portal}),
            uri => $c->session->{origin}->{uri}
        });
    }

    # Configure the user's permissions
    $c->set_auth;

    # If we got to here, it means we will attempt to actually do
    # something, so increment the request counter and log the request
    ++$c->session->{count};
    $c->forward('CAP::Controller::RequestLogger');

    return 1;
}


sub access_denied :Private {
    my($self, $c) = @_;
    warn("[debug] Access denied (insufficient privileges)") if ($c->debug);
    $c->stash->{page} = $c->{stash}->{uri};
    $c->detach('error', [403, "NOACCESS"]);
}

=head2 favicon()

Handle requests for /favicon.ico by redirecting them to /static/favicon.ico

=cut
sub favicon :Path('favicon.ico') {
    my($self, $c) = @_;
    $c->res->redirect($c->uri_for_action('/static', 'favicon.ico'));
    $c->detach();
}

# If we don't match anything, we're trying to access a CMS node (or 404)
sub default :Path {
    my($self, $c, @path) = @_;

    my $path = join '/', @path;
    my $lookup = $c->model('CMS')->view({
        portal => $c->portal->id,
        lang => $c->stash->{lang},
        path => $path,
        base_url => $c->uri_for('/')
    });

    $c->detach('error', [404, "Failed lookup for $path"]) unless $lookup;
    $c->detach('error', [404, $lookup]) unless ref $lookup;

    if ((ref $lookup) =~ /URI/) {
        $c->response->redirect($lookup);
        $c->detach();
    }

    use Data::Dumper;
    $c->stash(
        node => $lookup,
        template => "node.tt"
    );
}

sub end : ActionClass('RenderView')
{
    my($self, $c) = @_;

    # Don't cache anything except for static resources
    if ($c->action eq 'static') {
        $c->res->header('Cache-Control' => 'max-age=3600');
    }
    else {
        $c->res->header('Cache-Control' => 'no-cache');
    }

    return 1;
}


sub error :Private
{
    my($self, $c, $error, $error_message) = @_;
    $error_message = "" unless ($error_message);
    $c->response->status($error);
    $c->stash->{error} = $error_message;
    $c->stash->{status} = $error;
    $c->stash->{template} = "error.tt";
    return 1;
}


# These are the basic actions we have to handle. 

sub index :Path('') Args(0)
{
    my($self, $c) = @_;

    # The secure portal has no index page: forward to the user's profile.
    if ($c->req->uri->host eq $c->config->{secure}->{host}) {
        warn "##### Request for / on Secure goes to /user/profile" if ($c->debug);
        $c->response->redirect($c->uri_for_action("/user/profile"));
        $c->detach();
    }

    $c->stash->{slides} = $c->model("DB::Slide")->get_slides($c->portal->id, "frontpage");
    $c->stash->{template} = "index.tt";
    $c->stash->{portals} = [$c->model("DB::Portal")->list];
    $c->stash->{updates} = $c->model("CMS")->cached_updates({
        portal => $c->portal->id,
        lang => $c->stash->{lang},
        limit => 3
    });
}

# list of CMS nodes marked isUpdate
sub updates :Local {
    my ($self, $c) = @_;
    $c->stash->{updates} = $c->model("CMS")->updates({
        portal => $c->portal->id,
        lang => $c->stash->{lang}
    });
}

# check for insitutional subscription
sub proxy :Local {
    my ($self, $c) = @_;
    $c->detach('error', [404, "Not supported for non-subscription portals"])
        unless ($c->portal->supports_institutions && $c->portal->supports_subscriptions);
}

sub robots :Path('robots.txt') {
    my ($self, $c) = @_;
    $c->res->header('Content-Type', 'text/plain');
    my $sitemap_uri = $c->uri_for('/sitemap/sitemap.xml');
    my $body = <<"EOF";
User-agent: *
Disallow: /search
Disallow: /file
Sitemap: $sitemap_uri
EOF
    $c->res->body($body);
    return 1;
}

sub test_error :Path('error') Args(1)
{
    my($self, $c, $error) = @_;
    $c->detach('error', [$error, 'Test error']);
}

# Generate a basic system error message. This action is intended to catch
# serious system misconfigurations that cannot or should not be handled
# using the templating system.
sub config_error :Private
{
    my($self, $c, $message) = @_;
    $c->stash->{config_error} = 1;
    $c->res->status(500);
    $c->res->body("<html><head><title>Configuration Error</title><body><h1>Configuration Error</h1><p>$message</p></body></html>");
    return 0;
}

# Serve a file in the static directory under root. In production, requests
# for /static should be intercepted and handled by the web server.
sub static : Path('static') :Args()
{
    my($self, $c, @path) = @_;
    my $file = join('/', $c->config->{root}, 'static', @path);

    if (-f $file) {
        $c->serve_static_file($file);
    }
    else {
        $c->detach('error', [404, $file]);
    }
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;

