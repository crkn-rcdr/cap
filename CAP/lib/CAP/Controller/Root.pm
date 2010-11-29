package CAP::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Config::General;
use CAP::Solr;
use JSON;
use XML::LibXML;

use utf8;

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
__PACKAGE__->config->{namespace} = '';


# Unpack a Perl data structure into a LibXML document object. $name is the
# name of the root element and $content is a pointer to a hash, array, or
# scalar containing the document data. $xml and $node should be left undefined.
sub xmlify
{
    my($name, $content, $xml, $node) = @_;
    
    $xml = XML::LibXML::Document->new('1.0', 'UTF-8') unless ($xml);

    my $element = $xml->createElement($name);
    if ($node) {
        $node->appendChild($element);
    }
    else {
        $xml->setDocumentElement($element);
    }

    if (ref($content) eq 'ARRAY') {
        foreach my $itm (@{$content}) {
            xmlify('ITM', $itm, $xml, $element);
        }
    }
    elsif (ref($content) eq 'HASH') {
        while (my($key, $value) = each(%{$content})) {
            xmlify($key, $value, $xml, $element);
        }
    }
    elsif ($content) {
        $element->appendChild($xml->createTextNode($content));
    }

    return $xml;
}


sub begin :Private
{
    my($self, $c) = @_;

    unless ($c->config->{version} >= $CAP::VERSION) {
        $c->res->body(
            "Your cap.conf file is out of date. " .
            "Check that you are using version of cap.conf.erb based on version $CAP::VERSION or later"
        );
        return 0;
    }

    # Determine which portal configuration to use
    $c->forward('config_portal');

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

    # Check for an alternative format request.
    if ($c->req->params->{fmt}) {
        my $fmt = $c->req->params->{fmt};
        if ($c->stash->{config}->{fmt}->{$fmt}) {
            $c->stash->{fmt} = $c->req->params->{fmt} 
        }
        delete($c->req->params->{fmt});
    }

    # Create a Solr object
    $c->stash->{solr} = CAP::Solr->new($c->config->{solr}, $c->stash->{config}->{subset});

    # Clean up any expired sessions
    my $expired = $c->model('DB::Sessions')->remove_expired();
    warn("[debug] Cleaned up $expired expired sessions") if ($expired);
    return 1;
}


sub auto :Private
{
    my($self, $c) = @_;

    # Check that the portal is enabled.
    unless ($c->stash->{config}->{enabled}) {
        $c->forward('error', [503, "portal disabled"]);
        return 0;
    }

    # Check that the requested action is enabled.
    unless ($c->stash->{config}->{action}->{$c->req->action}) {
        $c->forward('error', [404, $c->req->action . " is not enabled"]);
        return 0;
    }
}

#sub post : Chained('base') PathPart('post') Args(0)
#{
#    my($self, $c) = @_;
#    my @parts = ();
#    my $i = 0;
#    while ($c->request->params->{$i}) {
#        push(@parts, $c->request->params->{$i});
#        $i += 1;
#    }
#    $c->response->redirect(join('/', @parts), 303);
#}

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
        return $lang if ($c->stash->{config}->{lang}->{$lang});
    }

    # If a cookie is present and contains a supported language, use it.
    if ($c->req->cookie('usrlang')) {
        $lang = $c->req->cookie('usrlang')->value;
        if ($c->stash->{config}->{lang}->{$lang}) {
            return $lang;
        }
    }

    # Override with the supported language with the highest q value from
    # the Accept-Language header.
    if ($c->req->header('Accept-Language')) {
        my $lang_q = -1;
        foreach my $accept_lang (split(/\s*,\s*/, $c->req->header('Accept-Language'))) {
            my ($val, $q) = split(';q=', $accept_lang);
            $q = 0 unless ($q);
            $q = 1 if ($q && $q eq '');
            if ($val) {
                $val = lc(substr($val, 0, 2));
                if ($c->stash->{config}->{lang}->{$val} && int($q) > $lang_q) {
                    $lang = $val;
                    $lang_q = int($q);
                }
            }
        }
        return $lang if ($lang_q != -1);
    }

    # Use the default language
    return $c->stash->{config}->{default_lang};
}

