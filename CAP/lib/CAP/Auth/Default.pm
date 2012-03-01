package CAP::Auth::Default;
use strict;
use warnings;
use Carp;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;

# has 'user'  => (is => 'ro', isa => 'Maybe[Catalyst::Authentication::Store::DBIx::Class::User]', required => 1);
has 'auth'  => (is => 'ro', isa => 'HashRef', required => 1);
has 'doc'   => (is => 'ro', isa => 'CAP::Solr::Document', required => 1);

method all_pages {
    return 1;
}

method download {
    return 1;
}

method resize {
    return 1;
}

method pages {
    my $pages = [];
    if ($self->doc->record_type eq 'document') {
        for (my $page = 0; $page < $self->doc->child_count; ++$page) {
            push(@{$pages}, 1);
        }
    }
    return $pages;
}

__PACKAGE__->meta->make_immutable;

