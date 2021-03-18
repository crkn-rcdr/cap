package CAP;

use strict;
use warnings;

use Catalyst::Runtime '5.70';
use FindBin;

use Catalyst qw/
  ConfigLoader
  ConfigLoader::Environment
  Static::Simple
  StackTrace
  /;

# Configure the application.
# Note that settings in cap.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config(
  name => 'CAP',

  'Plugin::ConfigLoader' => {
    driver => {
      General => {
        -AutoTrue => 1,  # treat 1/yes/on/true == true; 0/no/off/false == false
        -UTF8     => 1,  # Enable support for UTF8 strings in the config file
      },
    },
  },
);

# Start the application
__PACKAGE__->setup();

sub portal_id {
  my ($c) = @_;
  if ( $c->stash->{portal} ) {
    return $c->stash->{portal}->id;
  } else {
    return '';
  }
}

sub portal_title {
  my ($c) = @_;
  if ( $c->stash->{portal} && $c->stash->{lang} ) {
    return $c->stash->{portal}->{label}->{ $c->stash->{lang} };
  } else {
    return '';
  }
}

sub loc {
  my ( $c, $tag, @args ) = @_;
  die 'Trying to localize a string without $c->stash->{lang} set'
    unless $c->stash->{lang};
  return $c->model("I18N")->localize( $c->stash->{lang}, $tag, @args );
}

1;
