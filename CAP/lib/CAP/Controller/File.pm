package CAP::Controller::File;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use POSIX qw( strftime );

=head1 NAME

CAP::Controller::File - Catalyst Controller

=head1 DESCRIPTION

Retrieve digital objects

=head1 METHODS

=cut


=head2 index

=cut

sub get :Chained('/base') PartPath('/get') Args(1)
{
    my( $self, $c, $key ) = @_;
    my $suffix = "";

    # Retrieve the record for the requested document. Verify that it
    # exists. If not, strip the suffix and see if that record exists.
    my $solr = CAP::Solr->new($c->config->{solr});
    my $doc = $solr->document($key);

    # If this is a downloadable resource, serve it to the requester.
    if ( $doc && $doc->{type} eq 'resource' && $doc->{role} eq 'download' && $doc->{file} ) {
        $c->detach( 'get_download', [ $doc ] );
    }

    # Strip away the final suffix and see if the resulting record  exists.
    # Try to get a derivative image based on the suffix type.
    ( $key, $suffix ) = ( $key =~ /(.*)\.(.*)/ );
    warn("[debug]: Trying to find resource $key to create $suffix file\n");
    $doc = $solr->query_first( { key => $key, type => 'resource', role => 'master' } );
    if ( $doc && $doc->{file} ) {
        $c->detach( 'get_derivative', [ $doc, $suffix ] );
    }

    # If none of the above worked, the requested item is not available.
    warn("[debug] Couldn't find suitable file for $key\n");
    $c->detach( '/error', [ 404 ] );
}

