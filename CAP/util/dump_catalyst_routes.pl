#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use Encode 'decode_utf8';

my $app = shift or usage();
bootstrap_app($app, @ARGV);
my $d = $app->dispatcher;
my $actions = get_actions($d);
for (@{$actions}) {
  say join "\t", $_->{class}, $_->{name}, $_->{path};
}

sub usage {
  die "
  USAGE
    $0 <Catalyst Module Name> [path,...]
  EXAMPLE
    \$ $0 MyApp lib local/lib/perl5\n\n";
}

sub bootstrap_app {
  my ($app, @paths) = @_;
  require lib;
  lib->import(@paths);
  eval "require $app";
  die $@ if $@;
}

sub get_actions {
  my $dispatcher = shift;

  my @actions;
  for my $dt (@{$dispatcher->dispatch_types})
  {
    if (ref $dt eq 'Catalyst::DispatchType::Path')
    {
      # taken from Catalyst::DispatchType::Path
      foreach my $path ( sort keys %{ $dt->_paths } ) {
        foreach my $action ( @{ $dt->_paths->{$path} } ) {
          my $args  = $action->number_of_args;
          my $parts = defined($args) ? '/*' x $args : '/...';

          my $display_path = "/$path/$parts";
          $display_path =~ s{/{1,}}{/}g;
          $display_path =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg; # deconvert urlencoded for pretty view·
          $display_path = decode_utf8 $display_path;  # URI does encoding
          $action->{path} = $display_path;
          push @actions, $action;
        }
      }
    }
    elsif (ref $dt eq 'Catalyst::DispatchType::Chained')
    {
      # taken from Catalyst::DispatchType::Chained
      ENDPOINT: foreach my $endpoint (
                    sort { $a->reverse cmp $b->reverse }
                             @{ $dt->_endpoints }
                    ) {
          my $args = $endpoint->list_extra_info->{Args};
          my @parts = (defined($endpoint->attributes->{Args}[0]) ? (("*") x $args) : '...');
          my @parents = ();
          my $parent = "DUMMY";
          my $extra  = $dt->_list_extra_http_methods($endpoint);
          my $consumes = $dt->_list_extra_consumes($endpoint);
          my $scheme = $dt->_list_extra_scheme($endpoint);
          my $curr = $endpoint;
          my $action = $endpoint;
          while ($curr) {
              if (my $cap = $curr->list_extra_info->{CaptureArgs}) {
                  unshift(@parts, (("*") x $cap));
              }
              if (my $pp = $curr->attributes->{PathPart}) {
                  unshift(@parts, $pp->[0])
                      if (defined $pp->[0] && length $pp->[0]);
              }
              $parent = $curr->attributes->{Chained}->[0];
              $curr = $dt->_actions->{$parent};
              unshift(@parents, $curr) if $curr;
          }
          if ($parent ne '/') {
              next ENDPOINT;
          }
          my @rows;
          foreach my $p (@parents) {
              my $name = "/${p}";

              if (defined(my $extra = $dt->_list_extra_http_methods($p))) {
                  $name = "${extra} ${name}";
              }
              if (defined(my $cap = $p->list_extra_info->{CaptureArgs})) {
                  if($p->has_captures_constraints) {
                    my $tc = join ',', @{$p->captures_constraints};
                    $name .= " ($tc)";
                  } else {
                    $name .= " ($cap)";
                  }
              }
              if (defined(my $ct = $p->list_extra_info->{Consumes})) {
                  $name .= ' :'.$ct;
              }
              if (defined(my $s = $p->list_extra_info->{Scheme})) {
                  $scheme = uc $s;
              }

              unless ($p eq $parents[0]) {
                  $name = "-> ${name}";
              }
              push(@rows, [ '', $name ]);
          }

          if($endpoint->has_args_constraints) {
            my $tc = join ',', @{$endpoint->args_constraints};
            $endpoint .= " ($tc)";
          } else {
            $endpoint .= defined($endpoint->attributes->{Args}[0]) ? " ($args)" : " (...)";
          }
          push(@rows, [ '', (@rows ? "=> " : '').($extra ? "$extra " : ''). ($scheme ? "$scheme: ":'')."/${endpoint}". ($consumes ? " :$consumes":"" ) ]);
          my @display_parts = map { $_ =~s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg; decode_utf8 $_ } @parts;
          $rows[0][0] = join('/', '', @display_parts) || '/';
          $action->{path} = $rows[0][0];
          push @actions, $action;
      }
    }
    else {
      warn ref $dt
    }
  }
  return \@actions;
}
__END__
Copyright 2019 David Farrell
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
