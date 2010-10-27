package CAP::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Config::General;
use CAP::Config qw(as_array);
use CAP::Solr;

use utf8;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';


sub begin :Private
{
    my($self, $c) = @_;

    # Determine which portal configuration to use
    my $portal = $c->forward('config_portal');

    # TODO: this should be deprecated once none of the templates reference
    # root.
    $c->stash->{root} = "/";

    # Set the user interface language
    my $lang = $c->forward('set_usrlang');
    $c->stash->{lang} = $lang;
    $c->languages([$lang]);
    $c->res->cookies->{usrlang} = { value => $lang, expires => time() + 7776000 }; # Cookie expires in 90 days
    $c->stash->{label} = $c->model('DB::Labels')->get_labels($c->stash->{lang});

    $c->stash('response' => {
        request => "" . $c->req->{uri}, # need to stringify this
        status => 200,
        version => '0.1',
    });

    # Clean up any expired sessions
    my $expired = $c->model('DB::Sessions')->remove_expired();
    warn("[debug] Cleaned up $expired expired sessions") if ($expired);
    return 1;
}

sub post : Chained('base') PathPart('post') Args(0)
{
    my($self, $c) = @_;
    my @parts = ();
    my $i = 0;
    while ($c->request->params->{$i}) {
        push(@parts, $c->request->params->{$i});
        $i += 1;
    }
    $c->response->redirect(join('/', @parts), 303);
}

sub static : Chained('base') PathPart('static') Args()
{
    my($self, $c, @path) = @_;
    my $file = join('/', $c->config->{root}, $c->stash->{portal}, 'static', @path);
    my $default_file = join('/', $c->config->{root}, 'Default', 'static', @path);

    if (-f $file) {
        $c->serve_static_file($file);
    }
    elsif (-f $default_file) {
        $c->serve_static_file($default_file);
    }
    else {
        $c->detach('error', [404, $file]);
    }

    return 1;
}

sub test_error : Chained('base') PathPart('error') Args(1)
{
    my($self, $c, $error) = @_;
    if (! $c->config->{debug}) {
        $c->detach('error', [404]);
    }
    $c->detach('error', [$error, 'ERRORTEST']);
}

sub access_denied : Private
{
    my($self, $c) = @_;
    warn("[debug] Access denied (insufficient privileges)") if ($c->config->{debug});
    $c->stash->{page} = $c->{stash}->{uri};
    $c->detach('error', [403, "NOACCESS"]);
}

sub set_usrlang : Private
{
    my($self, $c) = @_;
    my $lang;

    # Decide what user interface language to used based on the following
    # criteria, in descending order of preference:

    # Check for an explicit usrlang query parameter.
    if ($c->req->params->{usrlang}) {
        $lang = $c->req->params->{usrlang};
        delete($c->req->params->{usrlang});
        return $lang if ($c->stash->{config}->{languages}->{$lang});
    }

    # If a cookie is present and contains a supported language, use it.
    if ($c->req->cookie('usrlang')) {
        $lang = $c->req->cookie('usrlang')->value;
        if ($c->stash->{config}->{languages}->{$lang}) {
            return $lang;
        }
    }

    # Override with the supported language with the highest q value from
    # the Accept-Language header.
    my $lang_q = -1;
    foreach my $accept_lang (split(/\s*,\s*/, $c->req->header('Accept-Language'))) {
        my ($val, $q) = split(';q=', $accept_lang);
        $q = 0 unless ($q);
        $q = 1 if ($q && $q eq '');
        if ($val) {
            $val = lc(substr($val, 0, 2));
            if ($c->stash->{config}->{languages}->{$val} && int($q) > $lang_q) {
                $lang = $val;
                $lang_q = int($q);
            }
        }
    }
    return $lang if ($lang_q != -1);

    # Use the default language
    return $c->stash->{config}->{default_lang};
}

