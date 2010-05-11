#!/usr/bin/perl
use strict;
use warnings;

=head1 NAME

ingest - ingest the contents of a BagIt archive into the Canadiana Access Portal

=head1 SYNOPSIS

ingest -contributor I<CONTRIBUTOR> -url I<http://host/app> I<FILE> [I<FILE...>]

=head1 DESCRIPTION

=cut

use Encode;
use File::Basename;
use Getopt::Long;
use HTTP::Request::Common;
use LWP::UserAgent;
use URI::Escape;
use XML::LibXML;


my $version = 0.20091201;
my $prog = basename($0);

my $contributor = undef;
my $uri = undef;
my $username = undef;
my $password = undef;
my $autocommit = 1;

my $usage =  "Usage: $prog -c CONTRIBUTOR -url URL -username USER -password PASS FILE [FILE...]\n";

GetOptions(
    'autocommit!' => \$autocommit,
    'contributor=s' => \$contributor,
    'password=s' => \$password,
    'username=s' => \$username,
    'url=s' => \$uri
) or die($usage);

die ($usage) unless($contributor && $uri && @ARGV);

my $errors = 0;
my $xml = XML::LibXML->new();
my $auth = "username=" . uri_escape($username) . "&password=" . uri_escape($password);

my $uri_upload = "$uri/xml/content/upload";
my $uri_commit = "$uri/xml/content/commit";
my $uri_finish = "$uri/xml/content/cleanup";

my $nocommit = "";
$nocommit = "&nocommit=1" unless ($autocommit);

my $agent= LWP::UserAgent->new(timeout => 600);


$| = 1; # Don't buffer output

print("Autocommit is on\n") if ($autocommit);

foreach my $file (@ARGV) {

    die("$file does not exist") unless (-f $file);
    print "Uploading $file to $uri_upload ... ";

    my $response = $agent->request(POST  $uri_upload, Content_Type => 'form-data',
     Content => [ contributor => $contributor, username => $username, password => $password, file => [$file]]);

    my $doc;
    eval { $doc = $xml->parse_string($response->content) };
    die("\nError parsing XML: $@\n\nGot this response:\n" . $response->content . "\n") if ($@);

    print("ok\n");

    print("Checking upload status ... ");
    if (int($doc->findvalue('/response/ok'))) {
        print("ok\n");
    }
    else {
        die("\nError uploading BagIt archive. Got this response:\n" . $doc->toString(1, 1) . "\n");
    }

    my @objects = ($doc->findnodes('/response/ingest/uri'));
    my $n_objects = int(@objects);
    my $i = 0;
    print("$n_objects in package to process.\n");

    foreach my $object (@objects) {
        ++$i;
        my $object_uri = decode_utf8($object->textContent());
        print("Processing item $i of $n_objects ($object_uri) ... ");
        $response = $agent->request(GET $object_uri . "&$auth");
        eval { $doc = $xml->parse_string($response->content) };
        die("\nError parsing XML: $@\n\nGot this response:\n" . $response->content . "\n") if ($@);
        print("ok\n");
        print("Checking ingest status ... ");
        if (int($doc->findvalue('/response/ok'))) {
            print("ok\n");
        }
        else {
            die("\nError uploading BagIt archive. Got this response:\n" . $doc->toString(1, 1) . "\n");
        }
    }

    if (! $autocommit) {
        print("Committing changes ... ");
        $response = $agent->request(GET $uri_commit . "?$auth");
        eval { $doc = $xml->parse_string($response->content) };
        die("\nError parsing XML: $@\n\nGot this response:\n" . $response->content . "\n") if ($@);
        if (int($doc->findvalue('/response/ok'))) {
            print("ok\n");
        }
        else {
            print("Commit failed. Got this response:\n" . $response->content);
        }
    }

    print("Removing uploaded file ... ");
    $response = $agent->request(GET $uri_finish . "/$contributor?$auth");
    eval { $doc = $xml->parse_string($response->content) };
    die("\nError parsing XML: $@\n\nGot this response:\n" . $response->content . "\n") if ($@);
    if (int($doc->findvalue('/response/ok'))) {
        print("ok\n");
    }
    else {
        print("Cleanup failed. Got this response:\n" . $response->content);
    }

}
