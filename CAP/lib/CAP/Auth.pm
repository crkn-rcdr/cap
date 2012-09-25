package CAP::Auth;
use strict;
use warnings;
use Carp;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;

#has 'auth'  => (is => 'ro', isa => 'HashRef', required => 1);
#has 'rules' => (is => 'ro', isa => 'Str', required => 1);
has 'portal' => (is => 'ro', isa => 'CAP::Model::DB::Portal', required => 1);
has 'user'   => (is => 'ro');
#has 'doc'    => (is => 'ro', isa => 'CAP::Solr::Document', required => 1);
has 'doc'    => (is => 'rw', required => 1);
has 'institution' => (is => 'ro');
# TODO: user and institution should have an isa => maybe user/instition
# type thing.

has 'all_pages'  => (is => 'ro', isa => 'Int'); # Deprecated

has 'view_all'   => (is => 'ro', isa => 'Int', default => 0);
has 'view_part'  => (is => 'ro', isa => 'Int', default => 0);
has 'download'   => (is => 'ro', isa => 'Int', default => 0);
has 'resize'     => (is => 'ro', isa => 'Int', default => 0);

has 'pages'      => (is => 'ro', isa => 'ArrayRef', default => sub{[]});

method BUILD {

    # Temporary: replicate existing behaviour
    if ($self->portal->id eq 'eco') {
        my $subscriber = 0;
        my $paid       = 0;
        if ($self->user) {
            $subscriber = 1 if ($self->user->subexpires && $self->user->subexpires->epoch() >= time);
            $paid = 1 if ($self->user->subexpires && $self->user->subexpires->epoch() >= time && $self->user->class eq 'paid');
            $subscriber = 1 if ($self->user->class eq 'permanent');
            $paid = 1 if ($self->user->class eq 'permanent');
        }
        if ($self->institution) {
            if ($self->institution->subscriber) {
                $subscriber = 1;
                $paid = 1;
            }
        }
        if ($subscriber) {
            $self->{all_pages} = 1;
            $self->{view_all}  = 1;
            $self->{view_part} = 1;
            $self->{download}  = 1 if ($paid);
            $self->{resize}    = 1;
            if ($self->doc->record_type eq 'document') {
                for (my $page = 0; $page < $self->doc->child_count; ++$page) {
                    push(@{$self->pages}, 1);
                }
            }
        }
        else {
            $self->{all_pages} = 0;
            $self->{view_all}  = 0;
            $self->{view_part} = 1;
            $self->{download}  = 0;
            $self->{resize}    = 0;
            if ($self->doc->record_type eq 'document') {
                for (my $page = 0; $page < $self->doc->child_count; ++$page) {
                    # The first page is always allowed (in case there is only one # page)
                    if ($page == 1) {
                        push(@{$self->pages}, 1);
                    }
                    # If this is a series, the first 2 issues are open to all.
                    elsif ($self->doc && $self->doc->seq <= 2) {
                        push(@{$self->pages}, 1);
                    }
                    # The first 20 pages or 50% (whichever is less) are accessible to all.
                    elsif ($page < 20 && $page <= int($self->doc->child_count / 2)) {
                        push(@{$self->pages}, 1);
                    }
                    else {
                        push(@{$self->pages}, 0);
                    }
                }
            }
        }
    }
    else {
        warn "Portal is OTHER";
        $self->{all_pages} = 1;
        $self->{view_all}  = 1;
        $self->{view_part} = 1;
        $self->{download}  = 1;
        $self->{resize}    = 1;
        if ($self->doc->record_type eq 'document') {
            for (my $page = 0; $page < $self->doc->child_count; ++$page) {
                push(@{$self->pages}, 1);
            }
        }
    }

    # Temporary (?) undef the document reference to prevent memory leaks.
    # This might be something to do permamently, as we don't actually need
    # it.
    $self->doc(undef);

}

method page (Int $page) {
    $page--; # Turn the 1-based page sequence into a 0-based array reference
    return 0 if ($page < 0);
    return 0 if ($page > $#{$self->pages});
    return $self->pages->[$page];
}

__PACKAGE__->meta->make_immutable;

