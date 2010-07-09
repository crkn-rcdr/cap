package Ingest;

use strict;
use warnings;
use String::CRC32;
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);

use XML::LibXML;
use FindBin;

use CAP::Schema;

sub new 
{
    my $class = shift;
    my $repos = shift;
    my $config= shift;
    my $self             = { };
    $self->{repos}=  $repos ;
    #print "config: ".Dumper($$config{'Component'}{'Model::DB'}{'connect_info'});
    bless ($self, $class);
    my $connect_info=$$config{'Component'}{'Model::DB'}{'connect_info'};
    #print Dumper(%$config{'Component'}{'Model::DB'}{'connect_info'});
    #print "connect_info: ".Dumper($connect_info);
    bless ($self, $class);
    $self->{schema} = CAP::Schema->connect($$connect_info{'dsn'},$$connect_info{'user'},$$connect_info{'password'}) ;
    #print "schema: ".Dumper($self->{schema})."\n";
    
    return $self;
}


sub get_path
{
    # Given a filename return the full filesystem path
    
    my($self, $file, $contributor) = @_;
    my $file_name = basename($file);
    my $digest = String::CRC32::crc32($file_name)  ;
    #print $digest."\n";
    my $hex_prefix = sprintf("%X", $digest);
    my $prefix = substr($hex_prefix, 0, 2) . '/' . substr($hex_prefix, 2, 2);
    #print $prefix."\n";

    my $repos = $self->{repos};

    my $path = "$repos/$contributor/$prefix";

    return $path;
    
}

sub get_fqfn
{
    my($self, $file, $contributor) = @_;

    my $path = $self->get_path($file,$contributor);
    
    my $file_name = basename($file);
    my $fqfn = "$path/$file_name";
    
    return $fqfn;
}

sub ingest_file
{
    my($self, $file, $contributor)=@_;

    my $path=$self->get_path($file, $contributor);
    my $fqfn=$self->get_fqfn($file, $contributor);

    unless (-d $path) {
        make_path($path) or die("Failed to make $path: $!");
    }

    #if same filesystem link, else copy
    if ( -e $fqfn) {
        unlink $fqfn;
    }
    if ((stat($path))[0] == (stat($file))[0]) {
        link($file, $fqfn) or die("Failed to copy $file to $fqfn: $!");
        #print "linked\n";
    }
    else {
        copy($file, $fqfn) or die("Failed to copy $file to $fqfn: $!");
        #print "copied\n";
    }
    
    return $fqfn;

}

sub validate_file
{
    my($self, $file, $solr)=@_;
    
    my $result = $solr->query(0, { type=>"page", canonicalMaster=>$file }, {});
        if(my $md5=$result->{documents}[0]{md5}) {
            if(my $md5_digest eq $md5) {
                print "VALID\n";
            }
            else {
                print "INVALID\n";
            }
        }
        else {
            print "Cannot validate, no md5 record in solr (might try mysql next)\n";
        }
    
}

sub populate_mysql
{
    #populates mysql from solr
    # list of types:
    #   can I grab these from the xsd?

    my($self, $solr, $xsd)=@_;
   
    #print Dumper(@_); 
    my @types;
    my $parser = XML::LibXML->new();
    my $tree=$parser->parse_file($xsd);
    my $root=$tree->getDocumentElement;
    foreach my $doc_type ($root->findnodes('//xs:element[@name="type"]/xs:simpleType/xs:restriction/xs:enumeration')) {
        push(@types, $doc_type->getAttribute("value"));
    }
    #print Dumper(@types);
    foreach my $type (@types) {
        my $result_ref =$solr->query(0, { type=>$type });
        #print Dumper($result_ref);
        my %result=%$result_ref;
        my $hits=$result{hits};
        #print "hits: $hits\n";
        if ($hits>0) {
            my $i=0;
            #print Dumper($result{documents});
            my @doc_arr=$result{documents};
            while(my %doc=pop(@doc_arr)) {
                $i=+1;
                print "key: ".$doc{key}."\n";
                print Dumper(%doc);
                my $download_file;
                my $md5;
                my $record;
                my $id=$result{documents}[$i]{key};
                if(!($record=$self->{schema}->resultset('Record')->find({ id=>$id }))){
                    if ($type eq "monograph") {
                        $download_file=$result{documents}[$i]{canonicalDownload};
                        $md5=$result{documents}[$i]{canonicalDownloadMD5};
                    }
                    elsif ($type eq "page") {
                        $download_file=$result{documents}[$i]{canonicalMaster};
                        $md5=$result{documents}[$i]{canonicalMasterMD5};
                    }
                    print Dumper($result{documents}[$i]);
                    $record=$self->{schema}->resultset('Record')->create({ id=>$id,
                                                               type=>$type,
                                                               filename=>$download_file,
                                                               md5=>$md5,
                                                                });
                }
            
                

            }
        }
    }
} 


1;
