package CIHM::Access::Presentation::Document;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/HashRef Str/;
use List::Util qw/min/;
use List::MoreUtils qw/any/;

has 'record' => (
	is => 'ro',
	isa => HashRef,
	required => 1
);

has 'derivative' => (
	is => 'ro',
	isa => sub {
		die "$_[0] is not a CIHM::Access::Derivative" unless ref($_[0]) eq 'CIHM::Access::Derivative';
	},
	required => 1
);

has 'download' => (
	is => 'ro',
	isa => sub {
		die "$_[0] is not a CIHM::Access::Download" unless ref($_[0]) eq 'CIHM::Access::Download';
	},
	required => 1
);

has 'prezi_demo_endpoint' => (
	is => 'ro',
	isa => Str,
	required => 1
);

sub BUILD {
	my ($self, $args) = @_;

	# handle date tags correctly
    my $dates = $args->{record}{tagDate};
    if (defined $dates) {
    	my @date_tags = ();
        foreach my $date_str (@$dates) {
        	my $tag = '';
        	if ($date_str =~ /\[(.+) TO (.+)\]/) {
        		my ($date1, $date2) = (_format_date($1), _format_date($2));
        		$tag = $date1 && $date2 ? "$date1 – $date2" : '';
        	} else {
        		$tag = _format_date($date_str);
        	}
        	push(@date_tags, $tag) if $tag;
        }
        $args->{record}{tagDate} = \@date_tags;
    }
}

sub _format_date {
    my ($date) = (@_);
    $date =~ /^(\d{4})-(\d{2})-(\d{2}).+/;
    return $2 == 1 && $3 == 1 || $2 == 12 && $3 == 31 ? $1 : "$1-$2-$3";
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
    return [200, $self->download->uri($download)];
}

sub validate_derivative {
	my ($self, $seq, $size, $rotate) = @_;
    my $component = $self->component($seq);
    return [400, $self->key . " does not have page at seq $seq."] unless $component;
    if ($component->{canonicalMaster}) {
	    return [200, $self->derivative->uri({
	    	master => $component->{canonicalMaster},
	    	size => $size,
	    	rotate => $rotate
	    })];
    } elsif ($self->record->{canonicalDownloadMime} eq 'application/pdf') {
    	return [200, $self->derivative->uri({
    		from_pdf => 1,
    		download => $self->record->{canonicalDownload},
    		page => $seq,
    		size => $size,
    		rotate => $rotate
    	})];
    } else {
	    return [400, $component->{key} . " does not have a canonical master."] unless $component->{canonicalMaster};
    }
}

sub prezi_demo_uri {
	my ($self) = @_;
	if ($self->is_type('document')) {
		return join '/', $self->prezi_demo_endpoint, $self->record->{key}, 'manifest';
	} elsif ($self->is_type('series')) {
		return join '/', $self->prezi_demo_endpoint, 'collection', $self->record->{key};
	} else {
		return '';
	}
}

1;
