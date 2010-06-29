package CAP::Controller::File;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use POSIX qw( strftime );
use CAP::Ingest;

=head1 NAME

CAP::Controller::File - Catalyst Controller

=head1 DESCRIPTION

Retrieve digital objects

=head1 METHODS

=head2 get($key, $file)

=over 4

Create a derivative from the canonical master for $key. $file is the file
name that appears in the URL. The name can be anything, but the suffix
determines the output file format. (E.g. 'file.png' creates a PNG
derivative). The I<s> and I<r> parameters can be used to specify the file
size.

=back

=head2 download($key, $file)

=over 4

Works like B<get()> except that it looks for the canonical download file
and outputs it without any transformation. The I<s> and I<r> query
parameters are therefore ignored.

=back

=cut

sub get :Chained('/base') PartPath('/get') Args(2)
{
    my($self, $c, $key, $file) = @_;
    my $suffix = "";

    # Retrieve the record for the requested document. Verify that it
    # exists.
    my $solr = CAP::Solr->new($c->config->{solr});
    my $doc = $solr->document($key);
    if (! $doc){
        $c->detach('/error', [ 404, "No record for: $key" ]);
    }

    # If there is a canonical master, look for a suffix that
    # implies the file type we want and get it.
    if ($doc->{canonicalMaster}) {
        my($base, $suffix) = ($file =~ /(.*)\.(.*)/);
        if ($suffix) {
            $c->detach('get_derivative', [$doc, $suffix]);
        }
    }

    # If none of the above worked, the requested item is not available.
    warn("[debug] Couldn't find suitable file for $key\n");
    $c->detach( '/error', [ 404, "No suitable file for $key" ] );
}

sub download :Chained('/base') PartPath('/download') Args(2)
{
    my($self, $c, $key, $file) = @_;

    # Retrieve the record for the requested document. Verify that it
    # exists.
    my $solr = CAP::Solr->new($c->config->{solr});
    my $doc = $solr->document($key);
    if (! $doc){
        $c->detach( '/error', [ 404, "No record for: $key" ] );
    }

    # Prepare the file for download.
    if ($doc->{canonicalDownload} eq $file) {
        # Set the MIME type and size for the file.
        #my $content_type = "application/octet-stream";
        my $content_type = $doc->{canonicalDownloadMime};
        my $content_length = 0;
        $content_length = int( $doc->{size} ) if ( $doc->{size} );

        # Verify that the file exists.
        my $repos = Ingest->new($c->config->{content});
        my $file = $repos->get_fqfn($file, $doc->{contributor});
        if ( ! -f $file ) {
            $c->detach( '/error', [ 404, "No such file: $file" ] );
            return 1;
        }

        # Read the file
        if ( ! open( DATA, "<$file" )) {
            $c->detach( '/error', [ 500, "Opening $file: $!" ] );
            return 1;
        }
        my $content = join( "", <DATA> );
        close( DATA );

        # Output the file
        $c->res->content_length( $content_length );
        $c->res->content_type( $content_type );
        $c->res->status( 200 );
        $c->res->body ( $content );
        return 1;
    }

    $c->detach( '/error', [ 404, "No such record: $key" ] );
}


# This function is called by get() to do the actual work of generating and
# outputting the derivative image.
sub get_derivative :Private
{
    my ( $self, $c, $doc, $format ) = @_;

    # Default parameters
    my $content_type = "application/octet-stream";
    my $content_length = 0;
    my $content = "";
    my $rot = 0;
    my $size = $c->config->{defaults}->{image_size};

    # User-specified image size
    $size = $c->req->params->{s} if (
        $c->req->params->{s} &&
        $c->req->params->{s} !~ /[^0-9]/ &&
        int( $c->req->params->{s} ) >= $c->config->{defaults}->{image_min} &&
        int( $c->req->params->{s} ) <= $c->config->{defaults}->{image_max}
    );

    # User-specified image orientation
    $rot = $c->req->params->{r} % 4 if (
        $c->req->params->{r} &&
        $c->req->params->{r} !~ /[^0-9]/
    );

    # Determine the requested output format based on the supplied format
    # and verify that we can create the requested format.
    my $output = {
        png => { mime => 'image/png', netpbm => 'pnmtopng' },
        jpg => { mime => 'image/jpeg', netpbm => 'pnmtojpeg' },
    };
    if ( ! $output->{$format} ) {
        $c->detach( '/error', [ 404, "Unsupported format: $format" ] );
    }

    # Determine how to convert the source format and verify that we can
    # convert from that format.
    my $input = {
        'image/jpeg' => { netpbm => 'jpegtopnm' },
        'image/tiff' => { netpbm => 'tifftopnm' },
    };
    if ( ! $input->{$doc->{canonicalMasterMime}} ) {
        $c->detach( '/error', [ 500, "Source has no MIME type" ] );
    }

    # Verify that the master file exists.
    my $repos = Ingest->new($c->config->{content});
    my $file = $repos->get_fqfn($doc->{canonicalMaster}, $doc->{contributor});
    if ( ! -f $file ) {
        $c->detach( '/error', [ 404, "No such file: $file" ] );
        return 1;
    }

    # Find out if we already have a cached version of the requested object.
    my $cached_file = [ $c->model( 'DB::PimgCache' )->get_image( $doc->{key}, $format, $size, $rot ) ]->[ 0 ];

    # Use the cached file if there is one. Otherwise, try to find a usable
    # conversion routine.
    if ( $cached_file ) {
        $content = $cached_file->data;
        $content_type = $output->{$format}->{mime};
        $content_length = length( $content );
        $cached_file->update({ acount => $cached_file->acount + 1, atime => strftime( '%Y-%m-%d %H:%M:%S', localtime()) });
    }
    elsif ( $input->{$doc->{canonicalMasterMime}}->{netpbm} && $output->{$format}->{netpbm} )  {
        my $netpbm_path = $c->config->{netpbm_path};
        my @command = ();

        # Construct the NetPBM command pipeline
        push(@command, "$netpbm_path/" . $input->{$doc->{canonicalMasterMime}}->{netpbm} . " -quiet $file");
        push(@command, "$netpbm_path/pamscale -quiet -xsize $size -");
        if ($rot == 1) {
            push(@command, "$netpbm_path/pamflip -quiet -cw -");
        }
        elsif ($rot == 2) {
            push(@command, "$netpbm_path/pamflip -quiet -r180 -");
        }
        elsif ($rot == 3) {
            push(@command, "$netpbm_path/pamflip -quiet -ccw -");
        }
        push(@command, "$netpbm_path/" . $output->{$format}->{netpbm} . " -quiet -");
        my $command_pipeline = join(" | ", @command);
        warn("Executing command pipeline: $command_pipeline");
        $content = `$command_pipeline`;
        $content_type = $output->{$format}->{mime};
        $content_length = length( $content );

        # Make sure we got something.
        if ( ! $content_length ) {
            $c->detach( '/error', [ 500, "Empty file" ] );
        }

        # Cache our derivative image
        my $cached_file = $c->model('DB::PimgCache')->create( {
            id => $doc->{key},
            format => $format,
            size => $size,
            rot => $rot,
            data => $content,
            ctime => time(),
            acount => 1
        });
    }
    else {
        $c->detach('/error', [ 404, "Not found" ]);
    }

    # Output the file
    $c->res->content_length( $content_length );
    $c->res->content_type( $content_type );
    $c->res->status( 200 );
    $c->res->body ( $content );
    return 1;
}

1;
