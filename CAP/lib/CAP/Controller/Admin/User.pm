package CAP::Controller::Admin::User;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Admin::User - Catalyst Controller

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

    my $users = [ $c->model('DB::User')->all ];

    $c->stash (
        users => $users,
    );

    return 1;
}

sub create :Private
{
    my ( $self, $c ) = @_;

    # Get a list of all roles.
    my $roles = $c->forward ( '_roles', [ $c->stash->{roles} ] );

    # If the process flag is not set, we can short-circuit and just return
    # an empty form.
    if ( $c->stash->{process}) {

        my $invalid = $c->forward('_validate');

        # If no valididy errors were found, try to create the user. If successful,
        # redirect to the user edit page;
        if ( 0 == keys( %{$invalid} ) ) {
            my $user =  $c->model('DB::User')->create({
                username => $c->stash->{username},
                password => $c->stash->{password},
                name => $c->stash->{name},
                email => $c->stash->{email},
                active => 1
            });

            # TODO: set roles....

            if ( $user ) {
                $c->res->redirect( $c->uri_for($c->stash->{root}, 'user', { id => $user->get_column( 'id' ), action => 'edit' } ));
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
        user => {
            username => $c->req->params->{user},
            name => $c->req->params->{name},
            email => $c->req->params->{email},
        },
        roles => $roles,
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

    my $record = $c->model( 'DB::User' )->find( { id => $c->stash->{id} } );

    if ( $record ) {
        $c->model( 'DB::UserRole' )->delete_roles( $record->id );
        $record->delete;
        $c->res->redirect( $c->uri_for($c->stash->{root}, 'user' ));
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
    my $user_roles = {};
    my $roles;
    my $invalid = {};

    if ( 0 == $c->stash->{id} ) {
        $c->stash ( error => 'NOUSERID' );
        return 1;
    }

    $record = $c->model( 'DB::User' )->find( { id => $c->stash->{id} } );

    if ( ! $record ) {
        $c->stash ( error => 'NOTFOUND' );
        return 1;
    }


    if ( $c->stash->{process}) {
        $invalid = $c->forward( '_validate' );

        # Certain conditions are actually not validity errors in the context of editing
        # an existing user:
        delete( $invalid->{username} ) if
            ( $invalid->{username} eq 'EXISTS' && $c->stash->{username} eq $record->get_column( 'username' ) );
        delete( $invalid->{password} ) if ( $invalid->{password} eq 'EMPTY' );

        # If there are no validity errors, update the user information.
        if ( ! keys( %{$invalid} ) ) {
            if ( $c->stash->{password} ) {
                $record->update( { password => $c->stash->{password} } );
            }
            $record->update( {
                username => $c->stash->{username},
                name => $c->stash->{name},
                email => $c->stash->{email},
            } );

            # User id 1 must always have role 1 (admin)
            $c->stash->{roles}->{1} = 1 if ( $c->stash->{id} == 1 );

            # Set the requested roles
            $c->model( 'DB::UserRole' )->set_roles( $c->stash->{id}, keys( %{$c->stash->{roles}} ) );

            $record = $c->model( 'DB::User' )->find( { id => $c->stash->{id} } );
        }
        else {
            $c->stash ( error => 'INVALID' );
        }
    }

    # Create a table of available user roles and flag the ones had by this user
    if ( ! $c->stash->{process} || ( $c->stash->{process} && ! keys( %{$invalid} ))) {
        foreach my $role ( $c->model( 'DB::UserRole' )->roles_for_user( $record->id )) {
            $user_roles->{$role->role_id} = 1;
        }
        $roles = $c->forward ( '_roles', [ $user_roles ] );
    }
    else {
        $roles = $c->forward ( '_roles', [ $c->stash->{roles} ] );
    }

    $c->stash (
        user => $record,
        roles => $roles,
    );

    return 1;
}


sub _roles :Private
{
    my ( $self, $c, $user_roles ) = @_;
    my $roles = [];

    foreach my $role ( $c->model( 'DB::Role' )->all) {
        my $role_info = {};
        $role_info->{id} = $role->id;
        $role_info->{has_role} = 1 if ( $user_roles->{$role->id} );
        $role_info->{name} = $role->role;
        push( @{$roles}, $role_info );
    }

    return $roles;
}


sub _validate :Private
{
    my ( $self, $c ) = @_;
    my $invalid = {};

    # The username must be between 4 and 32 characters and cannot already
    # be in use.
    if ( ! $c->stash->{username} ) {
        $invalid->{username} = 'EMPTY';
    }
    elsif ( $c->model( 'DB::User' )->find( { username => $c->stash->{username} } )) {
        $invalid->{username} = 'EXISTS';
    }
    elsif ( length( $c->stash->{username} ) < 4 ) {
        $invalid->{username} = 'MINLENGTH';
    }
    elsif ( length( $c->stash->{username} ) > 32 ) {
        $invalid->{username} = 'MAXLENGTH';
    }

    # Real name must be between 1 and 128 characters
    if ( ! $c->stash->{name} ) {
        $invalid->{name} = 'EMPTY';
    }
    elsif ( length( $c->stash->{name} ) > 128 ) {
        $invalid->{name} = 'MAXLENGTH';
    }

    # Email address must look like an email address and be at most 128
    # characters long.
    if ( ! $c->stash->{email} ) {
        $invalid->{email} = 'EMPTY';
    }
    elsif ( length( $c->stash->{email} ) > 128 ) {
        $invalid->{email} = 'MAXLENGTH';
    }
    elsif ( $c->stash->{email} !~ /^[\w\.-]+\@[\w\/-]+\.[a-zA-Z]+$/ ) {
        $invalid->{email} = 'FORMAT';
    }

    # A password must exist, be 6 - 20 characters long, and the
    # verification field must match.
    if ( ! $c->stash->{password} ) {
        $invalid->{password} = 'EMPTY';
    }
    elsif ( length ( $c->stash->{password} ) < 6 ) {
        $invalid->{password} = 'MINLENGTH';
    }
    elsif ( length ( $c->stash->{password} ) > 20 ) {
        $invalid->{password} = 'MAXLENGTH';
    }
    elsif ( $c->stash->{password} ne $c->stash->{password2} ) {
        $invalid->{password} = 'MISMATCH';
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

