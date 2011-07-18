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

sub main :Private
{
    my($self, $c, $key, $filename) = @_;
    my $params;
    my $size   = $c->config->{derivative}->{default_size};
    my $rotate = 0;
    my $solr   = $c->stash->{solr};
    my $format = $c->req->params->{f} || "";
    my $doc    = $solr->document($key);
    my $url    = $c->config->{content}->{url};

    # Make sure the item exists and that the user has access permission to it.
    $c->detach('/error', [404, "$key: no such record"]) unless ($doc);
    $c->detach('/error', [403, "No access for $key"]) unless ($c->forward('/user/has_access', [$doc]));

    # Determine the image size to generate.
    if ($c->req->params->{s} && $c->config->{derivative}->{size}->{$c->req->params->{s}}) {
        $size = $c->config->{derivative}->{size}->{$c->req->params->{s}};
    }

    # Determine whether or not to rotate the image
    if ($c->req->params->{r} && $c->config->{derivative}->{rotate}->{$c->req->params->{r}}) {
        $rotate = $c->config->{derivative}->{rotate}->{$c->req->params->{r}};
    }


    if ($format && $doc->{canonicalMaster}) {
        $params = $c->forward('derivative', [$filename, $doc->{canonicalMaster}, $format, $size, $rotate]);
    }
    elsif ($doc->{canonicalDownload}) {
        $params = $c->forward('download', [$doc->{canonicalDownload}]);
        $filename = $doc->{canonicalDownload};
    }
    else {
        $c->detach('/error', [404, "Insufficient information to generate file for $key"]);
    }

    $c->res->redirect(join('?', join('/', $url, $filename), join('&', @{$params})));
    $c->detach();
}

sub download :Private
{
    my($self, $c, $filename) = @_;

    my $password  = $c->config->{content}->{password};
    my $key       = $c->config->{content}->{key};
    #my $expires   = time() + $c->config->{content}->{expires};
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
    #my $expires   = time() + $c->config->{content}->{expires};
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
