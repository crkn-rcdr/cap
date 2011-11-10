package CAP::View::Dojo;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    STRICT => 0,
    INCLUDE_PATH => [CAP->path_to('root/Default/templates/Dojo')],
    render_die => 1,
    VARIABLES => {
        modify_params => sub {
            my($orig, $new) = @_;
            my $param = {};
            while (my($key, $value) = each(%{$orig})) { $param->{$key} = $value; }
            while (my($key, $value) = each(%{$new})) { $param->{$key} = $value; }
            return $param;
        },
    }
);

=head1 NAME

CAP::View::Dojo - TT View for CAP

=head1 DESCRIPTION

TT View for CAP.

=head1 SEE ALSO

L<CAP>

=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
