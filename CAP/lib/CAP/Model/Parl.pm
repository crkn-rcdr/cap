package CAP::Model::Parl;

use utf8;
use strictures 2;
use Moose;

extends 'Catalyst::Model';

has _type_labels => (
  is => 'ro',
  default => sub {
    return {
      en => {
        debates => "Debates",
        journals => "Journals",
        committees => "Committees"
      },
      fr => {
        debates => "Débats",
        journals => "Journaux",
        committees => "Comités"
      }
    }
  }
);

sub type_labels {
  my ($self, $lang) = @_;
  return $self->_type_labels->{$lang};
}

has _chamber_labels => (
  is => 'ro',
  default => sub {
    return {
      en => {
        s => "Senate",
        c => "House of Commons"
      },
      fr => {
        s => "Sénat",
        c => "Chambre des communes"
      }
    }
  }
);

sub chamber_labels {
  my ($self, $lang) = @_;
  return $self->_chamber_labels->{$lang};
}

1;