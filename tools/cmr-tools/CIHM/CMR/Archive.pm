package CIHM::CMR::Archive;

=head1  NAME

CIHM::CMR::Archive

=head1 SYNOPSIS

Archive querying and management routines for a CMR repository.

=head1 FUNCTIONS

=cut

use strict;
use warnings;
use Cwd;
use Digest::MD5 qw(md5_hex);
use Encode;
use File::Find;
use POSIX qw(strftime);
use Perl6::Slurp;

use Exporter qw(import);
our @EXPORT = qw(
    bagit
    find_archive
    find_archives
    find_cmr_records
);


=head2 bagit(I<$archive>)

Creates a bagit.txt bag-info.txt and manifest in I<$archive> for the contents of I<$archive>/data.

=cut
sub bagit
{
    my($archive) = @_;

    # bagit.txt and bag-info.txt file contents
    my $bagit = "BagIt-Version: 0.96\nTag-File-Character-Encoding: UTF-8\n";
    my $baginfo = "Source-Organization: Canadiana.org\nBagging-Date: " . strftime("%Y-%m-%d", localtime()) . "\n";

    my $cwd = getcwd();
    die("$archive is not a directory.\n") unless (-d $archive);
    die("$archive is missing a data subdirectory.\n") unless (-d "$archive/data");
    chdir($archive);

    # Create the BagIt declaration and metadata files.
    open(BAGIT, ">bagit.txt") or die("Cannot create bagit.txt: $!\n");
    print(BAGIT encode_utf8($bagit));
    close(BAGIT);
    open(BAGIT, ">bag-info.txt") or die("Cannot create bagit.txt: $!\n");
    print(BAGIT encode_utf8($baginfo));
    close(BAGIT);

    # Generate MD5 digests for all of the files under ./data
    open(MD5, ">manifest-md5.txt") or die("Cannot create manifest-md5.txt: $!\n");
    my $md5_fh = *MD5;
    find(
        sub {
            my $file = $File::Find::name;
            if (-f $_) {
                my $digest = md5_hex(slurp($_));
                print($md5_fh "$digest  $file\n");
            }
        },
        'data'
    );
    close(MD5);

    chdir($cwd);
    return 1;
}

=head2 find_archive(I<$root>, I<$archive>)

Finds the Bagit archive located under I<$root> with the name I<$archive>
and returns a path to it, or undef if no such archive is found. If
multiple I<$archive> directories exist under I<$root>, the first one found
(essentially at random) will be returned.

=cut
sub find_archive
{
    my($path, $archive) = @_;
    opendir(DIR, $path) or die("Cannot read directory $path: $!\n");
    my @contents = readdir(DIR);
    closedir(DIR);
    foreach my $dirent (@contents) {
        next if (substr($dirent, 0, 1) eq '.');
        my $subdir = join('/', $path, $dirent);
        if (-d $subdir) {
            if ($dirent eq $archive) {
                return $subdir;
            }
            elsif (! -f join('/', $subdir, 'bagit.txt')) {
                my $found = find_archive($subdir, $archive);
                return $found if (defined($found));
            }
        }
    }
    return undef;
}


=head2 find_archives(I<$path>)

Generate a list of all bagit archive roots found under I<$path> and
returns them as a list. Bagit archives within other Bagit archives will
not be found.

=cut
sub find_archives
{
    my($path, $archives) = @_;
    $archives = [] if (! $archives);
    opendir(DIR, $path) or die("Cannot read directory $path: $!\n");
    while (my $dirent = readdir(DIR)) {
        next if (substr($dirent, 0, 1) eq '.');
        my $dir = join('/', $path, $dirent);
        if (-d $dir) {
            if (-f join('/', $dir, 'bagit.txt')) {
                push(@{$archives}, $dir);
            }
            else {
                find_archives($dir, $archives);
            }
        }
    }
    closedir(DIR);
    return @{$archives};
}

=head2 find_cmr_records(I<$path>)

Returns a list of all CMR metadata records under the Bagit archive at
I<$path>. (I<$path>/data/*.xml)

=cut
sub find_cmr_records
{
    my($archive) = @_;
    my $path = join('/', $archive, 'data');
    my @cmr = ();
    opendir(DIR, $path) or die("Cannot read directory $path: $!\n");
    while (my $dirent = readdir(DIR)) {
        next if (substr($dirent, 0, 1) eq '.');
        push(@cmr, join('/', $path, $dirent)) if ($dirent =~ /\.xml$/);
    }
    close(DIR);
    return @cmr;
}

1;
