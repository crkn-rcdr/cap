package CAP::Controller::Admin::Role;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Admin::Role - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Private
{
    my ( $self, $c ) = @_;
    my $id = $c->stash->{id};

    my $roles = [ $c->model('DB::Role')->all ];

    $c->stash (
        roles => $roles,
    );

    return 1;
}

sub create :Private
{
    my ( $self, $c ) = @_;
    my $invalid = {};

    if ( $c->stash->{process}) {

        $invalid = $c->forward('_validate');

        # If no validity errors were found, try to create the role. If successful,
        # redirect to the edit form.
        if ( 0 == keys( %{$invalid} ) ) {
            my $role =  $c->model('DB::Role')->create({
                role => $c->stash->{role},
            });

            if ( $role ) {
                $c->res->redirect( $c->uri_for($c->stash->{root}, 'role', { id => $role->get_column( 'id' ), action => 'edit' } ));
            }
            else {
                $c->stash (
                    error => 'DBERROR',
                );
            }
        }
        else {
            $c->stash ( error => 'INVALID' );
        }
    }

    $c->stash (
        invalid => $invalid,
        role => $c->req->params->{role},
    );

    return 1;
}

sub delete :Private
{
    my ( $self, $c ) = @_;

    if ( 0 == $c->stash->{id} ) {
        $c->stash (
            error => 'NOUSERID',
        );
        return 1;
    }
    elsif ( $c->stash->{id} == 1 ) {
        $c->stash (
            error => 'NODELETEADMIN'
        );
        return 1;
    }

    my $record = $c->model( 'DB::Role' )->find( { id => $c->stash->{id} } );

    if ( $record ) {
        $c->model( 'DB::UserRole' )->delete_roles( $record->id );
        $record->delete;
        $c->res->redirect( $c->uri_for($c->stash->{root}, 'role' ));
        return 1;
    }

    $c->stash (
        error => 'NOTFOUND',
    );
    return 1;
}

sub edit :Private
{
    my ( $self, $c ) = @_;
    my $record;
    my $role;
    my $invalid = {};

    if ( 0 == $c->stash->{id} ) {
        $c->stash ( error => 'NOUSERID' );
        return 1;
    }

    $record = $c->model( 'DB::Role' )->find( { id => $c->stash->{id} } );

    if ( ! $record ) {
        $c->stash ( error => 'NOTFOUND' );
        return 1;
    }

    # The name of the admin role cannot be changed.
    if ( 1 == int( $record->get_column( 'id' )) && $c->stash->{role} ne 'admin' ) {
        $c->stash ( error => 'NODELETEADMIN' );
        return 1;
    }

    if ( $c->stash->{process}) {
        $invalid = $c->forward( '_validate' );

        # Certain conditions are actually not validation errors in the context of editing
        # an existing user:
        delete( $invalid->{role} ) if
            ( $invalid->{role} eq 'EXISTS' && $c->stash->{role} eq $record->get_column( 'role' ) );
        delete( $invalid->{password} ) if ( $invalid->{password} eq 'EMPTY' );

        # If there are no validation errors, update the user information.
        if ( ! keys( %{$invalid} ) ) {
            $record->update( {
                role => $c->stash->{role},
            } );

            $record = $c->model( 'DB::Role' )->find( { id => $c->stash->{id} } );
        }
        else {
            $c->stash ( error => 'INVALID' );
        }
    }

    $c->stash (
        invalid => $invalid,
        role => $record,
    );

    return 1;
}

sub _validate :Private
{
    my ( $self, $c ) = @_;
    my $invalid = {};

    # The role must be between 1 and 128 characters and cannot already
    # be in use. It must consist only of A-Za-z0-9_
    if ( ! $c->stash->{role} ) {
        $invalid->{role} = 'EMPTY';
    }
    elsif ( $c->model( 'DB::Role' )->find( { role => $c->stash->{role} } )) {
        $invalid->{role} = 'EXISTS';
    }
    elsif ( length( $c->stash->{role} ) > 128 || $c->stash->{role} =~ /\W/ ) {
        $invalid->{role} = 'FORMAT';
    }

    $c->stash ( invalid => $invalid );
    return $invalid;
}


=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

