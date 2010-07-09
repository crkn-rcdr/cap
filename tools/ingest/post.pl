#!/usr/bin/perl
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
my $usage = "Usage: $prog --conf CONFIG_FILE [FILE...]";
my $conf_file;
my $use_cmr;
my $verbose;
my $do_ingest;
my $contributor;

my $err_log = "/tmp/ingest.log";

open my $err_out, '>', $err_log or croak "Couldn't open '$err_log': $!";

GetOptions(
    'conf=s' => \$conf_file,
    'cmr' => \$use_cmr,
    'verbose' => \$verbose,
    'ingest' => \$do_ingest,
    'contributor=s' => \$contributor,
) or die ($usage);

die ($usage) unless($conf_file);

my $conf = new Config::General(
    -ConfigFile => $conf_file,
    );

my %config = $conf->getall;

my $solr_uri=$config{'solr'}->{'update_uri'};



if($use_cmr) {
    foreach my $file (@ARGV) {
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
            #print "Caught Error: ".Dumper($@);
        }
        else {
            #my $message = `$solr_cmd`;
            #print $message;
            my $userAgent = LWP::UserAgent->new(agent=>'perl post');
            my $response = $userAgent->request(POST $solr_uri, Content_Type=>'text/xml', Content=>$message);
            if ($do_ingest && $response->is_success) {
                #get ingest list from file
                my $repos=$config{'content'};
                my $ingest = new Ingest($repos);
                my $parser = XML::LibXML->new();
                my $tree=$parser->parse_file($file);
                my $root=$tree->getDocumentElement;
                my @downloads;
                push(@downloads, $root->findnodes('//resource/canonicalDownload'));
                push(@downloads, $root->findnodes('//resource/canonicalMaster'));
                foreach my $download (@downloads) {
                    my $download_file=$download->findvalue('.');
                    if ( -e "$dirname/files/$download_file") {
                        my $fqfn=$ingest->ingest_file("$dirname/files/$download_file", $contributor);
                        if ($verbose) { print "ingested: $fqfn\n" };
                    }
                    else {
                        print "FAIL: did not injest expected file";
                    }
                }


            }
            elsif ($response->is_success) {
                if ( $verbose) {print "SUCCESSFUL POST: $file\n"; };
            }
            else {

                print "FAIL POST $file\n";

            }
        }
    }
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