sub get_download :Private
{
    my ( $self, $c, $doc ) = @_;

    # Set the MIME type and size for the file.
    my $content_type = "application/octet-stream";
    $content_type = $doc->{mime} if ( $doc->{mime} );
    my $content_length = 0;
    $content_length = int( $doc->{size} ) if ( $doc->{size} );

    # Get the resource file name and make sure it exists
    my $file = join( '/', $c->forward( '/common/repos_path', [ $doc ] ), $doc->{file} );
    warn("[debug] Downloading file \"$file\"\n");
    if ( ! -f $file ) {
        $c->detach( '/error', [ 404 ] );
        return 1;
    }

    # Read the file
    if ( ! open( DATA, "<$file" )) {
        $c->detach( '/error', [ 500 ] );
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
        $c->detach( '/error', [ 404 ] );
    }

    # Determine how to convert the source format and verify that we can
    # convert from that format.
    my $input = {
        'image/jpeg' => { netpbm => 'jpegtopnm' },
        'image/tiff' => { netpbm => 'tifftopnm' },
    };
    if ( ! $input->{$doc->{mime}} ) {
        $c->detach( '/error', [ 500 ] );
    }

    # Verify that the master file exists.
    my $file = join( '/', $c->forward( '/common/repos_path', [ $doc ] ), $doc->{key} );
    if ( ! -f $file ) {
        $c->detach( '/error', [ 404 ] );
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
    elsif ( $input->{$doc->{mime}}->{netpbm} && $output->{$format}->{netpbm} )  {
        my $netpbm_path = $c->config->{netpbm_path};
        my @command = ();

        # Construct the NetPBM command pipeline
        push(@command, "$netpbm_path/" . $input->{$doc->{mime}}->{netpbm} . " -quiet $file");
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
            $c->detach( '/error', [ 500 ] );
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
        $c->detach( '/error', [ 404 ] );
    }

    # Output the file
    $c->res->content_length( $content_length );
    $c->res->content_type( $content_type );
    $c->res->status( 200 );
    $c->res->body ( $content );
    return 1;
}



#### DEPRECATED:

sub file :Chained('/base') PartPath('/file') Args(1)
{
    my($self, $c, $filename) = @_;
    my $size = $c->req->params->{s} || 0;
    my $rot = $c->req->params->{r} || 0;
    my $cache = 0; $cache = 1 if ($c->req->params->{c});
    my($id, $format, $image_data, $mime_type);

    # This is a table of the output formats we support. For each one,
    # we...
    # TODO: describe what's in the table
    my %output = (
        'png' => { mime => 'image/png', pnm => 'pnmtopng' },
        'pdf' => { mime => 'application/pdf' },
    );

    # This table describes how to deal with the various source formats.
    my %src = (
        'application/pdf' => { mime => 'application/pdf' }, 
        'image/jpeg' => { pnm => 'jpegtopnm' },
        'image/tiff' => { pnm => 'tifftopnm' },
    );

    # Split $filename into a base part and a suffix part and verify that
    # the output format is supported.
    $filename =~ /(.*)\.(.*)/;
    ($id, $format) = ($1, $2);
    unless ($id && $format) {
        $c->response->body("Invalid filename: $filename");
        $c->response->status(400);
        return 1;
    }
    unless(exists($output{$format})) {
        $c->response->body("Unsupported output format: $format");
        $c->response->status(400);
        return 1;
    }

    # Verify that the requested master image exists and retrieve its info.
    my $master = [$c->model('DB::MasterImage')->get_image($id)]->[0];
    if (! $master) {
        $c->response->body("No such item: $id");
        $c->response->status(400);
        return 1;
    }
    
    # If we can create derivatives using NetPBM:
    if ($src{$master->format}->{pnm} && $output{$format}->{pnm}) {
        # TODO: a minimum and maximum size should be specified. Probably in
        # the range of 50 - 1500.
        $size = $c->config->{Display}->{imgsize} unless ($size);
        $size = int($size);
        if ($size < 1) {
            $c->response->body("Invalid size: $size");
            $c->response->status(400);
            return 1;
        }
        $rot  = 0 unless ($rot);
        $rot  = $rot % 4;

        # Determine whether a matching derivative exists.  If it does, but
        # is older than the master, delete it
        my $derivative = [$c->model('DB::PimgCache')->get_image($id, $format, $size, $rot)]->[0];
        if ($derivative) {
            warn("[debug] Master image was modified at " . $master->ctime . "; derivative at " . $derivative->ctime . "\n") if ($c->config->{debug});
            if ($master->ctime > $derivative->ctime) {
                warn("[info] Derivative \"$id-$format-$size-$rot\" is older than its master file; it will be deleted\n");
                $derivative->delete();
                undef($derivative);
            }
        }


        # If the requested derivative (still) exists, use it. Otherwise,
        # create a new derivative.
        if ($derivative) {
            #$mime_type = $output{$format}->{mime};
            $mime_type = $derivative->format;
            $image_data = $derivative->data;
            my @time = time();
            $derivative->update({
                acount => $derivative->acount + 1,
            });
        }
        else {
            warn("Derivative image for $id-$format-$size-$rot does not exist. Will have to create");
            my $netpbm_path = $c->config->{netpbm_path};
            my $master_root = join("/", $c->config->{root}, $c->config->{repository});
            warn "Using image root $master_root";
            my @command = ();

            my $master_file = join("/", $master_root, $master->path, $master->id);
            if (! -r $master_file) {
                $c->response->body("Read file error: $master_file");
                $c->response->status(500);
                return;
            }

            # Get the base command to create the netpbm image.
            push(@command, "$netpbm_path/" . $src{$master->format}->{pnm} . " -quiet $master_file");

            # Scale the image
            push(@command, "$netpbm_path/pamscale -quiet -xsize $size -");
            
            # Rotate the image, if $rot is nonzero.
            if ($rot == 1) {
                push(@command, "$netpbm_path/pamflip -quiet -cw -");
            }
            elsif ($rot == 2) {
                push(@command, "$netpbm_path/pamflip -quiet -r180 -");
            }
            elsif ($rot == 3) {
                push(@command, "$netpbm_path/pamflip -quiet -ccw -");
            }

            push(@command, "$netpbm_path/" . $output{$format}->{pnm} . " -quiet -");
            my $cmd_pipeline = join(" | ", @command);
            warn("Executing command pipeline: $cmd_pipeline");
            $image_data = `$cmd_pipeline`;
            $mime_type = $output{$format}->{mime};

            $derivative = $c->model('DB::PimgCache')->create({
                id => $master->id,
                format => $format,
                size => $size,
                rot => $rot,
                data => $image_data,
                ctime => time(),
                acount => 1
            });
            if (! $derivative) {
                $c->response->body("Error creating ");
                $c->response->status(500);
                return;
            }

        }
    }
    # Otherwise, the output format has to match the source format. Pass
    # the master file through directly.
    elsif ($output{$format}->{mime} eq $master->format) {
        $mime_type = $master->format;
        my $master_root = join("/", $c->config->{root}, $c->config->{repository});
        my $master_file = join("/", $master_root, $master->path, $master->id);
        if (! open(IMAGE, "<$master_file")) {
            $c->response->body("Read file error: $master_file");
            $c->response->status(500);
            return;
        }
        $image_data = join("", <IMAGE>);
        close(IMAGE);
    }
    else {
        $c->response->body("Cannot generate output type " . $output{$format}->{mime} . " from source format " . $master->format);
        $c->response->status(400);
        return 1;
    }

    # Output the image, or a status message if this is a cache-only
    # request.
    if ($cache) {
        $c->stash->{template} = "file.tt";
    }
    else {
        $c->res->content_length(length($image_data));
        $c->res->content_type($mime_type);
        $c->res->status(200);
        $c->res->body($image_data);
    }
    return 1;
}


=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
