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
    my %params = ();
    my %cookies = ();

    $c->stash->{current_view} = 'Default';

    # Check the MySQL database version; make sure we are up to date
    if (! $c->model('DB::Info')->check_version($c->config->{db_version})) {
        $c->detach("config_error", ["Incorrect cap.info database version (cap.conf is expecting version " . $c->config->{db_version} . "). Upgrade database or modify cap.conf."]);
    }
    
    ############
    #
    
    
    # Get the portal configuration.
    my $portal_config = $c->configure_portal;

    # If no portal is found or the portal is disabled, redirect to the
    # default URL.
    unless ($portal_config && $portal_config->enabled) {
        $c->res->redirect($c->config->{default_url});
        $c->detach();
    }

    $c->stash->{portal_config} = $portal_config;
    $c->stash->{portal} = $portal_config->id;

    #
    ############


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

        $c->config->{portal} = \%portal;


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
        $c->stash->{lang} = $portal{default_lang} unless $c->stash->{lang};

        # Stash whether or not user account and access control functions are enabled
        $c->stash->{user_accounts}  = $portal{user_accounts};
        $c->stash->{payment_processing} = $portal{payment_processing};
        if ($portal{access_model}) {
            $c->stash->{access_model} = $portal{access_model};
        }
        else {
            $c->stash->{access_model} = 'default';
        }

        # Stash whether or not to show media icons
        $c->stash->{media_icons} = $portal{media_icons} || 0;

        # Stash the list of valid support terms
        $c->stash->{support} = $portal{support} if ($portal{support});

        # Stash portal-supported features
        $c->stash->{features} = $portal{features} || {};

        # Set the subscription price and eligible tax receipt amount, if
        # any
        $c->stash->{subscription_price} = $portal{subscription_price} || 0;
        $c->stash->{tax_receipt} = $portal{tax_receipt} || 0;
        $c->stash->{tax_rcpt_pct} = $portal{tax_rcpt_pct} || 0;

        # Stash the portal name
        $c->stash->{portal_name} = $portal{lang}->{$c->stash->{lang}}->{name};

        # Stash the search bar placeholder text
        $c->stash->{search_bar_placeholder} = $portal{lang}->{$c->stash->{lang}}->{search_bar_placeholder} || "";

        # Stash a list of supported interface languages
        $c->stash->{supported_langs} = [keys(%{$portal{lang}})];

        # TODO: can be removed when all of the portals have portal_collection data in their tables
        $c->stash->{search_subset} = $portal{search_subset} || "";

        # Stash the content sets hosted by this portal
        $c->stash->{hosted} = {};
        foreach my $set (keys(%{$portal{hosted}})) {
            # TODO: allow for lists of values...
            $c->stash->{hosted}->{$set} = $portal{hosted}->{$set};
        }
        
        # Stash the instituion alias
        if ($c->session->{subscribing_institution_id}) {
        
          $c->stash->{institution_alias} = $c->model('DB::InstitutionAlias')->get_alias($c->session->{subscribing_institution_id},
                                                                                        $c->stash->{lang})
                                                                             ||
                                           $c->session->{subscribing_institution};
        
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
                $c->user->log('RESTORE_SESSION', sprintf("from %s", $c->req->address));
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
    
    $c->update_session();
    ++$c->session->{count};

    # Set the current view
    if (! $c->config->{default_view}) {
        $c->detach("config_error", ["default_view is not set"]);
    }
    if ($c->req->params->{fmt}) {
        if ($c->config->{fmt}->{$c->req->params->{fmt}}) {
            $c->stash->{current_view} = $c->config->{fmt}->{$c->req->params->{fmt}}->{view};
            $c->res->content_type($c->config->{fmt}->{$c->req->params->{fmt}}->{content_type});
        }
        else {
            $c->stash->{current_view} = $c->config->{default_view};
        }
    }
    else {
        $c->stash->{current_view} = $c->config->{default_view};
    }
    $c->stash->{additional_template_paths} = [
        join('/', $c->config->{root}, 'templates', $c->stash->{current_view}, $c->stash->{portal}),
        join('/', $c->config->{root}, 'templates', $c->stash->{current_view}, 'Common')
    ];

    # Set a cookie to remember the interface language.
    $c->res->cookies->{usrlang} = { value => $c->stash->{lang}, expires => time() + 7776000 }; # Cookie expires in 90 days TODO: put in cap.conf?

    # Set I18N information for the selected language.
    $c->languages([$c->stash->{lang}]);

    # Fetch a set of language-appropriate labels and tags.
    $c->stash->{label} = $c->model('DB::Labels')->get_labels($c->stash->{lang});
    $c->stash->{contributors} = $c->model('DB::Institution')->get_contributors($c->stash->{lang});
    $c->stash->{languages} = $c->model('DB::Language')->get_labels($c->stash->{lang});
    $c->stash->{media} = $c->model('DB::MediaType')->get_labels($c->stash->{lang});

    # Initialize the query response with default values. These may be
    # added to or overwritten when a search query is executed.
    $c->stash('response' => {
        request => "" . $c->req->{uri}, # we need to prepend "" in order to force this to a string
        status => 200,
        version => '0.3', # TODO: this should be in cap.conf
    });

    # Log the request.
    $c->model('DB::RequestLog')->log($c);

    return 1;
}


sub access_denied : Private :Local Does('NoSSL') {
    my($self, $c) = @_;
    warn("[debug] Access denied (insufficient privileges)") if ($c->debug);
    $c->stash->{page} = $c->{stash}->{uri};
    $c->detach('error', [403, "NOACCESS"]);
}

# The default action is to redirect back to the main page.
sub default :Path :Local Does('NoSSL') {
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

sub index :Local Does('NoSSL') Path('') Args(0)
{
    my($self, $c) = @_;

    # Messsages bugging you to subscribe already
    if ($c->stash->{portal} eq 'eco' && !$c->session->{subscribing_institution}) {
        if ($c->user_exists) {
            if ($c->user->has_class("trial")) {
                if ($c->user->has_active_subscription) {
                    $c->message({ type => "success", message => "active_trial_prod" });
                } else {
                    $c->message({ type => "success", message => "expired_trial_prod" });
                }
            } elsif (! $c->user->has_class) {
                $c->message({ type => "success", message => "no_trial_prod" });
            }
        } else {
            $c->message({ type => "success", message => "anonymous_prod" });
        }
    }

    $c->stash->{slides} = $c->model("DB::Slide")->get_slides($c->stash->{portal}, "frontpage");
    $c->stash->{template} = "index.tt";
}

sub support :Path('support') :Local Does('NoSSL') Args() {
    my ($self, $c, $resource) = @_;
    unless ($c->stash->{support}->{$resource}) {
        $c->detach("error", [404]);
    }
    $c->stash->{support_resource} = $resource;
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
sub static : Path('static') :Local Does('NoSSL') Args()
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

