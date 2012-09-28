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
    
    if ($portal->id eq 'eco') {
        my $subscriber = 0;
        my $paid       = 0;
        if ($user) {
            $subscriber = 1 if ($user->subexpires && $user->subexpires->epoch() >= time);
            $paid = 1 if ($user->subexpires && $user->subexpires->epoch() >= time && $user->class eq 'paid');
            $subscriber = 1 if ($user->class eq 'permanent');
            $paid = 1 if ($user->class eq 'permanent');
        }
        if ($institution) {
            if ($institution->subscriber) {
                $subscriber = 1;
                $paid = 1;
            }
        }
        if ($subscriber) {
            $self->auth->all_pages(1);
            $self->auth->view_all(1);
            $self->auth->view_part(1);
            $self->auth->download(1) if ($paid);
            $self->auth->resize(1);
            if ($self->record_type eq 'document') {
                for (my $page = 0; $page < $self->child_count; ++$page) {
                    $self->auth->addPage(1);
                }
            }
        }
        else {
            $self->auth->all_pages(0);
            $self->auth->view_all(0);
            $self->auth->view_part(1);
            $self->auth->download(0);
            $self->auth->resize(0);
            if ($self->record_type eq 'document') {
                for (my $page = 0; $page < $self->child_count; ++$page) {
                    # The first page is always allowed (in case there is only one # page)
                    if ($page == 1) {
                        $self->auth->addPage(1);
                    }
                    # If this is a series, the first 2 issues are open to all.
                    elsif ($self->seq <= 2) {
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
        }
    }
    else {
        $self->auth->all_pages(1);
        $self->auth->view_all(1);
        $self->auth->view_part(1);
        $self->auth->download(1);
        $self->auth->resize(1);
        if ($self->record_type eq 'document') {
            for (my $page = 0; $page < $self->child_count; ++$page) {
                $self->auth->addPage(1);
            }
        }
    }

    #warn "All pages is " . $self->auth->all_pages;
    #warn "View all is " . $self->auth->view_all;
    #warn "View part is " . $self->auth->view_part;
    #warn "Download is " . $self->auth->download;
    #warn "Resize is " . $self->auth->resize;
    #warn "Pages is " . join(" ", @{$self->auth->pages});
    #warn "Page 1 is " . $self->auth->page(1);
    #warn "Page 30 is " . $self->auth->page(30);

    return;

}

around 'derivative_request' => sub {
    my $orig = shift;
    my $self = shift;
    my ($content_config, $derivative_config, $seq, $filename, $size, $rotate, $format) = @_;

    my $child = $self->child($seq);
    my $size_str = $derivative_config->{size}->{$size} || $derivative_config->{default_size};
    return [403, "Not authenticated."] unless $self->auth;
    return [400, $self->key . " does not have page at seq $seq."] unless $child;
    return [403, "Not allowed to view this page."] unless $self->auth->page($seq);
    return [400, $child->key . " does not have a canonical master."] unless $child->canonicalMaster;
    return [403, "Not allowed to resize this page."] unless ($size_str eq $derivative_config->{default_size} || $self->auth->resize);

    $self->$orig(@_);
};

around 'download_request' => sub {
    my $orig = shift;
    my $self = shift;

    return [403, "Not authenticated."] unless $self->auth;
    return [403, "Not allowed to download this resource."] unless $self->auth->download;
    return [400, "Document " . $self->key . " does not have a canonical download."] unless $self->canonicalDownload;

    $self->$orig(@_);
};

__PACKAGE__->meta->make_immutable;
