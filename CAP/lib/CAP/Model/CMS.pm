package CAP::Model::CMS;

use base 'Catalyst::Model';
use CIHM::CMS;
use Moose;

our $AUTOLOAD;

has 'cms_instance' => (
	is => 'rw',
	isa => 'CIHM::CMS'
);

has 'server' => (
	is => 'ro',
	isa => 'Str',
	required => 1
);

sub initialize_after_setup {
	my ($self, $app) = @_;
	$app->log->debug('Initializing CMS after app is fully loaded.');
	$self->cms_instance(
		CIHM::CMS->new({
			server => $self->server,
			languages => $app->config->{languages},
			cache => $app->model('CouchCache')
		})
	);
}

# see http://www.perlmonks.org/?node_id=915657
sub AUTOLOAD {
	my $self = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	$self->cms_instance->$name(@_);
}

1;