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
my $prog = basename($0);
my $usage = "Usage: $prog --conf CONFIG_FILE [FILE...]";
my $conf_file;
my $use_cmr;

GetOptions(
    'conf=s' => \$conf_file,
    'cmr' => \$use_cmr
) or die ($usage);

die ($usage) unless($conf_file);

my $conf = new Config::General(
    -ConfigFile => $conf_file,
    );

my %config = $conf->getall;

my $solr_uri=$config{'solr'}->{'update_uri'};

if($use_cmr) {
    foreach my $file (@ARGV) {
        print "Posting file $file to $solr_uri\n";
        system ('xsltproc '.$FindBin::Bin.'/../cmr-tools/cmr2solr.xsl '.$file.' 2>/dev/null | curl '.$solr_uri.' --data-binary @- -H "Content-type:text/xml; charset=utf-8" ');
        #print  ('saxonb-xslt -s:'.$file.' -xsl:'.$FindBin::Bin.'/../cmr-tools/cmr2solr.xsl 2>/dev/null | curl '.$solr_uri.' --data-binary @- -H "Content-type:text/xml; charset=utf-8" ');
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
system("curl $solr_uri --data-binary '<commit/>' -H 'Content-type:text/xml; charset=utf-8'");
