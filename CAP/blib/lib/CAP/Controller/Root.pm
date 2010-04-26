package CAP::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Config::General;
use CAP::Solr;

use utf8;

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

CAP::Controller::Root - main controller for the Canadiana Access Portal

=head1 DESCRIPTION

This controller handles the main dispatch logic as well as error handling
and some auxiliary functions. Other functions are delegated to secondary
controllers, which include:

=over 4

=item L<CAP::Controller::Auth>

    Authorization, login, and logout functions.

=item L<CAP::Controller::Content>

    Content ingestion, indexing, and management of metadata and digital resources (administrative).

=item L<CAP::Controller::File>

    Methods for responding to digital content (image files, etc.) requests
    by finding, generating, and delivering appropriate files.

=item L<CAP::Controller::Search>

    Portal search functions.

=item L<CAP::Controller::Show>

    Methods for delivering/displaying content and/or records to the user.

=item L<CAP::Controller::User>

    User and role management features (administrative).

=back

=head1 METHODS

=cut

=head2 Actions

=cut


=over 4

=item page ( I<@path> )

Returns an HTML page, which is processed using the standard wrapper and
I<page.tt> template. I<@path> describes the path to the file, which is in
the I<pages> subdirectory of the portal root, and which is further
subdivided according to the interface. The '.html' suffix is added to the
file automatically. E.g., a request for I</foo/en/page/bar/baz> would
retrieve the file I<$root/foo/pages/en/bar/baz.html>.

This method is intended to be used to present larger textual documents
that still should be wrapped in the usual template. Note that if you have
multiple language interfaces, you need a separate document for each one.

=back
=cut
sub page : Chained('base') PathPart('page') Args()
{
    my($self, $c, @path) = @_;

    my $file = join('/', $c->config->{root}, $c->stash->{portal}, "pages", $c->stash->{iface}, @path);

    # TODO: allow other extensions.
    $file = "$file.html";

    if (! -f $file) {
        $c->detach('/error', [404, $file]);
    }

    if (! open(FILE, "<$file")) {
        $c->detach('/error', [500]);
    }

    $c->stash(
        page_content => join('', <FILE>),
        template => 'page.tt',
    );
    close(FILE);
}


=over 4

=item index

Displays the home page for a valid portal with a valid interface (e.g. I</foo/en>).

=back
=cut
sub index : Chained('base') PathPart('') Args(0)
{
    my($self, $c) = @_;
    $c->stash->{template} = "index.tt";
}


=over 4

=item master_index

Display the master portal home page. This method is called in response to an empty request (I</>).

=back
=cut
sub master_index :Path :Args(0)
{
    my($self, $c) = @_;
    $c->stash->{template} = "index.tt";
}


=over 4

=item post

Takes a POST request (e.g. from a Web form) and redirects the request to
an appropriately-constructed URI. The parameters should be named I<0>,
I<1>, I<2>, etc. and will be processed in numerical order. An example form
might look like this:

    <form method="post" action="[% c.uri_for(root, 'post') %]>
      <input type="hidden" name="0" value="[% c.uri_for(root, 'show') %]"/>
      <select name="1">
          <option value="foo:12345">Document 12345</option>
          <option value="foo:98765">Document 98765</option>
      </select>
      <button type="submit">Go</button>
    <form>

In this case, if the second option were selected, the request would be
redirected to I<$root/show/foo:98765>.

=back
=cut
# Used by forms that have to construct a URL, this catenates the arguments
# 0, 1, 2, etc. to create a URL and redirects the request.
#sub post :Local :Args(0)
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


=over 4

=item splash

Displays the portal splash page when a request names a portal but nothing else (no interface). E.g.: I</foo>.

=back
=cut
sub splash :Path :Args(1)
{
    my($self, $c, $portal) = @_;
    $c->forward('config_portal', [$portal]);
    $c->forward('set_root', [$portal, undef]);
    $c->stash->{template} = 'splash.tt';
}


=over 4

=item static ( I<@path> )

Retrieve a static document described in I<@path> from the portal's static
directory. E.g.: I</foo/en/static/css/foo.css> would try to serve the
static file in I<$root/foo/static/css/foo.css>.

Often, you will want to configure your web server to intercept these URLs
and serve the content directly.

=back
=cut
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


=over 4

=item test_error ( I<$error> )

