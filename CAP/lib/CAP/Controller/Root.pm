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

    # Make sure the CAP database version agrees with the config file.
    $c->model('DB::Info')->assert_version($c->config->{db_version});

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
        label        => $c->model('DB::Labels')->get_labels($c->stash->{lang}),
        contributors => $c->model('DB::Institution')->get_contributors($c->stash->{lang}, $c->portal),
        languages    => $c->model('DB::Language')->get_labels($c->stash->{lang}),
        media        => $c->model('DB::MediaType')->get_labels($c->stash->{lang}),
    );

    # If this is an anonymous request, check for a persistence token and,
    # if valid, automatically login the user.
    if (! $c->user_exists) {
        if ($c->request->cookie($c->config->{cookies}->{persist})) {
            my $id = $c->model('DB::User')->validate_token($c->request->cookie($c->config->{cookies}->{persist})->value);
            if ($id) {
                $c->set_authenticated($c->find_user({id => $id}));
                $c->persist_user();
                $c->user->log('RESTORE_SESSION', sprintf("from %s", $c->req->address));
            }
        }
    }

    # Update the user's last access time.
    if ($c->user_exists) {
        eval { $c->user->update({lastseen => time()}) };
        $c->detach('/error', 500) if ($@);
    }

    # Create or update the session and increment the session counter
    $c->update_session();

    # Route this request to/from the secure host if necessary
    $c->model('Secure')->routeRequest($c);

    # If we got to here, it means we will attempt to actually do
    # something, so increment the request counter and log the request
    ++$c->session->{count};
    $c->model('DB::RequestLog')->log($c);

    return 1;
}


sub access_denied :Private {
    my($self, $c) = @_;
    warn("[debug] Access denied (insufficient privileges)") if ($c->debug);
    $c->stash->{page} = $c->{stash}->{uri};
    $c->detach('error', [403, "NOACCESS"]);
}

# The default action is to redirect back to the main page.
sub default :Path {
    my($self, $c) = @_;
    $c->res->redirect($c->uri_for_action('index'));
    $c->detach();
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

    # Messsages bugging you to subscribe already
    if ($c->portal->id eq 'eco' && !$c->session->{eco}->{subscribing_institution}) {
        if ($c->user_exists) {
            my $sub_level = $c->user->subscriber_level($c->portal);
            my $sub_active = $c->user->subscription_active($c->portal);

            # Trial subscribers get a message regarding their current or
            # expired trial.
            if ($sub_level == 1) {
                if ($sub_active) {
                    $c->message({ type => "success", message => "active_trial_prod" });
                }
                else {
                    $c->message({ type => "success", message => "expired_trial_prod" });
                }
            }

            # Expired full subscribers get a message informing them their
            # subscription is over
            elsif ($sub_level == 2 && $sub_active == 0) {
                $c->message({ type => "success", message => "expired_sub" });
            }

        } else {
            $c->message({ type => "success", message => "anonymous_prod" });
        }
    }

    # TODO: figure out a better solution than hardcoding this
    if ($c->portal->id eq 'parl') {
        my @tree = $c->model('DB::Terms')->term_tree($c->portal);
        $c->stash(
            browse => \@tree,
            id_prefix => "oop.",
        );
    }

    $c->stash->{slides} = $c->model("DB::Slide")->get_slides($c->portal->id, "frontpage");
    $c->stash->{template} = "index.tt";
}

sub support :Path('support') :Args() {
    my ($self, $c, $page) = @_;
    unless ($c->portal->has_page($page)) {
        $c->detach("error", [404]);
    }
    $c->stash->{support_resource} = $page;
    $c->stash->{template} = 'support.tt';
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