sub base : Chained('/') PathPart('') CaptureArgs(0)
{
    my($self, $c) = @_;

    # Use the default output format unless the specified format is supplied
    my $format = 'Default';
    if ($c->req->params->{fmt}) {
        if ($c->stash->{config}->{format}->{$c->req->params->{fmt}}) {
            $format = $c->req->params->{fmt};
        }
    }
    $c->stash->{format} = $format;
    $c->response->content_type($c->stash->{config}->{format}->{$format});



    # If a username and password are supplied as query parameters, try to
    # authenticate the user transparently. If this fails, redirect to the
    # login form. This does not apply when the login action itself is the
    # called.
    if ($c->action ne $c->controller('Auth')->action_for('login')) {
        if ($c->request->params->{username} && $c->request->params->{password}) {
            $c->logout if ($c->user_exists);
            if (! $c->forward('auth/authenticate')) {
                $c->forward('access_denied');
            }
        }
    }

    #### ACCESS CONTROL
    #
    # Based on whether or not the action is enabled, public, and/or
    # supports access for one or more roles the user has, do one of four
    # things: generate a 404/Not Found, forward to a login page, forward
    # to an access denied page, or continue on to the requested action.

    # Determine whether the requested action is enabled for this portal.
    # If it is not, we forward the user to a 404/Not Found page.
    
    my $requested_action = $c->req->{action};
    my $default_action = $c->config->{action}->{$requested_action};
    my $portal_action = $c->stash->{config}->{action}->{$requested_action};
    my $action_enabled = 0;

    if ($default_action) {
        $action_enabled = 0 if (defined($default_action->{enabled})); # not required, but included for completeness
        $action_enabled = 1 if ($default_action->{enabled});
    }

    if ($portal_action) {
        $action_enabled = 0 if (defined($portal_action->{enabled}));
        $action_enabled = 1 if ($portal_action->{enabled});
    }

    if (! $action_enabled) {
        #warn("[info] request for disabled action \"$requested_action\" for portal \"$portal\"\n");
        warn("[info] request for disabled action \"$requested_action\" for portal \"" . $c->stash->{portal} . "\"\n");
        $c->detach('error', [404]);
    }


    my $access_allowed = 0;
    my %authorized_roles = ();

    if ($default_action) {
        $access_allowed = 0 if (defined($default_action->{public})); # not required, but included for completeness
        $access_allowed = 1 if ($default_action->{public});

        foreach my $role (as_array($default_action->{allow})) { $authorized_roles{$role} = 1  }
        foreach my $role (as_array($default_action->{deny})) { delete($authorized_roles{$role}) }
    }
    
    if ($portal_action) {
        $access_allowed = 0 if (defined($portal_action->{public}));
        $access_allowed = 1 if ($portal_action->{public});

        foreach my $role (as_array($portal_action->{allow})) { $authorized_roles{$role} = 1  }
        foreach my $role (as_array($portal_action->{deny})) { delete($authorized_roles{$role}) }
    }

    $access_allowed = 1 if ($c->check_any_user_role(keys(%authorized_roles)));


    # If access is not allowed, forward to an access denied page if the
    # user is logged in, or to the login form otherwise.
    if (! $access_allowed) {
        if ($c->user_exists) {
            $c->detach('access_denied');
        }
        else {
            $c->res->redirect($c->uri_for($c->stash->{root}, 'login', { page => $c->stash->{uri}, redirected => 1 }));
        }
    }


    return 1;
}

# Read the portal configuration file and apply its characteristics.
sub config_portal : Private
{
    my($self, $c) = @_;
    my $portal;

    if ($c->config->{portal}->{$c->req->base}) {
        $portal = $c->config->{portal}->{$c->req->base};
    }
    else {
        $portal = $c->config->{default_portal};
    }

    # Load the portal configuration from the config file. If no portal
    # config file exists, return a not found error.
    my $config_file = join('/', $c->config->{root}, $portal, 'portal.conf');
    if (-f $config_file) {
        warn("[debug] Reading config file \"$config_file\"\n") if ($c->config->{debug});
        my $config;
        eval { $config = Config::General->new( -ConfigFile => $config_file, -AutoTrue => 1, -UTF8 => 1) };
        $c->detach('/error', [500, "Failed to parse $config_file"]) if ($@);
        # TODO: pconf is deprecated. Use config instead. Also: merge some
        # default options into the config if they don't already exist.
        $c->stash->{pconf} = { $config->getall };
        $c->stash->{config} = { $config->getall };
    }
    else {
        $c->detach('error', [404, "BADPORTAL"]);
    }

    # If the portal is disabled, return a file not found response.
    $c->detach('error', [404, "PORTALDISABLED"]) unless ($c->stash->{config}->{enabled});

    # Searches should be restricted to a subset of the Solr index.
    if ($c->stash->{config}->{subset}) {
        $c->config->{solr}->{subset} = {};
        while (my($field, $value) = each(%{$c->stash->{config}->{subset}})) {
            $c->config->{solr}->{subset}->{$field} = $value;
        }
    }

    $c->stash->{portal} = $portal;
    return $portal;
}


=over 4

=item default

Called if no other actions match the request. The default action is to
forward to I<error> with a 404 (Not Found) code.

=back
=cut
sub default :Path {
    my($self, $c) = @_;
    #my($self, $c, $portal, $iface, @args) = @_;
    #$c->forward->('config_portal', [$portal]) if ($portal);
    #$c->forward('set_root', [$portal]);
    $c->detach('error', [404]);
}

