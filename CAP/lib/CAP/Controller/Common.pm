package CAP::Controller::Common;
use Moose;
use namespace::autoclean;
use Digest::MD5 qw(md5_hex);
use Ingest;
use Data::Dumper;

BEGIN {extends 'Catalyst::Controller'; }

sub repos_path2 :Private
{
    my ( $self, $c, $doc ) = @_;

    # Create a subdirectory tree using a standardized algorithm to put
    # files in predictable places and keep directory sizes reasonable:
    my $subdir = substr( $doc->{key}, length( $doc->{contributor} ) + 1 ); # remove the leading "$contributor."
    my @components = split(/\./, $subdir);
    if ( @components > 2 ) {
        pop( @components );
        pop( @components );
    }
    $subdir = join( '/', @components );

    # Join with the base dir + contributor dir and return the full path to
    # the file.
    return join('/', $c->config->{content}, $doc->{contributor}, $subdir);
}

sub repos_path :Private
{
    my($self, $c, $doc) = @_;
    my $content=$c->config->{content};
    my $ingest = new Ingest($content);
    my $path=$ingest->get_path($doc->{file}, $doc->{contributor});
    warn("[debug] Repository path is $path\n");
    
    return $path;

    #my $digest = md5_hex($doc->{file});
    #my $path = join('/', $c->config->{content}, $doc->{contributor}, substr($digest, 0, 2), substr($digest, 2, 2));

    #warn("[debug] Repository path is $path\n");

    #return $path;
}

__PACKAGE__->meta->make_immutable;

