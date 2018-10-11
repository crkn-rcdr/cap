package CAP::Controller::RequestLogger;
use Moose;
use namespace::autoclean;
use JSON qw/encode_json/;

extends 'Catalyst::Controller';

sub process {
	my ( $self, $c ) = @_;

	my $data = {
		portal => $c->portal_id,
		view => $c->stash->{current_view},
		action => $c->req->action,
	};
	my $args = join('/', @{ $c->req->arguments });
	$data->{args} = $args if ($args);
	$data->{query} = $c->req->query_parameters if (%{ $c->req->query_parameters });

	$c->log->info(encode_json $data);

	return 1;
}

1;

