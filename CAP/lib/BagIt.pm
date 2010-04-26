package BagIt;

use Archive::Tar;
use Digest::MD5 qw(md5_hex);
use Encode;
use File::Basename;
use File::Glob ('bsd_glob');

our $version = '0.20091130';

=head1 NAME

BagIt - module for manipulating BagIt archives

=head1 SYNOPSIS

    use BagIt;
    my $bagit = BagIt->new($root);
    $bagit->load($tarfile);

    foreach my $archive_file ($bagit->list()) {
        $bagit->extract($archive_file, $file_on_disk);
    }


=head1 DESCRIPTION

Library routines to create and read BagIt directories.

This library is still in development. Many methods are undocumented and
all are are subject to change without notice. The API is not yet frozen.

=head1 METHODS

=head2 BagIt->new([$root])

Creates a new, empty BagIt object. The $root argument specifies the name of the
BagIt directory root, and will also be used as the basename of the BagIt
tarfile itself. If no name is specified, "bagit" is used.

=cut

sub new
{
    my($self, $root) = @_;
    $root = "bagit" unless ($root);
    my $bag = {};
    $bag->{root} = $root;
    $bag->{bagit} = [ "BagIt Version 0.95", "Tag-File-Character-Encoding: UTF-8" ];
    $bag->{manifest_md5} = [];
    $bag->{bag_info} = [];
    $bag->{data} = [];
    $bag->{fetch} = [];
    $bag->{tar} = Archive::Tar->new();
    return bless($bag);
}

=head2 $bagit->load($tarfile)

Loads an existing BagIt archive from a possibly compressed tar archive
file. Returns 1 if the file is successfully loaded and validated;
otherwise, returns 0. This overwrites any existing data in the BagIt
archive, including the archive root.

=cut

sub load
{
    my($self, $file) = @_;
    my $tar = $self->{tar};
    my $root = $self->{root};
    if (! $tar->read($file)) {
        $! = "Could not read from archive";
        return 0;
    }
    $self->{bagit} = [split("\n", $tar->get_content("$root/bagit.txt"))];
    $self->{manifest_md5} = [split("\n", $tar->get_content("$root/manifest_md5.txt"))] if
        ($tar->contains_file("$root/manifest_md5.txt"));
    $self->validate() or return 0;
    return 1;
}

=head2 $bagit->list()

Returns an array of all of the files in the BagIt archive.

=cut

sub list
{
    my($self) = @_;
    return $self->{tar}->list_files();
}

=head2 $bagit->extract($archive_file, $file_on_disk)

Copies a file from the archive to the specified location on disk.

=cut

sub extract
{
    my($self, $file, $target) = @_;
    return $self->{tar}->extract_file($file, $target);
}

=head2 $bagit->add_file($file, $alias)

Adds $file to the archive's data directory as $alias. E.g.
add_file('/foo/bar', 'baz') will add the file /foo/bar as
$bagit_root/data/baz.

=cut

sub add_file
{
    my($self, $file, $alias) = @_;
    open(FILE, "<$file") or die("Cannot open '$src' for reading: $!");
    my $data = join("", <FILE>);
    close(FILE);
    my $md5 = md5_hex($data);
    my $path = "data/$alias";
    push(@{$self->{manifest_md5}}, "$md5  $path");
    $self->{tar}->add_data("$self->{root}/$path", $data);
}

=head2 $bagit->add_files($prefix, $root, @files)

Add @files, which are found under $root, to the archive under
data/$prefix. E.g. add_files('foo', '/bar', 'baz', 'quz') would add
/bar/baz and /abr/quz to the archive as data/foo/baz and data/foo/quz. If
@files containes a directory, its contents are recursively added.

=cut

sub add_files
{
    my($self, $prefix, $root, @files) = @_;
    foreach my $file (@files) {
        my $source_file = join('/', $root, $file);
        my $bagit_file = join('/', $prefix, $file);
        if (-d $source_file) {
            opendir(DIR, $source_file) or die("Cannot read from directory $source_file: $!");
            my @dirents = ();
            while (my $dirent = readdir(DIR)) {
                next if ($dirent eq '.' || $dirent eq '..');
                push(@dirents, $dirent);
            }
            closedir(DIR);
            $self->add_files($prefix, $source_file, @dirents);
        }
        elsif (-e $source_file) {
            $self->add_file($source_file, $bagit_file);
        }
        else {
            die("Source file $source_file does not exist");
        }
    }
}

