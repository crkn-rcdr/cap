package CAP::Controller::Root;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use Config::General;
use CAP::Solr;
use Encode;
use Net::IP;
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


sub auto :Private
{
    my($self, $c) = @_;
    my %params = ();
    my %cookies = ();

    # Set debug mode
    if ($c->config->{debug}) {
        $c->stash->{debug} = 1;
    }
    
    # Verify that a default portal is set
    if (! $c->config->{default_portal}) {
        $c->detach("config_error", ["default_portal is not set"]);
    }

    # Determine which portal configuration to use
    my $portal;
    if ($c->config->{portals} && $c->config->{portals}->{$c->req->base}) {
        $c->stash->{portal} = $c->config->{portals}->{$c->req->base};
    }
    else {
        $c->stash->{portal} = $c->config->{default_portal};
    }

    # Configure the portal
    {
        # Load and parse the config file
        my $config_file;
        my %portal;
        $config_file = join("/", $c->config->{root}, "config", $c->stash->{portal} . ".conf");
        if (! -f $config_file) {
            $c->detach("config_error", ["Missing configuration file: $config_file"]);
        }
        else {
            my $config;
            eval { $config = Config::General->new( -ConfigFile => $config_file, -AutoTrue => 1, -UTF8 => 1) };
            if ($@) {
                $c->detach("config_error", ["Error loading $config_file: $@"]);
            }
            %portal = $config->getall;
        }

        # Determine whether the portal is enabled for access
        if (! $portal{enabled}) {
            $c->stash->{template} = 'disabled.tt';
            $c->detach();
        }

        # Set the interface language. In order of preference, look for: a
        # usrlang query parameter that explicitly sets the language; a
        # usrlang cookie that remembers the last selected preference; the
        # user agent's accept-language value; and finally the default
        # language.
        if (! $portal{default_lang}) {
            $c->detach("config_error", ["default_lang is not set in $config_file"]);
        }
        if ($c->request->params->{usrlang} && $portal{lang}->{$c->request->params->{usrlang}}) {
            $c->stash->{lang} = $c->request->params->{usrlang};
        }
        elsif ($c->request->cookie('usrlang') && $portal{lang}->{$c->request->cookie('usrlang')->value}) {
            $c->stash->{lang} = $c->request->cookie('usrlang')->value;
        }
        elsif ($c->req->header('Accept-Language')) {
            foreach my $accept_lang (split(/\s*,\s*/, $c->req->header('Accept-Language'))) {
                my ($value) = split(';q=', $accept_lang);
                if ($value) {
                    $value = lc(substr($value, 0, 2));
                    if ($portal{lang}->{$value}) {
                        $c->stash->{lang} = $value;
                        last;
                    }
                }
            }
        }
        else {
            $c->stash->{lang} = $portal{default_lang};
        }

        # Stash whether or not user account and access control functions are enabled
        $c->stash->{user_accounts}  = $portal{user_accounts};
        if ($portal{access_model}) {
            $c->stash->{access_model} = $portal{access_model};
        }
        else {
            $c->stash->{access_model} = 'default';
        }

        # Stash the portal name
        $c->stash->{portal_name} = $portal{lang}->{$c->stash->{lang}}->{name};

        # Stash a list of supported interface languages
        $c->stash->{supported_langs} = [keys(%{$portal{lang}})];

        # Stash the solr subset to search (try that tongue twister twice)
        $c->stash->{search_subset} = $portal{search_subset} || "";


        # Stash the content sets hosted by this portal
        $c->stash->{hosted} = {};
        foreach my $set (keys(%{$portal{hosted}})) {
            # TODO: allow for lists of values...
            $c->stash->{hosted}->{$set} = $portal{hosted}->{$set};
        }

    }

    # If this is an anonymous request, check for a persistence token and,
    # if valid, automatically login the user.
    if (! $c->user_exists) {
        if ($c->request->cookie("persistent")) {
            my $id = $c->model('DB::User')->validate_token($c->request->cookie("persistent")->value);
            if ($id) {
                $c->set_authenticated($c->find_user({id => $id}));
                $c->persist_user();
            }
        }
    }

    # Update the user's last access time.
    if ($c->user_exists) {
        eval { $c->user->update({lastseen => time()}) };
        $c->detach('/error', 500) if ($@);
    }
    

    #
    # Set session variables
    #
    
    # Force the creation of a session and sessionid if they don't already
    # exist. We need this so that logging doesn't barf on the first
    # request of a new session.
    $c->session();

    # Check whether the user's IP address has changed.
    if (! $c->session->{address} || $c->session->{address} ne $c->request->address) {
        $c->session->{address} = "";
    }

    # If not set, set the user's IP address and check group membership.
    $c->forward('user/init') unless ($c->session->{address});

    # Increment the session counter
    $c->session->{count} = 0 unless ($c->session->{count});
    ++$c->session->{count};

    # Call init after a predetermined number of transactions to ensure
    # we're up to date
    if ($c->session->{count} % $c->config->{init_interval} == 0) {
        $c->forward('user/init');
    }
    

    # Set image size and rotation
    if ($c->request->params->{'size'} && $c->config->{derivative}->{size}->{$params{'size'}}) {
        $c->session->{'size'} = $c->request->params->{'size'};
    }
    if ($c->request->params->{'rotate'} && $c->request->params->{'rotate'} eq 'on') {
        $c->session->{'rotate'} = 1;
    }
    if ($params{'rotate'} && $params{'rotate'} eq 'off') {
        $c->session->{'rotate'} = 0;
    }

    #
    # Set stash variables from the session
    #

    $c->stash->{'size'} = $c->session->{'size'}     || "";
    $c->stash->{'rotate'} = $c->session->{'rotate'} || 0;


    # Set the current view
    if (! $c->config->{default_view}) {
        $c->detach("config_error", ["default_view is not set"]);
    }
    if ($c->request->params->{fmt}) {
        if ($c->request->params->{fmt} eq 'json') {
            $c->stash->{current_view} = 'json'; # Builtin view
        }
        elsif ($c->request->params->{fmt} eq 'xml') {
            $c->stash->{current_view} = 'xml'; # Builtin view
        }
        elsif ($c->config->{views}->{$c->request->params->{fmt}}) {
            $c->stash->{current_view} = $c->config->{views}->{$c->Request->params->{fmt}};
        }
        else {
            $c->stash->{current_view} = $c->config->{default_view};
        }
    }
    else {
        $c->stash->{current_view} = $c->config->{default_view};
    }

    # Set a cookie to remember the interface language.
    $c->res->cookies->{usrlang} = { value => $c->stash->{lang}, expires => time() + 7776000 }; # Cookie expires in 90 days TODO: put in cap.conf?

    # Set I18N information for the selected language.
    $c->languages([$c->stash->{lang}]);

    # Fetch a set of language-appropriate labels and tags.
    $c->stash->{label} = $c->model('DB::Labels')->get_labels($c->stash->{lang});

    # Create a Solr object
    $c->stash->{solr} = CAP::Solr->new($c->config->{solr_url}, $c->config->{solr}, $c->stash->{search_subset});

    # Initialize the query response with default values. These may be
    # added to or overwritten when a search query is executed.
    $c->stash('response' => {
        request => "" . $c->req->{uri}, # we need to prepend "" in order to force this to a string
        status => 200,
        version => '0.2', # TODO: this should be in cap.conf
    });

    # Clean up any expired sessions
    my $expired = $c->model('DB::Sessions')->remove_expired();
    warn("[debug] Cleaned up $expired expired sessions") if ($expired);
    return 1;
}


