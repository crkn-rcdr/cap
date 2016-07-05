package CAP::View::Default;

use strict;
use base 'Catalyst::View::TT';
use Date::Format qw(time2str);
use Date::Parse qw(str2time);
use Scalar::Util qw(looks_like_number);
use HTML::Entities;
use JSON qw/encode_json/;


__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    STRICT => 0,
    #INCLUDE_PATH => [CAP->path_to('root/Default/templates/Default')],
    #INCLUDE_PATH => [CAP->path_to('root', 'templates', 'Default', 'Default')],
    RELATIVE => 1,
    WRAPPER => 'main.tt',
    FILTERS => {
        escape_js => sub { $_[0] =~ s/["\\]/\\$1/g; return $_[0]; },

        # Works basically like xml_escape, but doesn't turn ' into &quot;,
        # saving a lot of grief with Internet Explorer.
        xhtml => sub {
            $_[0] =~ s/&/&amp;/g;
            $_[0] =~ s/</&lt;/g;
            $_[0] =~ s/>/&gt;/g;
            $_[0] =~ s/"/&quot;/g;
            return $_[0];
        }
    },
    EVAL_PERL => 1,
    VARIABLES => {
        megabytes => sub {
            return sprintf("%3.1f", $_[0] / 1048576);
        },

        # Refines $param by adding/replacing any keys that appear in
        # refine. Returns a new hash.
        refine => sub {
            my($param, $refine) = @_;
            my $joined = {};
            while (my($key, $value) = each(%{$param})) { $joined->{$key} = $value; }
            while (my($key, $value) = each(%{$refine})) { $joined->{$key} = $value; }
            return $joined;
        },
        
        # Delete keys from the hash
        'delete' => sub {
            my($hash, @keys) = @_;
            my $joined = {};
            while (my($key, $value) = each(%{$hash})) { $joined->{$key} = $value; }
            foreach my $key (@keys) { delete($joined->{$key}) if (defined($joined->{$key})); }
            return $joined;
        },

        to_json_html => sub {
            my ($hash) = @_;
            return encode_entities(encode_json($hash));
        },

        format_date => sub {
            my $date = shift(@_);
            $date = str2time($date) unless looks_like_number($date);
            return $date ? time2str("%Y-%m-%d", $date) : "";
        },

        format_time => sub {
            my $time = shift(@_);
            $time = str2time($time) unless looks_like_number($time);
            return $time ? time2str("%Y-%m-%d %T", $time) : "";
        },

        'now' => sub {
            return time;
        },

        current_year => sub {
            return time2str("%Y", time);
        }
    }
);

=head1 NAME

CAP::View::Default - TT View for CAP

=head1 DESCRIPTION

TT View for CAP. 

=head1 AUTHOR

=head1 SEE ALSO

L<CAP>

William,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
