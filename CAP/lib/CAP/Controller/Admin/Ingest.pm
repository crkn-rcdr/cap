package CAP::Controller::Admin::Ingest;
use Moose;
use namespace::autoclean;
use CAP::Profiler;
use Digest::MD5 qw( md5_hex );
use File::Path qw( make_path );
use XML::LibXML;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Admin::Ingest - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub content :Private
{
    my ( $self, $c ) = @_;
    my $data;

    # Get the file data
    if ( $c->stash->{file} ) {
        $data = \$c->stash->{file};
    }
    elsif ( $c->stash->{data} ) {
        $data = \$c->stash->{data};
    }
    else {
        $c->stash( error => 'NODATA' );
        return 1;
    }

    # Verify that the key looks valid.
    if ( $c->stash->{key} =~ /[^A-Za-z0-9_\.-]/ ) {
        $c->stash( error => 'INVALID', debug => 'Illegal characters in key' );
        return 1;
    }

    # Make sure that a record for this object exists and that the
    # contributor namespace is authorized for this portal.
    my $solr = CAP::Solr->new( $c->config->{solr} );
    my $doc = $solr->document( $c->stash->{key} );
    if ( ! $doc ) {
        $c->stash ( error => 'NORECORD' );
        return 1;
    }
    if ( ! $c->config->{contributor}->{$doc->{contributor}} ) {
        $c->stash ( error => 'INVALID', debug => 'Key has unauthorized contributor namespace' );
        return 1;
    }

    # Check that this is the correct type of record.
    if ( ! $doc->{type} || $doc->{type} ne 'resource' ) {
        $c->stash ( error => 'INVALID', debug => sprintf( 'Record "%s" has incorrect type: "%s"', $c->stash->{key}, $doc->{type} ));
        return 1;
    }

    # Check that the data contains the correct MD5 sum
    if ( ! md5_hex( ${$data} )) {
        $c->stash( error => 'INVALID', debug => 'MD5 mismatch' );
    }
    
    # Remove all pre-existing cached derivatives from the database.
    $c->model( 'DB::PimgCache' )->delete_derivatives( $doc->{key} );

    # Create a subdirectory tree using a standardized algorithm to put
    # files in predictable places and keep directory sizes reasonable:
    my $path = $c->forward( '/common/repos_path', [ $doc ] );
    if ( ! -d $path && ! make_path( $path )) {
        $c->stash( error => 'FILEOP', debug => "make_path $path: $!" );
        return 1;
    }

    # Write the file.
    if ( ! open( FILE, ">$path/" . $c->stash->{key} ) ) {
        $c->stash( error => 'FILEOP', debug => "open: $!" );
        return 1;
    }
    if ( ! print( FILE ${$data} )) {
        $c->stash( error => 'FILEOP', debug => "print: $!" );
        return 1;
    }
    close( FILE );

    return 1;
}

sub metadata :Private
{
    my ( $self, $c ) = @_;
    my $xml = XML::LibXML->new();
    my $add;

    # Parse the XML record.
    if ( $c->stash->{file} ) {
        eval { $add = $xml->parse_string( $c->stash->{file} ) };
    }
    elsif ( $c->stash->{data} ) {
        eval { $add = $xml->parse_string( $c->stash->{data} ) };
    }
    else {
        $c->stash( error => 'NODATA' );
        return 1;
    }

    if ( $@ ) {
        $c->stash( error => 'NOPARSE', debug => $@ );
        return 1;
    }
    
    # Profile each document to make sure it has a valid type and conforms
    # to that type's requirements.
    my $profiler = CAP::Profiler->new( $c->config->{profiles} );
    if (! $profiler->profile( $add )) {
        $c->stash( error => 'BADPROFILE', debug => join( "\n", @{$profiler->errors} ));
        return 1;
    }

    # Check for invalid identifiers and invalid contributors.
    my @errors = ();
    foreach my $doc ($add->findnodes( '/add/doc' )) {

        # Each document must have a valid contributor namespace, and the portal
        # must be configured to accept content from that contributor.
        my $contributor = $doc->findvalue( 'field[@name="contributor"]' );
        if ( ! $contributor ) {
            push( @errors, "Found document with no contributor" );
            next;
        }
        elsif ( $contributor =~ /[^\w]/ ) {
            push( @errors, "Found document with invalid contributor name: \"$contributor\"" );
            next;
        }
        elsif ( ! $c->config->{contributor}->{$contributor} ) {
            push( @errors, "Found document with unauthorized contributor: \"$contributor\"" );
            next;
        }

        # The key, and any pkey or gkeys must contain legal values and
        # must begin with the contributor code.
        foreach my $key ( $doc->findnodes( 'field[@name="key" or @name="pkey" or @name="gkey"]' ) ) {
            my $name = $key->getAttribute( 'name' );
            my $value = $key->findvalue( '.' );
            if ( $value !~ /^$contributor\./ ) {
                push( @errors, "Found $name \"$value\" that should start with \"$contributor.\"" );
                next;
            }
            elsif ( $value =~ /[^\w.-]/ ) {
                push( @errors, "Found $name with illegal value \"$value\"" );
                next;
            }
        }

    }
    if ( @errors > 0 ) {
        $c->stash( error => 'INVALID', debug => join( "\n", @errors ));
        return 1  ;
    }

    # Ingest the record(s) into the Solr database. Note that we are
    # re-serializing the XML document rather than taking the original
    # data string. This should ensure that we get the correct encoding. It
    # also means we can modify our document in the preceding code and the
    # changes will be incorporated.
    my $solr = CAP::Solr->new( $c->config->{solr} );
    my $response = $solr->update( $add->toString() );
    if ( ! $response->{ok} ) {
        $c->stash( error => 'DBERROR', debug => $response->{error} );
    }
    $response = $solr->update("<commit/>");
    if ( ! $response->{ok} ) {
        $c->stash( error => 'DBERROR', debug => $response->{error} );
    }

    return 1;
}


=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

