package CAP::Auth;
use strict;
use warnings;
use Carp;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;

use CAP::Auth::Default;
use CAP::Auth::ECO;

# has 'user'  => (is => 'ro', isa => 'Maybe[Catalyst::Authentication::Store::DBIx::Class::User]', required => 1);
has 'auth'  => (is => 'ro', isa => 'HashRef', required => 1);
has 'rules' => (is => 'ro', isa => 'Str', required => 1);
has 'doc'   => (is => 'ro', isa => 'CAP::Solr::Document', required => 1);

has 'all_pages'  => (is => 'ro', isa => 'Int');
has 'download'   => (is => 'ro', isa => 'Int');
has 'resize'     => (is => 'ro', isa => 'Int');

method BUILD {
    my $auth_model;
    if ($self->rules eq 'eco') {
        $auth_model = new CAP::Auth::ECO(auth => $self->auth, doc => $self->doc);
    }
    else {
        $auth_model = new CAP::Auth::Default(auth => $self->auth, doc => $self->doc);
    }

    $self->{download}   = $auth_model->download;   # Can the resource be downloaded (e.g. PDF)
    $self->{resize}     = $auth_model->resize;     # Can derivative images be resized?
    $self->{all_pages}  = $auth_model->all_pages;  # View access to all pages?
    $self->{_pages}     = $auth_model->pages;      # Array of per-page access flags

}

method page (Int $page) {
    $page--; # Turn the 1-based page sequence into a 0-based array reference
    return 0 if ($page < 0);
    return 0 if ($page > $#{$self->{_pages}});
    return $self->{_pages}->[$page];
}

__PACKAGE__->meta->make_immutable;