Generates an error page for the status code I<$error>, with a test error
message. E.g.: I</foo/xml/error/500>. Only works if I<debug> is set in
I<cap.conf>. Otherwise, a 404 error is generated. This method can be used for
simulating responses to various error conditions without actually
having to create the error condition itself.

=back
=cut
sub test_error : Chained('base') PathPart('error') Args(1)
{
    my($self, $c, $error) = @_;
    if (! $c->config->{debug}) {
        $c->detach('error', [404]);
    }
    $c->detach('error', [$error, 'ERRORTEST']);
}

=head2 Flow Control

=cut


=over 4

=item access_denied

Detach to this method when access to the resource should be
denied due to not being logged in or insufficient user privileges.

=back
=cut
sub access_denied : Private
{
    my($self, $c) = @_;
    warn("[debug] Access denied (insufficient privileges)") if ($c->config->{debug});
    $c->stash->{page} = $c->{stash}->{uri};
    $c->detach('error', [403, "NOACCESS"]);
}


=over 4

=item auto

Executed at the start of each request.

=back
=cut
sub auto :Private
{
    my($self, $c) = @_;

    # Clean up any expired sessions
    my $expired = $c->model('DB::Sessions')->remove_expired();
    warn("[debug] Cleaned up $expired expired sessions") if ($expired);
    return 1;
}


=over 4

=item base

