package CAP::Model::Mailer;

use utf8;
use strictures 2;
use Moose;
use namespace::autoclean;

use Email::Sender::Transport::SMTP;
use Email::Stuffer;
use Try::Tiny;
use Template;

extends 'Catalyst::Model';

has 'host' => (
	is => 'ro',
	isa => 'Str',
	required => 1
);

has 'port' => (
	is => 'ro',
	isa => 'Int',
	default => 25
);

has 'from' => (
	is => 'ro',
	isa => 'Str',
	required => 1
);

has 'template_path' => (
	is => 'ro',
	isa => 'Str',
	required => 1
);

has 'template' => (
	is => 'ro',
	required => 1,
	lazy => 1,
	builder => '_build_template'
);

has 'transport' => (
	is => 'ro',
	required => 1,
	lazy => 1,
	builder => '_build_transport'
);

sub _build_template {
	my ($self) = @_;
	return Template->new({
		INCLUDE_PATH => $self->template_path,
		INTERPOLATE => 1,
		EVAL_PERL => 1
	});
}

sub _build_transport {
	my ($self) = @_;
	return Email::Sender::Transport::SMTP->new({
		host => $self->host,
		port => $self->port
	});
}

sub send {
	my ($self, $c, $args) = @_;
	my $body = '';
	my $template_success = $self->template->process($args->{template}, { c => $c, %{$args->{template_vars}} }, \$body);

	unless ($template_success) {
		warn "Email template error: " . $self->template->error();
		return 1;
	}

	my $email = Email::Stuffer->new({
		from => $self->from,
		to => $args->{to},
		subject => $args->{subject},
		text_body => $args->{html} ? undef : $body,
		html_body => $args->{html} ? $body : undef,
		transport => $self->transport
	});

	try {
		$email->send_or_die;
	} catch {
		warn "Error sending email: $_";
	};
}

sub status_report {
	my ($self, $c, $recipients, $data) = @_;
	$self->send($c, {
		to => $recipients,
		subject => "CAP System Status Report",
		html => 1,
		template => 'status_report.tt',
		template_vars => { mail_data => $data }
	});
}

sub user_reset {
	my ($self, $c, $recipient, $confirm_link) = @_;
	$self->send($c, {
		to => $recipient,
		subject => $c->loc('Password Reset'),
		template => 'reset.tt',
		template_vars => {
			confirm_link => $confirm_link,
			portal_name => $c->stash->{portal_name}
		}
	});
}

sub user_activate {
	my ($self, $c, $recipient, $real_name, $confirm_link) = @_;
	$self->send($c, {
		to => $recipient,
		subject => $c->loc('Canadiana Account Activation'),
		template => 'activate.tt',
		template_vars => {
			real_name => $real_name,
			recipient => $recipient,
			confirm_link => $confirm_link,
		}
	});
}

sub subscription_confirmation {
	my ($self, $c, $recipient, $lang, $subscription) = @_;
	$self->send($c, {
		to => $recipient,
		subject => $c->loc("Your Canadiana Subscription"),
		html => 1,
		template => 'subscription_confirmation.tt',
		template_vars => { lang => $lang, subscription => $subscription }
	});
}

1;