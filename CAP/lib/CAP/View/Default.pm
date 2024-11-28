package CAP::View::Default;

use strict;
use base 'Catalyst::View::TT';
use Number::Format;
use Date::Format qw(time2str);

__PACKAGE__->config(
  TEMPLATE_EXTENSION => '.tt',
  ENCODING           => 'UTF-8',
  STRICT             => 0,
  RELATIVE           => 1,
  WRAPPER            => 'main.tt',
  VARIABLES          => {

    # Refines $param by adding/replacing any keys that appear in
    # refine. Returns a new hash.
    refine => sub {
      my ( $param, $refine ) = @_;
      my $joined = {};
      while ( my ( $key, $value ) = each( %{$param} ) ) {
        $joined->{$key} = $value;
      }
      while ( my ( $key, $value ) = each( %{$refine} ) ) {
        $joined->{$key} = $value;
      }
      return $joined;
    },

    format_number => sub {
      my ( $number, $lang ) = @_;

      #format only if it's a valid decimal number
      my $result;
      if ( $number =~ /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/ ) {
        my %delimiters;

        if ( $lang eq 'fr' ) {
          %delimiters = ( -thousands_sep => ' ', -decimal_point => ',' );
        } else {
          %delimiters = ( -thousands_sep => ',', -decimal_point => '.' );
        }

        my $format = new Number::Format(%delimiters);
        $result = $format->format_number($number);
      } else {
        $result = $number;
      }
    },

    ordinate => sub {
      my ( $number, $gender, $lang ) = @_;

      my $result;

      #format only if it's a valid decimal number
      if ( $number =~ /^\d+$/ ) {
        if ( $lang eq 'fr' ) {
          if ( $number == 1 ) {
            $result = ( $gender eq 'f' ? '1re' : '1er' );
          } else {
            $result = $number . 'e';
          }
        } else {
          $number =~ s/1?\d$/$& . ((0,'st','nd','rd')[$&] || 'th')/e;
          $result = $number;
        }
      } else {
        $result = $number;
      }

      return $result;
    },

    current_year => sub {
      return time2str( "%Y", time );
    },

    ref => sub {
      my ($t) = @_;
      return ref $t;
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
