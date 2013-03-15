package CAP::Solr::AuthDocument::Auth;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;

has 'all_pages'  => (is => 'rw', isa => 'Int'); # Deprecated
has 'view_all'   => (is => 'rw', isa => 'Int', default => 0);
has 'view_part'  => (is => 'rw', isa => 'Int', default => 0);
has 'download'   => (is => 'rw', isa => 'Int', default => 0);
has 'resize'     => (is => 'rw', isa => 'Int', default => 0);
has 'pages'      => (is => 'rw', isa => 'ArrayRef', default => sub{[]});

method addPage ($auth) {
    push(@{$self->{pages}}, $auth);
}

method page (Int $page) {
    $page--; # Turn the 1-based page sequence into a 0-based array reference
    return 0 if ($page < 0);
    return 0 if ($page > $#{$self->pages});
    return $self->pages->[$page];
}

__PACKAGE__->meta->make_immutable;


package CAP::Solr::AuthDocument;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;
use base "CAP::Solr::Document";

has 'auth' => (is => 'ro', isa => 'CAP::Solr::AuthDocument::Auth');

method BUILD {
    $self->{auth} = new CAP::Solr::AuthDocument::Auth;
}

method authorize ($portal, $user, $institution) {

    # TODO: this is still a temporary workaround to having a set of
    # database-driven rules. It works as long as 'eco' is the only portal
    # that does not provide full open access to all content. This should
    # be replaced by a set of generic rule checks with all of the specific
    # parameters being defined in a database table.

    # Initialize the user's subscription level to 0 (none)
    my $level = 0;

    # Set the user's subscription level based on
    if ($user) {
        my $subscription = $user->find_related('user_subscriptions', { portal_id => $portal });
        # If the user has no subscription for this portal, access level
        # remains 0.
        if (! $subscription) {
            $level = 0;
        }
        # If the user's subscription is permanent, get the subscription level
        elsif ($subscription->permanent) {
            $level = $subscription->level;
        }
        # If the subscription has not yet expired, the the subscription level
        elsif ($subscription->expires->epoch() >= time) {
            $level = $subscription->level;
        }
    }

    # If we have an institutional subscription, the subscription level is
    # set to 2 (maximum)
    if ($institution) {
        if ($institution->is_subscriber($portal)) {
            $level = 2;
        }
    }

    # All portals other than ECO give the user an effective access level of 2.
    if ($portal->id ne 'eco') {
        $level = 2;
    }

    # Set to true if the user's access level is equal to or greater
    # than the required level.
    $self->auth->all_pages(int($level >= 1));
    $self->auth->view_all(int($level >= 1));
    $self->auth->view_part(int($level >= 1));
    $self->auth->download(int($level >= 2));
    $self->auth->resize(int($level >= 1));
    
    # Level 1 gives access to all pages, level 0 to only a preview.
    if ($level >= 1) {
        if ($self->record_type eq 'document') {
            for (my $page = 0; $page < $self->child_count; ++$page) {
                $self->auth->addPage(1);
            }
        }
    }
    else {
        for (my $page = 0; $page < $self->child_count; ++$page) {
            # The first page is always allowed (in case there is only one # page)
            if ($page == 1) {
                $self->auth->addPage(1);
            }
            # If this is a series, the first 2 issues are open to all.
            elsif ($self->seq && $self->seq <= 2) {
                $self->auth->addPage(1);
            }
            # The first 20 pages or 50% (whichever is less) are accessible to all.
            elsif ($page < 20 && $page <= int($self->child_count / 2)) {
                $self->auth->addPage(1);
            }
            else {
                $self->auth->addPage(0);
            }
        }
    }

    return;

}

around 'validate_derivative' => sub {
    my $orig = shift;
    my $self = shift;
    my ($seq, $size, $default_size) = @_;

    return [403, "Not authenticated."] unless $self->auth;
    return [403, "Not allowed to view this page."] unless $self->auth->page($seq);
    return [403, "Not allowed to resize this page."] unless ($size eq $default_size || $self->auth->resize);

    $self->$orig(@_);
};

around 'validate_download' => sub {
    my $orig = shift;
    my $self = shift;

    return [403, "Not authenticated."] unless $self->auth;
    return [403, "Not allowed to download this resource."] unless $self->auth->download;

    $self->$orig(@_);
};

__PACKAGE__->meta->make_immutable;
