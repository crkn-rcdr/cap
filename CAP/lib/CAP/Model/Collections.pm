package CAP::Model::Collections;

use Moose;
use namespace::autoclean;
use utf8;
use Text::Trim;

extends 'Catalyst::Model';

has 'path' => (
	is => 'ro',
	isa => 'Str',
	required => 1 );

has 'all' => (
	is => 'ro',
	isa => 'HashRef',
	writer => '_set_collections' );

sub BUILD {
	my ($self, $args) = @_;
	my $filename = $self->path;
	open (my $fh, '<', $filename) or die "Could not open $filename: $!";
	my $collections = {};
	while(my $line = <$fh>) {
		trim $line;
		my @data = split(/\|/, $line);
		$collections->{$data[0]} = {
			en => {
				title => $data[1],
				description => $data[3]
			}, fr => {
				title => $data[2],
				description => $data[4]
			}
		};
	}
	close $fh;
	$self->_set_collections($collections);
}

1;