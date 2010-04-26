package CAP::Controller::Admin;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub auto :Private {
    my ( $self, $c ) = @_;

    # Set parameter defaults
    my $action = "index";
    my $data = "";
    my $email = "";
    my $file = "";
    my $id = 0;
    my $key = "";
    my $name = "";
    my $process = 0;
    my $password = "";
    my $password2 = "";
    my $username = "";
    my $role = "";
    my $roles = {};

    # Override defaults with parameters specified in the query string if
    # they consist of allowable characters.
    $action = $c->req->params->{action} if
        ( $c->req->params->{action} && $c->req->params->{action} =~ /^[A-Za-z]\w*$/ );
    $data = $c->req->params->{data} if
        ( $c->req->params->{data} );
    $email = $c->req->params->{email} if
        ( $c->req->params->{email} );
    $file = $c->req->upload( 'file' )->slurp() if
        ( $c->req->upload( 'file' ));
    $id = int( $c->req->params->{id} ) if 
        ( $c->req->params->{id} && $c->req->params->{id} =~ /^\d+$/ );
    $key = $c->req->params->{key} if 
        ( $c->req->params->{key} );
    $name = $c->req->params->{name} if 
        ( $c->req->params->{name} );
    $process = 1 if
        ( $c->req->params->{process} );
    $role = $c->req->params->{role} if
        ( $c->req->params->{role} );
    $username = $c->req->params->{user} if
        ( $c->req->params->{user} );
    $password = $c->req->params->{pass} if
        ( $c->req->params->{pass} );
    $password2 = $c->req->params->{pass2} if
        ( $c->req->params->{pass2} );

    # Create a hash table of requested role assignments
    if ( ! $c->req->params->{roles} ) {
        ; # No roles supplied
    }
    elsif ( ref( $c->req->params->{roles} ) eq 'ARRAY' ) {
        foreach my $role ( @{$c->req->params->{roles}} ) {
            $roles->{$role} = 1 if ( $role =~ /^\d$/);
        }
    }
    elsif ( ref( $c->req->params->{roles} ) eq '' ) {
        $roles->{$c->req->params->{roles}} = 1 if ( $c->req->params->{roles} =~ /^\d$/);
    }

    # Store the parameters in the stash.
    $c->stash (
        action => $action,
        data => $data,
        email => $email,
        file => $file,
        id => $id,
        key => $key,
        name => $name,
        password => $password,
        password2 => $password2,
        process => $process,
        username => $username,
        role => $role,
        roles => $roles,
    );
    return 1;
}


sub docs :Chained('/base') :PathPart('docs') :Args(0)
{
    my ( $self, $c ) = @_;
    $c->stash (
        template => 'docs.tt',
    );
    return 1;
}

sub ingest :Chained('/base') :PathPart('ingest') :Args(0)
{
    my ( $self, $c ) = @_;

    # If a key is supplied, the data/file is treated as a digital
    # resource. Otherwise, it is assumed to be metadata.
    if ( $c->stash->{key} ) {
        $c->forward( '/admin/ingest/content' );
    }
    else {
        $c->forward( '/admin/ingest/metadata' );
    }

    $c->stash (
        template => 'ingest.tt',
    );
    return 1;
}

sub role :Chained('/base') :PathPart('role') :Args(0)
{
    my ($self, $c ) = @_;
    my $action = $c->stash->{action};
    my $path = "/admin/role/$action";

    if ( $c->dispatcher->get_action_by_path($path) ) {
        $c->forward($path);
    }
    else {
        $c->forward('/admin/role/index');
    }

    $c->stash (
        template => 'role.tt',
    );
    return 1;
}

sub user :Chained('/base') :PathPart('user') :Args(0)
{
    my ($self, $c ) = @_;
    my $action = $c->stash->{action};
    my $path = "/admin/user/$action";

    if ( $c->dispatcher->get_action_by_path($path) ) {
        $c->forward($path);
    }
    else {
        $c->forward('/admin/user/index');
    }

    $c->stash (
        template => 'user.tt',
    );
    return 1;
}

=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

