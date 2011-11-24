package CAP::Controller::File;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use CAP::Ingest;
use Digest::SHA1 qw(sha1_hex);
use POSIX qw( strftime );
use URI::Escape;

=head1 NAME

CAP::Controller::File - Catalyst Controller

=cut

sub for_page :Private {
    my($self, $c, $key, $seq, $filename) = @_;
    my $solr   = $c->stash->{solr};

    my $child = $solr->child($key, $seq);
    $c->detach('/error', [404, "$key: no such child seq $seq"]) unless ($child);
    $c->forward('main', [$child->{key}, $filename]);
    return 1;
}

sub main :Private
{
    my($self, $c, $key, $filename) = @_;
    my $params;
    my $size   = $c->config->{derivative}->{default_size};
    my $rotate = 0;
    my $format = $c->req->params->{f} || "";
    my $url    = $c->config->{content}->{url};

    my $doc = $c->model("Solr")->document($key);

    # Make sure the item exists.
    $c->detach('/error', [404, "$key: no such record"]) unless ($doc);

    # Series have no accessible resources, so any such request is a bad request.
    $c->detach('/error', [400, "$key: is a series"]) if ($doc->type_is('series'));

    # Generate authorization information for this document.
    my $user_can_view     = 0;
    my $user_can_resize   = 0;
    my $user_can_download = 0;
    if ($doc->type_is('document')) {
        $doc->set_auth($c->stash->{access_model}, $c->user);
        $user_can_download = $doc->auth->download;
    }
    else {
        $doc->parent->set_auth($c->stash->{access_model}, $c->user);
        $user_can_view     = $doc->parent->auth->page($doc->seq);
        $user_can_resize   = $doc->parent->auth->resize;
    }

    # If the f (format) parameter is present, we are asking for a
    # derivative from the canonical master. Otherwise, we want the
    # canonical download for $key.
    if ($format) {
        # Make sure we have a canonical master.
        $c->detach('/error', [400, "$key does not have a canonical master."]) unless $doc->canonicalMaster;

        # Check whether the user is allowed to access this resource.
        $c->detach('/error', [403, "Not allowed to view this page"]) unless ($user_can_view);
        
        # Determine the image size to generate.
        if ($c->req->params->{s} && $c->config->{derivative}->{size}->{$c->req->params->{s}}) {
            $size = $c->config->{derivative}->{size}->{$c->req->params->{s}};
        }

        # Check whether the user is allowed to resize documents, if that
        # is requested.
        $c->detach('/error', [403, "Not allowed to resize this page"]) if ($size ne $c->config->{derivative}->{default_size} && ! $user_can_resize);

        # Determine whether or not to rotate the image
        if ($c->req->params->{r} && $c->config->{derivative}->{rotate}->{$c->req->params->{r}}) {
            $rotate = $c->config->{derivative}->{rotate}->{$c->req->params->{r}};
        }

        # Generate the request parameters
        $params = $c->forward('derivative', [$filename, $doc->canonicalMaster, $format, $size, $rotate]);
    }
    else {
        # Make sure we have a canonical download.
        $c->detach('/error', [400, "$key does not have a canonical master."]) unless $doc->canonicalDownload;

        # Check whether the user is allowed to access this resource.
        $c->detach('/error', [403, "Not allowed to download this resource"]) unless ($user_can_download);

        # Generate the request parameters.
        $params = $c->forward('download', [$doc->canonicalDownload]);
        $filename = $doc->canonicalDownload;
    }

    $c->res->redirect(join('?', join('/', $url, $filename), join('&', @{$params})));
    $c->detach();
}

sub download :Private
{
    my($self, $c, $filename) = @_;

    my $password  = $c->config->{content}->{password};
    my $key       = $c->config->{content}->{key};
    my $expires   = _expires();
    my $signature = sha1_hex("$password\n$filename\n$expires\n\n\n");

    return [
        'expires='   . uri_escape($expires),
        'signature=' . uri_escape($signature),
        'key='       . uri_escape($key),
    ];
}

sub derivative :Private
{
    my($self, $c, $filename, $from, $format, $size, $rotate) = @_;

    my $password  = $c->config->{content}->{password};
    my $key       = $c->config->{content}->{key};
    my $expires   = _expires();
    my $signature = sha1_hex("$password\n$filename\n$expires\n$from\n$size\n$rotate");

    return [
        'expires='   . uri_escape($expires),
        'signature=' . uri_escape($signature),
        'key='       . uri_escape($key),
        'from='      . uri_escape($from),
        'format='    . uri_escape($format),
        'size='      . uri_escape($size),
        'rotate='    . uri_escape($rotate),
    ];
}

sub _expires
{
    my $time = time() + 90000; # 25 hours in the future
    $time = $time - ($time % 86400); # normalize the expiry time to the closest 24 hour period
    return $time; # minimum 1 hour from now, maximum 25
}

1;
