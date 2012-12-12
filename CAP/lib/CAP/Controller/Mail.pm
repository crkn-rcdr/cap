package CAP::Controller::Mail;
use Moose;
use namespace::autoclean;

use File::MimeInfo;
use File::Basename;
use parent qw/Catalyst::Controller::ActionRole/;


BEGIN {extends 'Catalyst::Controller::ActionRole'; }

=head1 NAME

CAP::Controller::Mail - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 sendmail

=cut

sub sendmail {
    my ($self, $c, $template, $header, $attach) = @_;

    my $old_template_paths = $c->stash->{additional_template_paths};
    $c->stash(additional_template_paths => [
        join('/', $c->config->{root}, 'templates', 'Mail', $c->stash->{portal}),
        join('/', $c->config->{root}, 'templates', 'Mail', 'Common')
    ]);


    if (defined($attach)) {
	# Assumes a single file name. Will need update if we want to 
        # accept array of filenames

	my $attachtype = mimetype($attach);
	my $attachbody = "";
	local $/ = undef;
	if (open FILE, $attach) {
	    binmode FILE;
	    $attachbody = <FILE>;
	    close FILE;
	} else {
	    $c->log->error("Can't open attachment $attach : $!\n");
        $c->stash(additional_template_paths => $old_template_paths);
	    return 1;
	}

	my $textbody = $c->view("Mail")->render($c, $template);

	# Two part MIM message:  plain text + attachment
	my @parts = (
	    Email::MIME->create (
		attributes => {
		    content_type => 'text/plain',
		    charset      => 'UTF-8',
		},
		body => $textbody,
	    ),
	    Email::MIME->create(
		attributes => {
		    content_type => $attachtype,
		    encoding     => 'base64',
		    name         => basename($attach),
		},
		body => $attachbody,
	    ),
	);

	$c->email({
		header => $header,
		parts => \@parts,
	    });

    } else {
	# Send simple email
	$c->email({
		header => $header,
		body => $c->view("Mail")->render($c, $template)
	    });
    }
    $c->stash(additional_template_paths => $old_template_paths);
    return 1;
}

sub user_reset :Private {
    my ($self, $c, $recipient, $confirm_link) = @_;
    $c->stash(confirm_link => $confirm_link);

    my $from = $c->config->{email_from};
    if (! $from) {
	return 1;
    }

    my $header = [
        From => $from,
        To => $recipient,
        Subject => $c->loc('Password Reset')
    ];

    $self->sendmail($c, "reset.tt", $header);
    return 1;
}

sub user_activate :Private {
    my ($self, $c, $recipient, $real_name, $confirm_link) = @_;
    $c->stash(recipient => $recipient,
        real_name => $real_name,
        confirm_link => $confirm_link
    );

    my $from = $c->config->{email_from};
    if (! $from) {
	return 1;
    }
    my $header = [
        From => $from,
        To => $recipient,
        Subject => $c->loc('ECO Account Activation')
    ];

    $self->sendmail($c, "activate.tt", $header);
    return 1;
}

sub subscription_notice :Private {
    my ($self, $c, $admins, $success, $oldexpire, $newexpire, $message) = @_;
    $c->stash(subscribe_success => $success,
        subscribe_oldexpire => $oldexpire,
        subscribe_newexpire => $newexpire,
        subscribe_message => $message
    );

    my $from = $c->config->{email_from};
    if (! $from) {
	return 1;
    }
    my $header = [
        From => $from,
        To => $admins,
        Subject => $c->loc('ECO Subscription Finalized')
    ];

    $self->sendmail($c, "subscribe_finalize.tt", $header);
    return 1;
}

sub feedback :Private {
    my ($self, $c) = @_;

    my $to = $c->config->{support_email};   
    $c->stash->{sending_message} = 1;   
    
    $c->stash(recipient => $to,
              real_name => 'user support'
    );

    my $from = $c->config->{email_from};
    if (! $from) {
	return 1;
    }
    my $header = [
        From => $from,
        To => $to,
        Subject => $c->loc('User feedback')
    ];

    $self->sendmail($c, "feedback.tt", $header);
    return 1;
}

sub subscription_reminder :Private {
    use feature 'switch';
    my ($self, $c, $exp_acct, $exp_date) = @_;
    
    
    
    #my $recipient  =  $exp_acct->{username};
    #my $sub_class  =  $exp_acct->{class};
    my $recipient  =  $exp_acct->username;
    my $sub_class  =  $exp_acct->class;
    
    $c->stash(recipient  =>  $exp_acct->username,
              real_name  =>  $exp_acct->name,
              subexpires =>  $exp_date,
              exp_en     =>  $exp_date->{en},
              exp_fr     =>  $exp_date->{fr} 
    );
    
    
    
    my $from = $c->config->{email_from};
    
    $c->model('DB::CronLog')->create({
               action  => 'reminder_notice',
               ok      => 0,
               message => "from address is $from"
    });    
    
    if (! $from) {
	return 1;
    }
    my $header = [
        From => $from,
        To =>   $recipient,
        Subject => "Your Canadiana.org subscription / Votre abonnement Canadiana.org"
    ];

    my $template = "";
    given ($sub_class) {
            when ("trial") {$template = "trial_reminder.tt"}
            when ("basic") {$template = "subscription_reminder.tt"}
            when ("paid")  {$template = "subscription_reminder.tt"}
            when ("") {return 1}
    }

    $self->sendmail($c, $template, $header);

    return 1;
}




=head1 AUTHOR

Sascha Adler,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
