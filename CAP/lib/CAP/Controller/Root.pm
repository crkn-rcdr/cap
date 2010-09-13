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

sub index : Chained('base') PathPart('') Args(0)
{
    my($self, $c) = @_;
    $c->stash->{template} = "index.tt";
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

sub auto :Private
{
    my($self, $c) = @_;

    $c->stash('response' => {
        request => "" . $c->req->{uri}, # need to stringify this
        status => 200,
        version => '1.0',
    });

    # Clean up any expired sessions
    my $expired = $c->model('DB::Sessions')->remove_expired();
    warn("[debug] Cleaned up $expired expired sessions") if ($expired);
    return 1;
}

sub base : Chained('/') PathPart('') CaptureArgs(2)
{
    my($self, $c, $portal, $lang) = @_;
    $portal = lc($portal);
    $lang = lc($lang);

    # Configure the requested portal (or return an error)
    $c->forward('config_portal', [$portal]);

    # Set the user interface language. Use the default if the supplied
    # language is not supported. Get the set of code->label mappings for
    # the selected language.
    $lang = $c->stash->{config}->{default_lang} unless ($lang && $c->stash->{config}->{languages}->{$lang});
    $c->languages( $lang ? [$lang] : []);
    $c->stash->{lang}  = $lang;
    $c->stash->{iface} = $lang; # Deprecated
    $c->stash->{label} = $c->model('DB::Labels')->get_labels($c->stash->{lang});

    $c->forward('set_root', [$portal, $lang]);

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
        warn("[info] request for disabled action \"$requested_action\" for portal \"$portal\"\n");
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

    ################## TODO: Everything below here can be removed at some point.






    # Determine whether the selected application allows the requested
    # action and set up role-based ACLs.
    # It seems we have to roll our own ACL solution, since rules created
    # using the ACL plugin seem to persist between requests, leading to an
    # ever-increasing denial of privilege (FIXME?)
    my %action_ok = ();
    my %role_required = ();

    # First process all of the rules specific to the portal.
    if ($c->stash->{config}->{actions}) {
        while (my($action, $auth) = each(%{$c->stash->{config}->{actions}})) {
            if (! $auth || $auth eq '!') {
                $action_ok{$action} = 0;
            }
            elsif ($auth eq '*') {
                $action_ok{$action} = 1;
            }
            else {
                $action_ok{$action} = 1;
                $role_required{$action} = $auth;
            }
        }
    }

    # Process those global rules that don't have a portal-specific rule.
    if ($c->config->{actions}) {
        while (my($action, $auth) = each(%{$c->config->{actions}})) {
            next if (
                $c->stash->{config}->{action} &&
                defined($c->stash->{config}->{action}->{$action})
            );
            if (! $auth || $auth eq '*') {
                $action_ok{$action} = 1;
            }
            elsif ($auth eq '!') {
                $action_ok{$action} = 0;
            }
            else {
                $action_ok{$action} = 1;
                $role_required{$action} = $auth;
            }
        }
    }

    # Check whether the action is supported by this portal.
    if (! $action_ok{$c->request->{action}}) {
        $c->detach('error', [404]);
    }

    # If a specific role is required, make sure the user has it.
    # (FIXME?)
    if ($role_required{$c->request->{action}}) {
        my @roles = split(/\s+/, $role_required{$c->request->{action}});

        # Verify that the defined roles all exist in the database.
        # Otherwise, an error may be generated.
        #if (! $c->model('DB::Role')->role_exists(@roles)) {
        #    $c->detach('/error', [500, "Role list \"@roles\" contains undefined role(s)\n"]);
        #}
        
        my $has_role = 0;
        if ($c->user_exists) {
            #$has_role = $c->check_any_user_role(@roles);
            $c->detach('access_denied') unless ($c->check_any_user_role(@roles));
        }
        else {
            warn("[debug] unauthenticated request for page requiring one of \"@roles\"\n") if ($c->config->{debug});
            warn("[debug] redirect to login page with forwarding URI \"" . $c->stash->{uri} . "\"\n") if ($c->config->{debug});
            $c->res->redirect($c->uri_for($c->stash->{root}, 'login', { page => $c->stash->{uri}, redirected => 1 }));
        }
    }

}

# Read the portal configuration file and apply its characteristics.
sub config_portal : Private
{
    my($self, $c, $portal) = @_;

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
    return 1;
}


=over 4

=item default

Called if no other actions match the request. The default action is to
forward to I<error> with a 404 (Not Found) code.

=back
=cut
sub default :Path :Args() {
    my($self, $c, $portal, $iface, @args) = @_;
    $c->forward->('config_portal', [$portal]) if ($portal);
    $c->forward('set_root', [$portal, undef]);
    $c->detach('error', [404]);
}

=over 4

=item default_portal

When called without arguments, forward to the default portal.

=back
=cut
sub default_portal :Path :Args(0)
{
    my($self, $c) = @_;
    $c->res->redirect($c->uri_for($c->config->{default_portal}));
}


=over 4

=item default_iface

If a valid portal is specified but nothing else, redirect to the default interface.

=back
=cut
sub default_lang :Path :Args(1)
{
    my($self, $c, $portal) = @_;
    $c->forward('config_portal', [$portal]);
    $c->res->redirect($c->uri_for($c->stash->{portal}, $c->stash->{config}->{default_lang}));
}




=over 4

=item default2
    
Called when a valid portal and interface are successfully configured (see
I<base>) but the action itself is invalid. E.g.:
I</foo/en/slay/grue>. Forwards to I<error> with a 404.

=back
=cut
sub default2 : Chained('base') PathPart('') Args()
{
    my($self, $c) = @_;
    $c->detach('error', [404]);
}


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


=over 4

=item set_root

Sets the value of I<< $c->stash->{root} >> and I<< $c->stash->{uri} >> based on
the particulars of the request. All URIs in the template should use the
root as the first part of any internal URIs they construct, while uri is a
self-referential URI that points to the page itself, for use with some of
the authentication routines and other functions that may intercept and
temporarily redirect a request. (In order to allow the request to
eventually be forwarded to the original URI.)

=back
=cut
sub set_root : Private
{
    my($self, $c, $portal, $lang) = @_;
    my $root = $portal;
    my $uri = $c->request->uri;
    $root .= "/$lang" if ($lang);

    if ($c->config->{prefix}->{$c->request->{base}}) {
        my $prefix = $c->config->{prefix}->{$c->request->{base}};
        $root = substr($root, length($prefix));
        $uri =~ s#\Q/$prefix\E##;
    }
    $root =~ s/\/$//;
    $c->stash->{root} = "/$root";
    $c->stash->{uri} = $uri; # $uri is a self-referential URI.
    $c->stash->{uri_tail} = substr($c->req->path, length($c->stash->{root}));
}

=head1 LICENSE AND COPYRIGHT

See I<CAP/license.txt>.

=head1 AUTHOR

William Wueppelmann L<<william.wueppelmann@canadiana.ca>>

=head1 SEE ALSO

cap.conf, L<CAP>

=cut

1;
