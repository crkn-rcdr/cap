package CAP::Model::Parl;

use utf8;
use strictures 2;
use Moo;
use Text::Trim;

extends 'Catalyst::Model';
with 'Role::REST::Client';

has _bt => (
  is => 'ro',
  default => sub { return {}; }
);

has _bt_updated => (
  is => 'rwp',
  default => sub { return time; }
);

has '+type' => (
	default => sub { 'application/json' }
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json' }; }
);

sub _fetch_tree {
	my ($self) = @_;

	my $response = $self->get('/_design/parl/_view/browseTree',
    { reduce => 'true', group_level => '4' });
  
  return undef unless $response->data->{rows};

  foreach my $row (@{ $response->data->{rows} }) {
    my ($lang, $chamber, $type, $session) = @{ $row->{key} };
    my ($parliament) = ($session =~ /^(\d{2})-\d$/);
    $self->_bt->{$lang} //= {};
    $self->_bt->{$lang}->{$chamber} //= {};
    $self->_bt->{$lang}->{$chamber}->{$type} //= {};
    $self->_bt->{$lang}->{$chamber}->{$type}->{$parliament} //= {};
    $self->_bt->{$lang}->{$chamber}->{$type}->{$parliament}->{$session} = $row->{value};
  }

  return $self->_bt;
}

sub tree {
  my ($self) = @_;
  if (!(keys %{$self->_bt}) || time - $self->_bt_updated > 3600) {
    $self->_fetch_tree();
    $self->_set__bt_updated(time);
  }
  return $self->_bt;
}

sub _issue_title {
  my ($full_title, $lang) = @_;
  my ($eng, $fra) = split " = ", $full_title;
  my $title = $fra && $lang eq "fra" ? $fra : $eng;
  return trim((split ":", $title)[1] || $title);
}

sub leaf {
  my ($self, $lang, $chamber, $type, $session) = @_;

  my $startkey = qq/["$lang","$chamber","$type","$session"]/;
  my $endkey = qq/["$lang","$chamber","$type","$session!"]/;
  my $response = $self->get('/_design/parl/_view/browseTree',
    { reduce => 'false', startkey => $startkey, endkey => $endkey });
  
  my $leaf = [];
  return $leaf unless $response->data->{rows};

  foreach my $row (@{ $response->data->{rows} }) {
    push @$leaf, { id => $row->{id}, label => _issue_title($row->{value}, $lang) };
  }

  return { title => $self->leaf_to_string([$lang, $chamber, $type, $session]), leaf => $leaf };
}

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

has _publications => (
  is => 'ro',
  default => sub {
    return {
      en => {
        sdebates => 'Senate Debates',
        sjournals => 'Senate Journals',
        scommittees => 'Senate Committees',
        cdebates => 'House of Commons Debates',
        cjournals => 'House of Commons Journals',
        ccommittees => 'House of Commons Committees'
      },
      fr => {
        sdebates => 'Débats du Sénat',
        sjournals => 'Journaux du Sénat',
        scommittees => 'Comités du Sénat',
        cdebates => 'Débats de la Chambre des communes',
        cjournals => 'Journaux de la Chambre des communes',
        ccommittees => 'Comités de la Chambre des communes'
      }
    }
  }
);

sub _ordinate {
  my ($self, $num, $lang) = @_;

  if ($lang eq 'fr') {
    if ($num == 1) {
      return '1re';
    } else {
      return $num . 'e';
    } 
  } else {
    $num =~ s/1?\d$/$& . ((0,'st','nd','rd')[$&] || 'th')/e;
    return $num;
  }
}

sub leaf_to_string {
  my ($self, $node) = @_;
  my $lang = $node->[0] eq 'fra' ? 'fr' : 'en';
  my $pub = $self->_publications->{$lang}->{$node->[1] . $node->[2]};
  my $pl = $lang eq 'fr' ? 'Législature' : 'Parliament';
  my $p = $self->_ordinate((substr $node->[3], 0, 2) + 0, $lang);
  my $s = $self->_ordinate((substr $node->[3], 3, 1) + 0, $lang);
  my $session = "$p $pl, $s Session";
  return "$pub, $session";
}
1;
