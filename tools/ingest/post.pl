#!/usr/bin/perl

# Post one or more Solr XML files to a Solr index.
# By default, data will be posted to http://localhost:8983/solr/update.
# Use the -solr parameter to specify a different URL.

use strict;
use warnings;
use lib "/opt/cap-libs/perl/lib/perl5";
use Getopt::Long;
use File::Basename;
use Config::General;
use FindBin;
use lib "$FindBin::Bin/../../CAP/lib";
use Carp;
use POSIX qw( WIFEXITED);
use LWP::UserAgent;
use HTTP::Request::Common;
use XML::LibXML;
use XML::LibXSLT;
use Data::Dumper;
use CAP::Ingest;


my $prog = basename($0);
my $usage = "Usage: $prog [-verbose] [-solr=SOLR_URL] [FILE...]\n";
my $use_cmr = 1;
my $verbose;
my $do_ingest;
my $contributor;

my $err_log = "/tmp/ingest.log";

open my $err_out, '>', $err_log or croak "Couldn't open '$err_log': $!";

my $solr_uri = 'http://localhost:8983/solr/update';

GetOptions(
    #'cmr' => \$use_cmr,
    'verbose' => \$verbose,
    #'ingest' => \$do_ingest,
    #'contributor=s' => \$contributor,
    'solr=s' => \$solr_uri,
) or die ($usage);

warn("Posting records to $solr_uri (use the -solr parameter to specify a different URL)\n");

if($use_cmr) {
    my %counts = ( files => 0, ok => 0, fail => 0 );
    foreach my $file (@ARGV) {
        ++$counts{files};
        if($verbose) {print "Posting file $file to $solr_uri\n"};
        my $xsl=$FindBin::Bin.'/../cmr-tools/cmr2solr.xsl';
        my $solr_cmd='xsltproc '.$FindBin::Bin.'/../cmr-tools/cmr2solr.xsl '.$file.' 2>/dev/null';
        my $xslt = XML::LibXSLT->new();
        my $stylesheet = $xslt->parse_stylesheet_file($xsl);
        my $result;
        my $message;
        my $dirname=dirname($file);
        
        eval { 
            $result = $stylesheet->transform_file($file); 
            $message = $stylesheet->output_as_bytes($result);
        };
        if($@) {
            print "FAIL: $file\n";
            ++$counts{fail};
            #print "Caught Error: ".Dumper($@);
        }
        else {
            my $userAgent = LWP::UserAgent->new(agent=>'perl post');
            my $response = $userAgent->request(POST $solr_uri, Content_Type=>'text/xml', Content=>$message);
            if ($response->is_success) {
                if ( $verbose) {print "SUCCESSFUL POST: $file\n"; };
                ++$counts{ok};
            }
            else {

                print "FAIL POST $file\n";
                ++$counts{fail};
            }
        }
    }
    printf("Files processed: %d (%d OK, %d failures)\n", $counts{files}, $counts{ok}, $counts{fail});
}
else {
    foreach my $file (@ARGV) {
      print "Posting file $file to $solr_uri\n";
      system ("curl $solr_uri --data-binary @".$file." -H 'Content-type:text/xml; charset=utf-8' ");
    }
}

#send the commit command to make sure all the changes are flushed and visible
print "Committing changes\n";
my $message = "<commit/>";
my $userAgent = LWP::UserAgent->new(agent=>'perl post');
my $response = $userAgent->request(POST $solr_uri, Content_Type=>'text/xml', Content=>$message);

#system("curl $solr_uri --data-binary '<commit/>' -H 'Content-type:text/xml; charset=utf-8'");
