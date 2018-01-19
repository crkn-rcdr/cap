package CAP::Model::CMS;

use base 'Catalyst::Model';
use CIHM::CMS;
use Moose;

our $AUTOLOAD;

has 'cms_instance' => (
	is => 'rw',
	isa => 'CIHM::CMS'
);

# see http://www.perlmonks.org/?node_id=915657
sub initialize_after_setup {
	my ($self, $app) = @_;
	$self->cms_instance(
		CIHM::CMS->new({
			server => $app->config->{services}->{cms}->{endpoint},
			languages => $app->config->{languages},
			cache => $app->model('CouchCache')
		})
	);
}

sub AUTOLOAD {
	my $self = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	$self->cms_instance->$name(@_);
}

1;