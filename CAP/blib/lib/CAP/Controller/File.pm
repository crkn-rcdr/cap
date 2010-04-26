package CAP::Controller::File;

use strict;
use warnings;
use parent 'Catalyst::Controller';

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
    my($self, $c, $id) = @_;

    # Verify that the requested master image exists and retrieve its info.
    my $master = [$c->model('DB::MasterImage')->get_image($id)]->[0];
    if (! $master) {
        $c->response->body("No such item: $id");
        $c->response->status(400);
        return 1;
    }

    my $mime_type = $master->format;
    my $master_root = join("/", $c->config->{root}, $c->config->{repository});
    my $master_file = join("/", $master_root, $master->path, $master->id);
    if (! open(IMAGE, "<$master_file")) {
        $c->response->body("Read file error: $master_file");
        $c->response->status(500);
        return;
    }
    my $image_data = join("", <IMAGE>);
    close(IMAGE);

    # Output the image.
    $c->response->content_length(length($image_data));
    $c->response->content_type($mime_type);
    $c->response->status(200);
    $c->response->body($image_data);
    return 1;
}

sub file :Chained('/base') PartPath('/file') Args(1)
{
    my($self, $c, $filename) = @_;
    my $size = $c->request->params->{s} || 0;
    my $rot = $c->request->params->{r} || 0;
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

    # Output the image.
    $c->response->content_length(length($image_data));
    $c->response->content_type($mime_type);
    $c->response->status(200);
    $c->response->body($image_data);
    return 1;
}


=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