sub access_denied : Private
{
    my($self, $c) = @_;
    warn("[debug] Access denied (insufficient privileges)") if ($c->config->{debug});
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


    # Log the request:
    my $request_log = $c->model('DB::RequestLog')->log($c); # Basic request information
    $c->model('DB::SearchLog')->log($c, $request_log) if ($c->stash->{log_search}); # Search query
    # TODO: user login/out
    # TODO: item access

    # Remove some information from the response if we're not in debug mode.
    if (! $c->stash->{debug}) {
        delete($c->stash->{response}->{solr}) if ($c->stash->{response}->{solr});
    }

    # If the current view is set to one of the special cases 'xml' or
    # 'json', handle the output internally, bypassing the normal view
    # rendering.
    if ($c->stash->{current_view} eq 'json') {
        $c->res->content_type('application/json; charset=UTF-8');
        $c->res->body(encode_json($c->stash->{response}));
        return 1;
    }
    elsif ($c->stash->{current_view} eq 'xml') {
        my $xml = xmlify('response', $c->stash->{response});
        $c->res->content_type('application/xml');
        $c->res->body(decode_utf8($xml->toString(1)));
        return 1;
    }

    # Don't cache anything (TODO: this is a bit harsh, but it does control
    # the login/logout refresh problem.) TODO: revisit this; a lot has
    # changed in the meantime
    if ($c->action eq 'static') {
        $c->res->header('Cache-Control' => 'max-age=3600');
    }
    else {
        $c->res->header('Cache-Control' => 'no-cache');
    }

    $c->stash->{additional_template_paths} = [
        join('/', $c->config->{root}, 'templates', $c->stash->{current_view}, $c->stash->{portal}),
        join('/', $c->config->{root}, 'templates', $c->stash->{current_view}, 'Common')
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
    $c->stash->{response}->{type} = "error";
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

    # If the adv parameter is set, parse the advanced search variables.
    # Otherwise, do a regular search.
    if ($c->req->params->{adv}) {
        return $c->forward('search/advanced', [$page]);
    }
    else {
        return $c->forward('search/main');
    }
}

sub file :Path('file') Args(2)
{
    my($self, $c, $key, $filename) = @_;
    return $c->forward('file/main', [$key, $filename]);
}

sub view :Path('view') Args() {
    my($self, $c, $key, $seq, $extra) = @_;
    if ($extra) {
        $c->detach('/error', [404]);
    }
    elsif ($seq) {
        # TODO: check if int > 0
        return $c->forward('view/page', [$key, $seq]);
    }
    elsif ($key) {
        return $c->forward('view/main', [$key]);
    }
    else {
        $c->detach('/error', [404]);
    }
}

sub support :Path('support') Args() {
    my($self, $c, @resource) = @_;
    my $support = join('/', $c->config->{root}, 'support', $c->stash->{portal}, @resource) . ".tt";
    if(! open(INFO, "<$support")) {
        $c->detach('/error', [404]);
    }
    $c->stash->{support}     = decode_utf8(join("", <INFO>));
    close(INFO);
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
    $c->res->status(500);
    $c->res->body("<html><head><title>Configuration Error</title><body><h1>Configuration Error</h1><p>$message</p></body></html>");
    return 0;
}

# Serve a file in the static directory under root. In production, requests
# for /static should be intercepted and handled by the web server.
sub static : Path('static') Args()
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

1;

