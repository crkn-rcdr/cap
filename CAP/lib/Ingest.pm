package Ingest;

use strict;
use warnings;
use String::CRC32;
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Path qw(make_path);



sub new 
{
    my $class = shift;
    my $repos = shift;
    my $self             = { };
    $self->{repos}=  $repos ;
    #print Dumper($self);
    bless ($self, $class);
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
    copy($file, $fqfn) or die("Failed to copy $file to $fqfn: $!");
    
    return $fqfn;

}
1;
