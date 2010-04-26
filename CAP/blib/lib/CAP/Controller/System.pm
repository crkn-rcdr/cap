package CAP::Controller::System;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::System - system status and maintenance

=head1 DESCRIPTION

This controller contains methods for monitoring and updating the system status.

=head1 METHODS

=cut


=over4

=item index

=back
=cut

sub index :Chained('/base') PathPart('system') Args(0)
{
    my($self, $c) = @_;

    $c->stash(
        'template' => 'system/index.tt',
        'sessions' => $c->model('DB::Sessions')->count_active(),
    );
    return 1;
}

sub i18n :Chained('/base') PathPart('system/i18n') Args(1)
{
    my($self, $c, $lang) = @_;
    my $p = $c->req->params;

    use Encode;

    if ($p->{update}) {
        my $message = $c->model('DB::Lexicon')->get_message($p->{id});
        if ($message) {
            $message->update({ value => $p->{value} });
        }
    }
    elsif ($p->{delete}) {
        my $message = $c->model('DB::Lexicon')->get_message($p->{id});
        $message->delete() if ($message);
    }
    elsif ($p->{create}) {
        # TODO: validate...
        # TODO: check for duplicates
        $c->model('DB::Lexicon')->create({
            path => $p->{path},
            language => $lang,
            message => $p->{message},
            value => $p->{value},
            notes => $p->{notes},
        });
    }

    $c->stash(
        'template' => 'system/i18n.tt',
        'i18n_lang' => $lang,
        'messages' => $c->model('DB::Lexicon')->translations($lang),
        'untranslated' => $c->model('DB::Lexicon')->untranslated($lang),
        'translated' => $c->model('DB::Lexicon')->translated($lang),
    );
}


__PACKAGE__->meta->make_immutable;

