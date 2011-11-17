package CAP::Solr::ResultSet;
use strict;
use warnings;

use WebService::Solr;

sub new {
    my($self, $server) = @_;
    my $solr = new WebService::Solr($server);
    use Data::Dumper;
    return Dumper($solr->search('canada'));
}


1;
