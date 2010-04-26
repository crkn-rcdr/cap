package CAP::Controller::Content;

use strict;
use warnings;
use parent 'Catalyst::Controller';
use BagIt;
use CAP::Profiler;
use Digest::MD5;
use File::Basename;
use File::Copy;
use File::Path;
use File::Glob ':glob';
use File::MimeInfo::Magic;
use XML::LibXML;

sub validate_contributor :Private
{
    my($self, $c, $contributor) = @_;
    unless (exists($c->stash->{pconf}->{contributor}->{$contributor})) {
        $c->detach('/error', [409, "invalid contributor code: $contributor"]);
    }
}

#sub index : Chained('/base') PathPart('content') Args(0)
#{
#    my($self, $c) = @_;
#    $c->stash->{template} = 'content/index.tt';
#    return 1;
#}

sub commit : Chained('/base') PathPart('content/commit') Args(0)
{
    my($self, $c) = @_;
    $c->stash->{template} = "admin/commit.tt";
    my $solr = CAP::Solr->new($c->config->{solr});
    my $response = $solr->update("<commit/>");
    $c->detach('/error', [500, "commit failed ($response->{error})"]) unless ($response->{ok});
    $c->stash->{response} = $response;
    return 1;
}

sub cleanup : Chained('/base') PathPart('content/cleanup') Args(1)
{
    my($self, $c, $contributor) = @_;
    $c->forward('validate_contributor',  [$contributor]);
    $c->stash->{cc} = $contributor;
    $c->stash->{contributor} = $c->config->{Contributors}->{$contributor} || "";
    $c->stash->{template} = "admin/cleanup.tt";
    my $dir = join('/', $c->config->{root}, $c->config->{uploads}, $contributor);
    if (-e $dir) {
        if (! rmtree($dir)) {
            $c->detach('/error', [500, "Failed to remove '$dir': $!"]);
        }
    }
    return 1;
}

=head2 upload

    Upload a file for ingestion
