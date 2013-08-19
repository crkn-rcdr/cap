package CAP::Solr::AuthDocument::Auth;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;

has 'content'    => (is => 'rw', isa => 'Int', default => 0);
has 'preview'    => (is => 'rw', isa => 'Int', default => 0);
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

=head2 authorize($auth)

Determine the authorization status for this document. $auth is the CAP
Auth object (i.e. $c->auth).

=cut
method authorize ($auth) {
    
    # Set the authorizations for this document
    $self->auth->content($auth->can_access('content'));
    $self->auth->preview($auth->can_access('preview'));
    $self->auth->download($auth->can_access('download'));
    $self->auth->resize($auth->can_access('resize'));


    # Compile a list of pages that can be viewed based on whether the user
    # has full, preview or no access.
    for (my $page = 0; $page < $self->child_count; ++$page) {
        if ($self->auth->content) {
            $self->auth->addPage(1);
        }
        elsif ($self->auth->preview) {
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
        else {
            $self->auth->addPage(0);
        }
    }
    
    return 1;
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