# Read the portal configuration file and apply its characteristics.
sub config_portal : Private
{
    my($self, $c) = @_;
    my $portal;
    my $config;

    # Are we in debug mode?
    $c->stash->{debug} = 1 if ($c->config->{debug});

    # Determine which portal to configure based on the base URL.
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
        my $config_general;
        eval { $config_general = Config::General->new( -ConfigFile => $config_file, -AutoTrue => 1, -UTF8 => 1) };
        $c->detach('/error', [500, "Failed to parse $config_file"]) if ($@);
        $config = { $config_general->getall };
        $c->stash->{config} = $config;
    }
    else {
        $c->detach('error', [404, "BADPORTAL"]); # Test this. Should probably die.
    }

    # Use defaults from cap.conf in cases where a corresponding value is
    # not specified in the portal config file.
    foreach my $item (qw(fmt  action)) {
        $config->{$item} = {} unless (exists($config->{$item}));
        if (exists($c->config->{$item})) {
            while (my($key, $value) = each(%{$c->config->{$item}})) {
                $config->{$item}->{$key} = $value unless (defined($config->{$item}->{$key}));
            }
        }
    }

    $c->stash->{config} = $config;
    $c->stash->{portal} = $portal;
    return $portal;
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

    # Remove some information from the response if we're not in debug mode.
    if (! $c->stash->{debug}) {
        delete($c->stash->{response}->{solr}) if ($c->stash->{response}->{solr});
    }

    # Automatically handle some builtin format types. Otherwise, set the
    # view to use.
    if (! $c->stash->{fmt}) {
        ; # Use whatever is in $c->stash->{current_view} or $c->config->{default_view}
    }
    elsif ($c->stash->{fmt} eq 'json') {
        $c->res->content_type('application/json');
        $c->res->body(to_json($c->stash->{response}, { utf8 => 1, pretty => 1 }));
        return 1;
    }
    elsif ($c->stash->{fmt} eq 'xml') {
        my $xml = xmlify('response', $c->stash->{response});
        $c->res->content_type('application/xml');
        $c->res->body($xml->toString(1));
        return 1;
    }
    else {
        $c->stash->{current_view} = ucfirst($c->stash->{fmt});
    }

    # Don't cache anything (TODO: this is a bit harsh, but it does control
    # the login/logout refresh problem.) TODO: revisit this; a lot has
    # changed in the meantime
    if ($c->action eq 'static') {
        $c->res->header('Cache-Control' => 'max-age=3600');
    }
    elsif ($c->action eq 'file/file') {
        $c->res->header('Cache-Control' => 'max-age=3600');
    }
    else {
        $c->res->header('Cache-Control' => 'no-cache');
    }

    # If no template is defined, use the default.
    if (! $c->stash->{template}) {
        $c->stash->{template} = "default.tt";
    }

    # In addition to the default template path, prepend additional paths
    # based on the portal name and the current view
    $c->stash->{additional_template_paths} = [ 
        join('/', $c->config->{root}, $c->stash->{portal}, "templates", $c->stash->{current_view}), 
        join('/', $c->config->{root}, "Default", "templates", $c->stash->{current_view}), 
        join('/', $c->config->{root}, $c->stash->{portal}, "templates", 'Default')
    ];

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

sub index :Path('') Args(0)
{
    my($self, $c) = @_;
    $c->stash->{template} = "index.tt";
}

sub search : Path('search') Args() {
    my($self, $c, $page) = @_;
    $page = 1 unless ($page);
    my $param = { page => 1};
    return $c->forward('search/main', [$page]);
}

sub show :Path('show') Args() {
    my($self, $c, @args) = @_;
    return $c->forward('show/main', [@args]);
}

sub static : Path('static') Args()
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

sub favicon :Path('favicon.ico') Args(0)
{
    my($self, $c) = @_;
    $c->res->redirect($c->uri_for_action('static', ['favicon.ico']));
}

sub test_error :Path('error') Args(1)
{
    my($self, $c, $error) = @_;
    $c->detach('error', [$error, 'Test error']);
}

1;