This is the base for (almost) all chained dispatches. It takes two
arguments: the name of the portal and the interface. The portal name must
be one recognized in the config file. The interface can either be an
iface directive in the portal configuration, or any two-letter code. In
the former case, the view will be rendered using the templates in the
$iface subdirectory (e.g. requests for I<foo/xml/*> will render using
the templates in I<$root/foo/templates/xml>). In the latter case, $iface
will be treated as a language code, which will use any i18n resources for
that language, and the Main templates will be used (e.g. requests for
I</foo/en/*> will render using the templates in I<$root/foo/templates/Main>.

A request for I</$portal/static/*> is a special case: it will be
redirected to I</$portal/$default/static/*>, where I<$default> is the
default interface for the portal. This is a bit of a hack so that
requests for static resources from the splash page can be made.

=back
=cut
sub base : Chained('/') PathPart('') CaptureArgs(2)
{
    my($self, $c, $portal, $iface) = @_;
    $portal = lc($portal);
    $iface = lc($iface);

    # The iface parameter overrides the requested interface.
    $iface = $c->req->params->{iface} if ($c->req->params->{iface});

    $c->forward('config_portal', [$portal]);

    # Configure the interface. Two-letter values for $iface are assumed to
    # be languages; other interfaces must be defined in the config file.
    #if ($iface =~ /^[a-z][a-z]$/) {
    #    $c->languages( $iface ? [$iface] : undef);
    #}
    # FIXME: this is a hack. If the interface name is 'static', we assume
    # that this is the splash page asking for a static resource, so we
    # add a dummy interface ('ai', for, let's say, 'arbitrary interface')
    # and redirect the request.
    if ($iface eq 'static') {
        my $static = "/" . $c->req->path;
        my $default = $c->stash->{pconf}->{deafult_iface};
        $static =~ s#/static#/$default/static#;
        $c->res->redirect($c->uri_for($static));
        $c->detach();
    }
    # If an invalid interface is specified, use the default one; generate
    # an error if no default interface is defined.
    elsif (! exists($c->stash->{pconf}->{iface}->{$iface})) {
        warn("[debug] Request for undefined iface \"$iface\"\n") if ($c->config->{debug});
        $c->detach('error', [404]) unless ($c->stash->{pconf}->{default_iface});
        warn("[info] Using default iface \"" . $c->stash->{pconf}->{default_iface} . "\" instead of invalid \"$iface\"\n");
        $iface = $c->stash->{pconf}->{default_iface};
    }

    $c->languages( $iface ? [$iface] : []);
    $c->response->content_type($c->stash->{pconf}->{iface}->{$iface});
    $c->stash->{iface} = $iface;

    $c->forward('set_root', [$portal, $iface]);



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


    # Determine whether the selected application allows the requested
    # action and set up role-based ACLs.
    # It seems we have to roll our own ACL solution, since rules created
    # using the ACL plugin seem to persist between requests, leading to an
    # ever-increasing denial of privilege (FIXME?)
    my %action_ok = ();
    my %role_required = ();

    # First process all of the rules specific to the portal.
    if ($c->stash->{pconf}->{action}) {
        while (my($action, $auth) = each(%{$c->stash->{pconf}->{action}})) {
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
    if ($c->config->{action}) {
        while (my($action, $auth) = each(%{$c->config->{action}})) {
            next if (
                $c->stash->{pconf}->{action} &&
                defined($c->stash->{pconf}->{action}->{$action})
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


=over 4

=item config_portal

Called from I<base> and some of the default actions to set various
configuration parameters based on the requested portal.

=back
=cut
sub config_portal : Private
{
    my($self, $c, $portal) = @_;

    # Check for an external config file for this portal in the portals
    # directory and load it if it exists.

    # If an external configuration file exists for $portal, load it.
    # Otherwise, use the definition in the main config file.
    my $config_file = join('/', $c->config->{root}, $c->config->{portals}, "$portal.conf");
    if (-f $config_file) {
        warn("[debug] Reading config file \"$config_file\"\n") if ($c->config->{debug});
        my $config;
        eval { $config = Config::General->new($config_file) };
        $c->detach('/error', [500, "Failed to parse $config_file"]) if ($@);
        $c->stash->{pconf} = { $config->getall };
    }
    elsif ($c->config->{portal}->{$portal}) {
        $c->stash->{pconf} = $c->config->{portal}->{$portal};
    }
    else {
        $c->detach('error', [404, "BADPORTAL"]);
    }

    # If the portal is disabled, return a file not found response.
    $c->detach('error', [404, "PORTALDISABLED"]) unless ($c->stash->{pconf}->{enabled});

    # Searches should be restricted to a subset of the Solr index.
    if ($c->stash->{pconf}->{subset}) {
        $c->config->{Solr}->{subset} = {};
        while (my($field, $value) = each(%{$c->stash->{pconf}->{subset}})) {
            $c->config->{Solr}->{subset}->{$field} = $value;
        }
    }

    $c->stash->{portal} = $portal;
    return 1;

    # Configure the requested application
    #if ($c->config->{portal}->{$portal}) {
    #    my $conf = $c->config->{portal}->{$portal};
#
## If the portal is disabled, return a file not found response.
#        $c->detach('error', [404, "Portal not enabled"]) unless ($conf->{enabled});
#
#        # Searches should be restricted to a subset of the Solr index.
#        if ($conf->{subset}) {
#            $c->config->{Solr}->{subset} = {};
#            while (my($field, $value) = each(%{$conf->{subset}})) {
#                $c->config->{Solr}->{subset}->{$field} = $value;
#            }
#        }
#
#        $c->stash->{portal} = $portal;
#    }
#    else {
#        $c->detach('error', [404]);
#    }

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
    $c->stash->{portal_dir} = $c->stash->{portal};


    # Look for templates in the $root/templates/$portal/templates/$iface
    # directory. Use "Main" if the interface is a standard language
    # interface. If the template is not found here, the default for the
    # view is used.
    my $subdir = "Main";
    if ($c->stash->{iface} && $c->stash->{iface} !~ /^[a-z][a-z]$/) {
        $subdir = $c->stash->{iface};
    }

    # If a portal is configured, add the default template path for that
    # portal. If an interface is also configured, add the template path
    # for that interface. (The global default path is the final fallback.)
    if ($c->stash->{portal}) {
        if ($c->stash->{iface}) {
            $c->stash->{additional_template_paths} = [ 
                join('/', $c->config->{root}, $c->stash->{portal}, "templates", $c->stash->{iface}), 
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
    my($self, $c, $portal, $iface) = @_;
    my $root = $portal;
    my $uri = $c->request->uri;
    $root .= "/$iface" if ($iface);

    if ($c->config->{prefix}->{$c->request->{base}}) {
        my $prefix = $c->config->{prefix}->{$c->request->{base}};
        $root = substr($root, length($prefix));
        $uri =~ s#\Q/$prefix\E##;
    }
    $root =~ s/\/$//;
    $c->stash->{root} = "/$root";
    $c->stash->{uri} = $uri; # $uri is a self-referential URI.
}

=head1 LICENSE AND COPYRIGHT

See I<CAP/license.txt>.

=head1 AUTHOR

William Wueppelmann L<<william.wueppelmann@canadiana.ca>>

=head1 SEE ALSO

cap.conf, L<CAP>

=cut

1;
