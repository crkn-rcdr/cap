package CAP::Auth::ECO;
use strict;
use warnings;
use Carp;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;
use CAP::Model::DB;

# has 'user'  => (is => 'ro', isa => 'Maybe[Catalyst::Authentication::Store::DBIx::Class::User]', required => 1);
has 'auth'  => (is => 'ro', isa => 'hashref', required => 1);
has 'doc'   => (is => 'ro', isa => 'CAP::Solr::Document', required => 1);

method all_pages {
    return $self->_is_subscriber;
}

# To download a PDF, the user must have an active subscription and be a
# full subcriber (not a trial user)
method download {
    return 1 if $self->auth->{institution_sub};
    return $self->_is_subscriber
       &&
   ($self->auth->{user}->class eq 'paid' || $self->auth->{user}->class eq 'permanent' || $self->auth->{user}->class eq 'admin');
}

method resize {
    return $self->_is_subscriber;
}

method pages {
    my $pages = [];
    my $subscriber = $self->_is_subscriber;
    if ($self->doc->record_type eq 'document') {
        for (my $page = 0; $page < $self->doc->child_count; ++$page) {

            # Subscribers have access to everything
            if ($subscriber) {
                push(@{$pages}, 1);
            }
            # The first page is always allowed (in case there is only one # page)
            elsif ($page == 1) {
                push(@{$pages}, 1);
            }
            # If this is a series, the first 2 issues are open to all.
            elsif ($self->doc->parent && $self->doc->seq <= 2) {
                push(@{$pages}, 1);
            }
            # The first 20 pages or 50% (whichever is less) are accessible to all.
            elsif ($page < 20 && $page <= int($self->doc->child_count / 2)) {
                push(@{$pages}, 1);
            }
            else {
                push(@{$pages}, 0);
            }

        }
    }
    return $pages;
}

method _is_subscriber {
    return 1 if ($self->auth->{user} && $self->auth->{user}->has_active_subscription);
    return 1 if $self->auth->{institution_sub};
    return 0;
}

__PACKAGE__->meta->make_immutable;