=head2 $bagit->write_archive($path)

Write the bagit archive to a file under $path. The name of the file will
thus be $path/$bagit->{root}.tgz

=cut

sub write_archive
{
    my($self, $path) = @_;
    $path = "." unless ($path);
    my $root = $self->{root};
    my $tar = $self->{tar};

    $tar->add_data("$root/bagit.txt", encode_utf8(join("\n", @{$self->{bagit}})));

    $tar->add_data("$root/manifest-md5.txt", encode_utf8(join("\n", @{$self->{manifest_md5}}))) if @{$self->{manifest_md5}};
    $tar->add_data("$root/fetch.txt", encode_utf8(join("\n", @{$self->{fetch}}))) if @{$self->{fetch}};
    $tar->add_data("$root/bag-info.txt", encode_utf8(join("\n", @{$self->{bag_info}}))) if @{$self->{bag_info}};

    $self->{tar}->write("$path/$root.tgz", COMPRESS_GZIP);
}





###### Some of these methods are no longer needed and can be removed.
# Others are called by the methods above and need to be documented.




sub version
{
    my($self) = @_;
    return $1 if ($self->{bagit}->[0] =~ /^BagIt Version (\d+\.\d+)$/);
    return undef;
}

sub encoding
{
    my($self) = @_;
    return $1 if ($self->{bagit}->[1] =~ /^Tag-File-Character-Encoding: (\S+)$/);
    return undef;
}

sub validate
{
    my($self) = @_;
    foreach my $checksum (@{$self->{manifest_md5}}) {
        my ($digest, $file) = split(/\s+/, $checksum);
        my $md5 = md5_hex($self->{tar}->get_content($file));
        if ($digest ne $md5) {
            $! = "MD5 mismatch for file $file";
            return 0;
        }
    }
    return 1;
}

sub datafiles
{
    my($self) = @_;
    return grep(m!^\Q$self->{root}/data/!, $self->{tar}->list_files());
}

sub getfile
{
    my($self, $file) = @_;
    my $tar = $self->{tar};
    return $tar->get_content("$root/file") if ($tar->contains_file("$root/$file"));
    return undef;
}


sub addData
{
    my($self, $filepath, $data) = @_;
    my $md5 = md5_hex($data);
    my $path = "data/$filepath";
    push(@{$self->{manifest_md5}}, "$md5  $path");
    $self->{tar}->add_data("$self->{root}/$path", $data);

}


sub addFileAs
{
    my($self, $file, $alias) = @_;
    open(FILE, "<$file") or die("Cannot open '$src' for reading: $!");
    my $data = join("", <FILE>);
    close(FILE);
    my $md5 = md5_hex($data);
    my $path = "data/$alias";
    push(@{$self->{manifest_md5}}, "$md5  $path");
    $self->{tar}->add_data("$self->{root}/$path", $data);
}

# FIXME: should be called addFiles
sub addGlob
{
    my($self, $basedir, $glob) = @_;
    $basedir .= "/";
    warn($basedir);
    foreach my $file (bsd_glob("$basedir/$glob")) {
        my $path = substr($file, length($basedir));
        $self->addFile($basedir, $path);
    }
}

sub addFile
{
    my($self, $basedir, @files) = @_;

    foreach my $file (@files) {
        warn("$file");
        my $src = join("/", $basedir, $file);
        open(FILE, "<$src") or die("Cannot open '$src' for reading: $!");
        my $data = join("", <FILE>);
        close(FILE);
        my $md5 = md5_hex($data);
        my $path = "data/$file";
        $path =~ s#/+#/#g; # Fix any double slashes that end up in the path
        push(@{$self->{manifest_md5}}, "$md5  $path");
        $self->{tar}->add_data("$self->{root}/$path", $data);
    }
}

# TODO:
#sub addUrl
#{
#}

sub addInfo
{
    my($self, %info)  = @_;
    while (my($label, $content) = each(%info)) {
        $content =~ s/(.{1,79}\s+)/$1\n    /g; # Try to split long lines.
        push(@{$self->{bag_info}}, "$label: $content");
    }
}

1;

__END__

=head1 AUTHOR

William Wueppelmann E<lt>william.wueppelmann@canadiana.caE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Canadiana.org

This library is free software; you may redistribute and/or modify it under the same terms as Perl itself.

=cut
