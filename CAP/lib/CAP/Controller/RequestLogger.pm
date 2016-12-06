package CAP::Controller::RequestLogger;
use Moose;
use namespace::autoclean;
use JSON qw/encode_json/;

extends 'Catalyst::Controller';

sub process {
	my ( $self, $c ) = @_;

	my $data = {
		portal => $c->portal->id,
		view => $c->stash->{current_view},
		action => $c->req->action,
	};
	my $args = join('/', @{ $c->req->arguments });
	$data->{args} = $args if ($args);
	$data->{user} = $c->user->id if ($c->user_exists());
	my $institution = $c->session->{$c->portal->id}->{subscribing_institution};
	$data->{institution} = $institution->{id} if ($institution);
	$data->{query} = $c->req->query_parameters if (%{ $c->req->query_parameters });
	$data->{new_session} = JSON::true if ($c->session->{count} == 1);

	$c->log->info(encode_json $data);

	return 1;
}

1;

