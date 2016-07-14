package CIHM::Access::Presentation::Document;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/HashRef/;
use List::Util qw/min/;
use List::MoreUtils qw/any/;

has 'record' => (
	is => 'ro',
	isa => HashRef,
	required => 1
);

has 'content' => (
	is => 'ro',
	isa => sub {
		die "$_[0] is not a CIHM::Access::Content" unless ref($_[0]) eq 'CIHM::Access::Content';
	},
	required => 1
);

has 'auth' => (
	is => 'ro',
	isa => HashRef,
	default => sub { return {
		content => 0,
		download => 0,
		preview => 0,
		resize => 0
	}; }
);

sub authorize_item {
	my ($self, $auth) = @_;
	foreach (qw/content download preview resize/) {
		$self->auth->{$_} = $auth->can_access($_);
	}

	foreach my $seq (1 .. scalar @{$self->record->{order}}) {
		my $key = $self->record->{order}[$seq-1];
		my $component = $self->record->{components}{$key};

		my $page_access = $self->auth->{content} ||
			# Preview access requires the following conditions:
			$self->auth->{preview} && (
				# The first page is always allowed (in case there is only one # page)
				$seq == 1 ||
				# If this is a series, the first 2 issues are open to all.
				$self->has_parent && $self->record->{seq} <= 2 ||
				# The first 20 pages or 50% (whichever is less) are accessible to all.
				$seq < 20 && $seq <= int($self->child_count / 2)
			);
		
		$component->{access} = $page_access ? 1 : 0;
	}

	return 1;
}

sub is_type {
	my ($self, $type) = @_;
	return $self->record->{type} eq $type;
}

sub is_in_collection {
	my ($self, $collection) = @_;
	return any { $_ eq $collection } @{ $self->record->{collection} };
}

sub has_children {
	my ($self) = @_;
	return scalar(@{ $self->record->{order} });
}

sub child_count { return shift->has_children() };

sub has_child {
	my ($self, $seq) = @_;
	return !!$self->record->{order}[$seq-1];
}

sub has_parent {
	my ($self) = @_;
	return !!$self->record->{pkey};
}

sub component {
	my ($self, $seq) = @_;
	my $child_id = $self->record->{order}[$seq-1];
	return { %{$self->record->{components}{$child_id}}, key => $child_id };
}

sub first_component_seq {
	my ($self) = @_;
	return 1 unless $self->is_type('document');

	my $limit = min 10, scalar(@{ $self->record->{order} });
	foreach my $seq (1..$limit) {
		foreach my $test ('cover', 'title page', 'table of contents', 'p\.') {
			return $seq if ($self->component($seq)->{label} =~ /$test/i);
		}
	}

	return 1;
}

sub canonical_label {
	my ($self) = @_;
	return ($self->record->{plabel} ? $self->record->{plabel} . " : " : "") . $self->record->{label};
}

sub validate_download {
	my ($self) = @_;
	my $download = $self->record->{canonicalDownload};
    return [400, "Document " . $self->record->{key} . " does not have a canonical download."] unless $download;
    return [403, "Not allowed to download this resource."] unless $self->auth->{download};
    return [200, $self->content->download($download)];
}

sub validate_derivative {
	my ($self, $seq, $size, $rotate) = @_;
    my $component = $self->component($seq);
    my $default_size = $self->content->derivative_config->{default_size};
    return [400, $self->key . " does not have page at seq $seq."] unless $component;
    return [400, $component->key . " does not have a canonical master."] unless $component->{canonicalMaster};
    return [200, $self->content->derivative($component->{canonicalMaster}, $size, $rotate)];
}

1;