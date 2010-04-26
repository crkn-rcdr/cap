package CAP::Profiler;
use strict;
use warnings;

use Carp;
use XML::LibXML;

sub new
{
    my($self, $dir) = @_;
    my $profiler = bless({});

    $profiler->{dir} = $dir;
    $profiler->{profiles} = {};
    $profiler->{parser} = XML::LibXML->new();

    opendir(PROF, $dir) or croak("Cannot open profile directory $dir: $!");
    while (my $file = readdir(PROF)) {
        $file = "$dir/$file";
        next unless $file =~ /\.xml$/;

        my $profile = $profiler->build_profile($file);

        my $name = $profile->findvalue('//profile/@name');
        $profiler->{profiles}->{$name} = $profile;
    }
    closedir(PROF);

    return $profiler;
}

sub profile
{
    my($self, $metadata) = @_;
    $self->{errors} = [];
    my $errors = 0;

    my $docno = 0;

    my @docs = $metadata->findnodes('//doc');

    foreach my $doc (@docs) {
        ++$docno;
        my $profile = $doc->findvalue('field[@name="type"]');

        if (! $self->{profiles}->{$profile}) {
            push(@{$self->{errors}}, ("Document $docno: invalid metadata profile: $profile\n"));
            ++$errors;
            next;
        }

        # Check for invalid fields in the source document.
        foreach my $field ($doc->findnodes('field')) {
            my $name = $field->getAttribute("name");
            $name =~ s/_..$//; # Remove language qualifiers from the end of the name
            if (! $self->{profiles}->{$profile}->findnodes("//field[\@name='$name']")) {

                # If we didn't find an exact match, see if we can find
                # a dynamic field match
                my $dmatch = 0;
                foreach my $dfield ($self->{profiles}->{$profile}->findnodes('//dynamicField')) {
                    my $dname = $dfield->getAttribute('name');
                    if (substr($dname, -1, 1) eq '*') {
                        chop($dname);
                        if ($name =~ /^$dname/) {
                            $dmatch = 1;
                            last;
                        }
                    }
                    elsif (substr($dname, 1, 1) eq '*') {
                        $dname = substr($dname, 1);
                        if ($name =~ /$dname$/) {
                            $dmatch = 1;
                            last;
                        }
                    }
                }
                next if ($dmatch);
                
                #push(@{$self->{errors}}, ("Document $docno ($profile): field '$name' is not allowed: " . encode_utf8($field->toString(1)) . "\n"));
                push(@{$self->{errors}}, ("Document $docno ($profile): field '$name' is not allowed: " . $field->toString(1) . "\n"));
                ++$errors;
            }
        }

        # Check for missing required fields.
        foreach my $field ($self->{profiles}->{$profile}->findnodes('//field[@required="true"]')) {
            my $name = $field->getAttribute("name");
            if (! $doc->findnodes("field[\@name='$name']")) {
                push(@{$self->{errors}}, ("Document $docno ($profile): missing required field '$name'\n"));
                ++$errors;
            }
        }
            
        # Check for multiple instances of non-multivalued fields.
        foreach my $field ($self->{profiles}->{$profile}->findnodes('//field')) {
            my $multi = $field->getAttribute('multiValued') || "";
            next if ($multi eq 'true');
            my $name = $field->getAttribute("name");
            my @nodes = $doc->findnodes("field[\@name='$name']");
            if (int(@nodes) > 1) {
                push(@{$self->{errors}}, ("Document $docno ($profile): multiple instances of non-multivalued field '$name':\n"));
                foreach my $node (@nodes) {
                    #push(@{$self->{errors}}, ("  " . decode_utf8($node->toString(1)) . "\n"));
                    push(@{$self->{errors}}, ("  " . $node->toString(1) . "\n"));
                }
                ++$errors;
            }
        }
    }

    return 0 if($errors);
    return 1;
}

sub errors
{
    my($self) = @_;
    return $self->{errors};
}

sub build_profile
{
    my($self, $file) = @_;
    my $main = $self->{parser}->parse_file($file);
    my $profile = XML::LibXML::Document->new();
    $profile->setEncoding('utf8');
    $profile->setDocumentElement($main->findnodes("//profile")->[0]->cloneNode());
    $self->parse_profile($main, $profile);
    return $profile;
}

sub parse_profile
{
    my($self, $dom, $profile) = @_;
    foreach my $node ($dom->findnodes("//profile/*")) {
        if ($node->nodeName() eq 'include') {
            $self->parse_profile($self->{parser}->parse_file($self->{dir} . "/" . $node->getAttribute("file")), $profile);
            next;
        }

        $profile->adoptNode($node);

        # Only the first description found is used.
        if ($node->nodeName eq "desc") {
            if (! $profile->findvalue("//profile/desc")) {
                $profile->documentElement()->appendChild($node);
            }
        }

        # Overwrite any field declarations with any that occur later in
        # the document. This means that the location of <include> elements
        # is important. However, all descriptions are catenated.
        if ($node->nodeName eq "field"|| $node->nodeName eq "dynamicField" ) {
            my $name = $node->getAttribute("name");
            my $field = $profile->findnodes("//profile/" . $node->nodeName . "[\@name='$name']")->[0];
            if ($field) {
                my $text = $field->textContent();
                $node->appendChild($profile->createTextNode($text));
                $field->replaceNode($node);
            }
            else {
                $profile->documentElement()->appendChild($node);
            }
        }
    }
}

1;
