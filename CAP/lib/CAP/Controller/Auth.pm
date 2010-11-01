package CAP::Controller::Auth;

use strict;
use warnings;
use parent 'Catalyst::Controller';

=head1 CAP::Controller::Auth - user login and authorization functions

=head1 DESCRIPTION

This controller contains methods for logging users in and out.

=head1 Methods

=cut

=head2 Actions

=cut


=over 4

=item  login

Attempts to log the user in using the query parameters I<username> and
I<password>. If neither of these is supplied, the method simply returns an
empty login form. Otherwise, an attempt to authenticate is made. On an
unsuccessful attempt, the user is returned to the login template and
I<< stash->{login_msg} >> is set to C<NOMATCH> to indicate a username/password mismatch.

The query parameter I<page> takes a URI as its argument. If supplied, the
user will be redirected to the specified page on successful login. The
value of I<page> is also passed back to the login template on an
unsuccessful login.

=back
=cut
#sub login :Chained('/base') PathPart('login') Args(0)
sub login
{
    my($self, $c) = @_;
    my $username = $c->request->params->{username};
    my $password = $c->request->params->{password};

    # The default action on successful login is to redirect to the main
    # page, but if a page query parameter is specified, we will redirect
    # to that instead.
    my $page      = $c->request->params->{page};
    $page = $c->uri_for($c->stash->{root}) unless ($page);
    $c->stash->{page} = $page;
    warn("[debug] authenticate: login requested; redirect will be to \"$page\"\n") if ($c->config->{debug});

    $c->stash->{template} = 'login.tt';

    # If we were redirected here because we aren't logged in, set an
    # appropriate message.
    $c->stash->{login_msg} = "AUTHREQUIRED" if ($c->req->params->{redirected});

    # If the user is already logged in, forward automatically.
    # Otherwise, try to log the user in and, if successful, redirect to
    # the requested page.
    if ($c->user_exists) {
        warn("[debug] authenticate: redirecting to \"$page\" for already logged in user\n") if ($c->config->{debug});
        $c->res->redirect($page);
        $c->detach();
    }
    elsif ($username && $password) {
        if ($c->forward('authenticate')) {
            warn("[debug] authenticate: redirecting to \"$page\" after successful login\n") if ($c->config->{debug});
            $c->res->redirect($page);
            $c->detach();
        }
    }
    elsif ($username || $password) {
        $c->stash->{login_msg} = "NOMATCH";
    }

    return 1;
}


=over 4

=item logout

Logs the user out (if logged in) ending the session and redirects to the login page.

=back
=cut
#sub logout :Chained('/base') PathPart('logout') Args(0)
sub logout
{
    my($self, $c) = @_;

    my $page = $c->request->params->{page};
    $page = $c->uri_for($c->stash->{root}) unless ($page);
    $c->stash->{page} = $page;

    warn("[debug] authenticate: redirecting to \"$page\" after logout\n") if ($c->config->{debug});

    $c->logout();
    $c->forward('/index');

    $c->res->redirect($page);
    $c->detach();
}

=head2 Private Methods

=cut


=over 4

=item authenticate

Attempts to authenticate the user based on the query parameters
I<username> and I<password> (see L<CAP::Controller::Auth::login>). On
success, returns 1. On failure, returns 0 and sets I<<
stash->{login_msg} >> to either C<NOMATCH> or C<NOUSERID> depending on
whether failure is due to a username/password mismatch or failure to
supply either a username or password.

=back
=cut
#sub authenticate :Private
sub authenticate
{
    my($self, $c) = @_;
    my $username = $c->request->params->{username};
    my $password = $c->request->params->{password};

    warn("[debug] authenticate: trying to authenticate with \"$username\" = \"$password\"\n") if ($c->config->{debug});

    if ($username && $password) {
        if ($c->authenticate({ username => $username, password => $password})) {
            return 1;
        }
        else {
            warn("[debug] authenticate: password \"$password\" does not match user \"$username\"\n") if ($c->config->{debug});
            $c->stash->{login_msg} = "NOMATCH";
            return 0;
        }
    }

    warn("[debug] authenticate: missing username ($username) or password ($password)\n") if ($c->config->{debug});
    $c->stash->{login_msg} = "NOUSERID";
    return 0;
}

1;