=over 4

=item default_portal

When called without arguments, forward to the default portal.

=back
=cut
#sub default_portal :Path :Args(0)
#{
#    my($self, $c) = @_;
#    $c->res->redirect($c->uri_for($c->config->{default_portal}));
#}


=over 4

=item default_iface

If a valid portal is specified but nothing else, redirect to the default interface.

=back
=cut
#sub default_lang :Path :Args(1)
#{
#    my($self, $c, $portal) = @_;
#    $c->forward('config_portal', [$portal]);
#    $c->res->redirect($c->uri_for($c->stash->{portal}, $c->stash->{config}->{default_lang}));
#}




=over 4

=item default2
    
Called when a valid portal and interface are successfully configured (see
I<base>) but the action itself is invalid. E.g.:
I</foo/en/slay/grue>. Forwards to I<error> with a 404.

=back
=cut
#sub default2 : Chained('base') PathPart('') Args()
#{
#    my($self, $c) = @_;
#    $c->detach('error', [404]);
#}


=over 4

=item end

This is the end action for all methods in all controllers. It sets a
default template if one was not explicitly set already, and updates the
template path based on the interface.

=back
=cut
sub end : ActionClass('RenderView')
{
    my($self, $c) = @_;

    # Don't cache anything (TODO: this is a bit harsh, but it does control
    # the login/logout refresh problem.)
    if ($c->action eq 'static') {
        $c->res->header('Cache-Control' => 'max-age=3600');
    }
    elsif ($c->action eq 'file/file') {
        $c->res->header('Cache-Control' => 'max-age=3600');
    }
    else {
        $c->res->header('Cache-Control' => 'no-cache');
    }

    # If no template was specified during processing, use the default
    # template to render the view.
    if (! $c->stash->{template}) {
        $c->stash->{template} = "default.tt";
    }


    # FIXME: when calling the generic top-level directory, the wrong value
    # of {portal} seems to get passed to the template, but creating
    # {portal_dir} here seems to fix that. Weird.
    # TODO: do we still even need this?
    #$c->stash->{portal_dir} = $c->stash->{portal};


    # Look for templates in the $root/templates/$portal/templates/$format
    # directory. Use "Main" if the interface is a standard language
    # interface. If the template is not found here, the default for the
    # view is used.
    my $subdir = "Main";
    #if ($c->stash->{format} && $c->stash->{format} !~ /^[a-z][a-z]$/) {
    #    $subdir = $c->stash->{format};
    #}

    # If a portal is configured, add the default template path for that
    # portal. If an interface is also configured, add the template path
    # for that interface. (The global default path is the final fallback.)
    if ($c->stash->{portal}) {
        if ($c->stash->{format}) {
            $c->stash->{additional_template_paths} = [ 
                join('/', $c->config->{root}, $c->stash->{portal}, "templates", $c->stash->{format}), 
                join('/', $c->config->{root}, "Default", "templates", $c->stash->{format}), 
                join('/', $c->config->{root}, $c->stash->{portal}, "templates", 'Default')
            ];
        }
        else {
            $c->stash->{additional_template_paths} = [  join('/', $c->config->{root}, $c->stash->{portal}, "templates", 'Default') ];
        }
        warn("[debug] Template include path is \"@{$c->stash->{additional_template_paths}}\"\n") if ($c->config->{debug});
    }

    return 1;
}


=over 4

=item error ( I<$error> [, I<$error_message>] )

Detach to this method when an error occurs that should stop normal
processing. Put the HTTP status code to be returned in I<$error> and,
optionally, a descriptive message in I<$error_message>.

=back
=cut
sub error : Private
{
    my($self, $c, $error, $error_message) = @_;
    $error_message = "" unless ($error_message);
    $c->stash->{response}->{status} = $error;
    $c->stash->{error} = $error_message;
    $c->stash->{status} = $error;
    $c->stash->{template} = "error.tt";
    return 1;
}


#
# These are the basic actions we have to handle. Most of them will simply
# dispatch to a method in another controller, but putting them here means
# that we can simplify uri_for_action strings.
#

sub index :Path :Args(0)
{
    my($self, $c) = @_;
    $c->stash->{template} = "index.tt";
}

sub search : Chained('/base') PathPart('search') Args() {
    my($self, $c, $start) = @_;
    return $c->forward('search/index', [$start]);
}

sub show : Chained('/base') PathPart('show') Args() {
    my($self, $c, @args) = @_;
    return $c->forward('show/index', [@args]);
}

1;

