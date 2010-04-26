package CAP::Controller::User;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 NAME

CAP::Controller::User - user management functions

=head1 DESCRIPTION

Methods for creating, editing, and deleting users and user roles.

=head1 METHODS

=head2 Actions

=cut


=over 4

=item index

Outputs the user management index page.

=back
=cut
sub index : Chained('/base') PathPart('user') Args(0)
{
    my($self, $c) = @_;
    $c->stash->{template} = 'user/index.tt';
    return 1;
}


=over 4

=item create

Creates a new user based on the form data supplied.

TODO: this method does not yet validate input, nor does it return a sensible error if there is a problem with the supplied data.

=back
=cut
sub create : Chained('/base') PathPart('user/create') Args(0)
{
    my($self, $c) = @_;
    my $p = $c->request->params;

    if ($p->{action} eq 'create') {
        # Verify that the user name is not already taken
        if ($c->model('DB::User')->user_exists($p->{user})) {
            $c->stash->{error} = $c->loc("Cannot create user '$p->{user}': user already exists.");
            $c->stash->{template} = "user/error.tt";
            return 1;
        }

        # Verify that the form data TODO

        # Return form if error TODO
        
        # Create the user entry in the database
        $c->model('DB::User')->create({
            username => $p->{user},
            password => $p->{pass},
            name => $p->{name},
            email => $p->{email},
            active => 1
        });

        # Open the newly-created user for editing.
        $c->detach('edit', [$p->{user}]);
    }

    $c->stash->{template} = 'user/create.tt';
    return 1;
}


=over 4

=item edit ( I<username> )

=back
=cut
sub edit : Chained('/base') PathPart('user/edit') Args(1)
{
    my($self, $c, $username) = @_;
    my $p = $c->request->params;
    my $update_password = 0;

    # Retrieve the data for the requested user
    my $user = $c->model('DB::User')->get_user_by_name($username);

    # Perform the requested action, if the user exists. If no action is
    # requested, this block is skipped and the edit form is displayed with
    # the user's information.
    if (! $user) {
        $c->stash->{error} = "NOUSER";
        $c->stash->{template} = "user/error.tt";
        return 1;
    }
    elsif ($p->{action} eq 'delete') {
        #TODO: don't allow the admin user to be deleted.
        $c->model('DB::UserRole')->delete_roles($user->id);
        $user->delete;
        $c->stash->{user} = $user;
        $c->stash->{template} = "user/deleted.tt";
        return 1;
    }
    elsif ($p->{action} eq 'edit') {

        # Validate the input TODO
        
        # Return form if error TODO
        
        # Set the user's active status
        my $active = 0;
        $active = 1 if ($p->{active});

        # Update the user's password, if a new one is specified.
        if ($p->{pass}) {
            if ($p->{pass} ne $p->{pass2}) {
                $c->stash->{error} = "PWMISMATCH";
                $c->stash->{template} = "user/error.tt";
                return 1;
            }

            # TODO: minimum password requirements

            warn("!! Setting password to $p->{pass}");
            $user->update({ password => $p->{pass} });
        }

        # Update the user information
        $user->update({
            active => $active,
            name => $p->{name},
            email => $p->{email},
        });
        
        # Update the roles for this user
        my @role_id = ();
        foreach my $param (keys(%{$p})) {
            if ($param =~ /^role\:/) { push(@role_id, substr($param, 5)) }
        }
        $c->model('DB::UserRole')->set_roles($user->id, @role_id);

    }
    
    # Retrieve the roles list and a list of roles currently assigned
    # to the user.
    my $roles = {};
    my $user_roles = {};
    foreach my $role ($c->model('DB::UserRole')->roles_for_user($user->id)) {
        $user_roles->{$role->role_id} = 1;
    }
    foreach my $role ($c->model('DB::Role')->all) {
        $roles->{$role->id} = { name => $role->role };
        $roles->{$role->id}->{has_role} = 1 if ($user_roles->{$role->id});
    }

    # Display the current status for this user.
    $c->stash->{roles} = $roles;
    $c->stash->{user} = $user;
    $c->stash->{template} = 'user/edit.tt';
    return 1;
}


=over 4

=item roles

=back
=cut
sub roles : Chained('/base') PathPart('user/roles') Args(0)
{
    my($self, $c) = @_;
    my $p = $c->request->params;

    if (! $p->{action}) {
        # Don't try to do anything; just display the role-editing form.
    }
    elsif ($p->{action} eq 'create') {

        # Check that the role name contains valid characters and is of
        # acceptable length.
        
        # Verify that the named role does not already exist
        
        # Create the role
        $c->model('DB::Role')->create({
            role => $p->{role},
        });

    }
    elsif ($p->{action} eq 'delete') {
        # Find the record.
        my $record = $c->model('DB::Role')->find({ id => $p->{id} });

        if (! $record) {
            $c->stash->{error} = "The requested role does not exist";
        }
        elsif ($record->role eq 'admin') {
            $c->stash->{error} = "The 'admin' role cannot be deleted";
        }
        else {

            # Delete the role
            $record->delete;

            # Delete all occurrences of the role from the user_role table
            my $user_role = $c->model('DB::UserRole')->search({ role_id => $p->{id} });
            $user_role->delete;
        }
    }
    elsif ($p->{action} eq 'rename') {

        # Verify that the old name exists
        
        # Check that the new name contains valid characters and is of
        # acceptable length
        
        # Verify that the new name is not already in use
        
        # Change the role name
    }


    # Retrieve a list of all roles
    $c->stash->{roles} = [$c->model('DB::Role')->all];

    $c->stash->{template} = 'user/roles.tt';
}

=head2 Private Methods

=cut

1;