=cut
sub upload : Chained('/base') PathPart('content/upload') Args(0)
{
    my($self, $c) = @_;
    my $file = $c->request->upload('file');
    my $contributor = $c->request->params->{contributor};

    $c->forward('validate_contributor',  [$contributor]);

    # A file upload is required.
    $c->detach('/error', [400, 'no file supplied']) unless ($file);

    # Disallow any file that contains a '/' in its name.
    $c->detach('/error', [400, "illegal characters in file name '" . $file->filename . "'"]) if ($file->filename =~ m#[/]#);

    # Store the file name, a pointer to the file itself, and the file's
    # MIME type
    #$c->stash->{file} = $file;
    my $filename = $c->stash->{filename} = $file->filename;
    my $format = $c->stash->{format} = mimetype($file->tempname);

    warn("[info] Uploaded file \"" . $c->stash->{filename} . "\" has format \"$format\"\n");

    if ($format eq 'application/xml') {
        $c->stash->{contributor} = $contributor;
        $c->forward('ingest_metadata', [$file->tempname, $file->filename]);
        return 1;
    }

    # Process an individual object whose MIME type we understand.
    if (exists($c->config->{MimeTypes}->{$format})) {
        $c->stash->{contributor} = $contributor;
        $c->forward('ingest_object', [$file->tempname, $file->filename]);
        return 1;
    }

    # Treat this as a BagIt archive. Unpack and validate it.
    my %bagit_types = (
        'application/x-gzip' => 1,
        'application/x-compressed-tar' => 1,
    );
    if ($bagit_types{$format}) {
        my @log = ();

        # Find the BagIt root directory (everything up to the first "." in the file name)
        my $root = $filename;
        $root =~ s/(\.tgz)$//;
        #my($root) = ($filename =~ /([^\.]+)/);
        $c->detach('/error', [500, "cannot determine BagIt root directory from file name '$filename'"]) unless ($root ne $filename);

        warn("[debug] BagIt root is \"$root\"\n");

        # Open the BagIt archive and load it into memory.
        my $bagit = BagIt->new($root);
        $c->detach('/error', [500, "cannot not open BagIt archive in '$filename' ($$!)"]) unless $bagit->load($file->tempname);

        # Create a destination directory for the archive and save it.
        my $upload_dir = join('/', $c->config->{root}, $c->config->{uploads}, $contributor);
        if (! -d $upload_dir) {
            $c->detach('/error', [500, "cannot not create upload directory '$upload_dir' ($!)"]) unless (mkdir($upload_dir));
        }

        # If a BagIt archive with the same name already exists, remove it.
        if (-e "$upload_dir/$root") {
            $c->detach('/error', [500, "cannot remove existing directory '$upload_dir/$root' ($!)"]) unless
                (rmtree("$upload_dir/$root"));
        }

        # Extract the files and build an ingest list of all files in the data/metadata and data/objects directories.
        $c->stash->{bagit_files} = [];
        foreach my $file ($bagit->list()) {
            $c->detach('/error', [500, "cannot extract file '$file' from archive ($!)"]) unless
                $bagit->extract($file, join('/', $upload_dir, $file));

            warn("[debug] Found file in BagIt archive: \"$file\"\n");
            push(@{$c->stash->{bagit_files}}, $file) if ($file =~ m#/data/(metadata|objects)/[^/]+#);
        }

        $c->stash->{contributor} = $contributor;
        $c->stash->{template} = "admin/bagit_upload.tt";
        return 1;
    }

    # If we get this far, it means we don't know how to process this kind of file.
    $c->detach('/error', [500, "don't know how to handle file '$filename' with MIME type '$format'"]);
}

sub ingest : Chained('/base') PathPart('content/ingest') Args(0)
{
    my($self, $c) = @_;
    my $file = $c->request->params->{file};

    my $contributor = $c->request->params->{contributor};
    $c->forward('validate_contributor',  [$contributor]);
    $c->stash->{contributor} = $contributor;

    # Make sure the supplied filename doesn't include any '..'s in the path.
    $c->detach('/error', [500, 'missing file parameter']) unless ($file);
    $c->detach('/error', [500, 'illegal characters in filename']) if ($file =~ /^\.\.\// || $file =~ /\/\.\.\// || $file =~ /\/\.\.$/);
    my $filename = join('/', $c->config->{root}, $c->config->{uploads}, $contributor, $file);
    $c->detach('/error', [500, "file '$filename' does not exist"]) unless (-f $filename);

    # Detach to the appropriate handler based on the location of the file
    # within the BagIt archive.
    my ($subdir) = ($filename =~ /.*\/(.*)\//);
    if ($subdir eq 'metadata') {
        $c->detach('ingest_metadata', [$filename, basename($filename)]);
    }
    elsif ($subdir eq 'objects') {
        $c->detach('ingest_object', [$filename, basename($filename)]);
    }
    # Allow other subdirectories, but ignore them.
    #else {
    #    $c->detach('/error', [500, "expecting subdirectory name to be 'metadata' or 'objects', not '$subdir'"]);
    #}
}

sub ingest_metadata : Private
{
    my($self, $c, $filename, $upload_name) = @_;
    my $format = mimetype($filename);

    # Verify the MIME type is correct.
    $c->detach('/error', [500, "don't know how to process metadata file '$filename' with MIME type '$format'"]) unless
        ($format eq 'application/xml');

    # Parse the XML
    my $parser = XML::LibXML->new();
    my $xml;
    eval { $xml = $parser->parse_file($filename) };
    $c->detach('/error', [500, "parsing of '$filename' failed ($@)"]) if ($@);
    
    # Verify that all documents match valid application profiles.
    my $profiler = CAP::Profiler->new($c->config->{profiles});
    if (! $profiler->profile($xml)) {
        $c->stash->{'log'} = $profiler->errors;
        $c->detach('/error', [409, "Profiling '$upload_name' failed"]);
    }

    # TODO: check for circular pkey references, inherit gkeys from the parent,
    # propagate gkeys to children, validate all key, gkey, pkey
    # references. gkeys cannot refer to themselves.

    # Check each document for invalid keys.
    my $namespace = $c->stash->{contributor};
    foreach my $doc ($xml->findnodes('*//doc')) {

        my $key = $doc->findvalue('field[@name="key"]');
        $c->detach('/error', [409, "found key in '$upload_name' missing required namespace prefix '$namespace': $key"])
            #unless (CORE::index($key, "$namespace:") == 0);
            unless (CORE::index($key, "$namespace.") == 0);
        $c->detach('/error', [409, "found key in '$upload_name' with invalid key: $key"])
        #    unless ($key =~ /^$namespace\:[\w\:\._-]+$/);
             #unless ($key =~ /^$namespace\:[A-Za-z0-9_\:\@\&\=\+\$\.\!\~\*\'\(\)\-]+$/);
             unless ($key =~ /^$namespace\.[A-Za-z0-9_\:\@\&\=\+\$\.\!\~\*\'\(\)\-]+$/);

        my $pkey = $doc->findvalue('field[@name="pkey"]');
        if ($pkey) {
            $c->detach('/error', [409, "found pkey in '$upload_name' missing required namespace prefix '$namespace': $pkey"])
                #unless (CORE::index($pkey, "$namespace:") == 0);
                unless (CORE::index($pkey, "$namespace.") == 0);
            $c->detach('/error', [409, "found pkey in '$upload_name' with invalid key: $pkey"])
            #    unless ($pkey =~ /^$namespace\:[\w\:\._-]+$/);
                 #unless ($key =~ /^$namespace\:[A-Za-z0-9_\:\@\&\=\+\$\.\!\~\*\'\(\)\-]+$/);
                 unless ($key =~ /^$namespace\.[A-Za-z0-9_\:\@\&\=\+\$\.\!\~\*\'\(\)\-]+$/);
        }

    }


    my $solr = CAP::Solr->new($c->config->{solr});
    my $response = $solr->update($xml->toString(0));
    $c->detach('/error', [500, "Solr index call failed ($response->{error})"]) unless ($response->{ok});

    # Commit the changes unless the nocommit option was specified.
    $c->forward('commit') unless ($c->request->params->{nocommit});

    $c->stash->{template} = 'admin/ingest_meta.tt';
    return 1;
}

sub ingest_object : Private
{
    my($self, $c, $filename, $key) = @_;

    # Make sure the object's type is supported.
    my $format = mimetype($filename);
    $c->detach('/error', [500, "File '$filename' has unsupported MIME type: $format"]) unless
        exists($c->config->{MimeTypes}->{$format});

    # Treat the filename as the unique key. Make sure that the filename
    # begins with the contributor code.
    my $prefix = $c->stash->{contributor} . ".";
    $c->detach('/error', [409, "filename '$key' missing required prefix '$prefix'"]) unless
        (CORE::index($key, $prefix) == 0);

    # Assign a unique key to this object based on its filename up to the first '.'
    #my $key = join(':', $c->stash->{contributor}, (fileparse($filename, qr/\..*/))[0]);
    #$key =~ s/[^\w:-]/_/g;

    # Create a subdirectory within the repository to store the object and
    # copy the object into that directotry.
    my @time = localtime(time());
    my $root = join("/", $c->config->{root}, $c->config->{repository});
    my $date = sprintf("%04d%02d%02d", $time[5] + 1900, $time[4] + 1, $time[3]);
    my $repository = join("/", $root, $date);
    if (! -d $repository) {
        $c->detach('/error', [500, "cannot create directory '$repository' ($!)"]) unless (mkdir($repository));
    }
    my $object_file = join('/', $repository, $key);
    $c->detach('/error', [500, "failed to copy '$filename' to '$object_file' ($!)"]) unless (copy($filename, $object_file));

    # Check whether there is an existing record for this object.
    my $master = [$c->model('DB::MasterImage')->get_image($key)]->[0];

    if ($master) {
        my $old_object = join('/', $root, $master->path, $master->id);

        # Delete the old object if it was stored in a different place from
        # the new version. We allow this to silently fail if there is a
        # problem removing the old object; it does no harm to keep it
        # around other than wasting space. Try to remove the object's
        # containing directory as well, if we can.
        unlink($old_object) if (-f $old_object && $old_object ne $object_file);
        rmdir(dirname($old_object));
        $master->delete();
    }

    # Generate an MD5 digest for the object.
    my $md5 = Digest::MD5->new();
    $c->detach('/error', [500, "cannot open '$object_file' to create MD5 sum ($!)"]) unless (open(SRC, "<$object_file"));
    $md5->addfile(*SRC);
    close(SRC);

    # Determine the object's file size
    my @stat = stat($object_file);
    $c->detach('/error', [500, "cannot stat '$object_file' ($!)"]) unless (@stat);

    $master = $c->model('DB::MasterImage')->create({
        id => $key,
        path => $date,
        format => $format,
        ctime => time(),
        bytes => $stat[7],
        md5 => $md5->hexdigest,
    });

    $c->stash->{key} = $key;
    $c->stash->{template} = 'admin/ingest_object.tt';
    return 1;
}

1;
