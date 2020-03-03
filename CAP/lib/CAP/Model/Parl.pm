package CAP::Model::Parl;

use utf8;
use strictures 2;
use Moo;
use Text::Trim;

extends 'Catalyst::Model';
with 'Role::REST::Client';

has _bt => (
  is      => 'ro',
  default => sub { return {}; }
);

has _bt_updated => (
  is      => 'rwp',
  default => sub { return time; }
);

has '+type' => ( default => sub { 'application/json' } );

has '+persistent_headers' =>
  ( default => sub { return { Accept => 'application/json' }; } );

sub _fetch_tree {
  my ($self) = @_;

  my $response = $self->get( '/_design/parl/_view/browseTree',
    { reduce => 'true', group_level => '4', stale => 'update_after' } );

  return {} unless $response->data->{rows};

  foreach my $row ( @{ $response->data->{rows} } ) {
    my ( $lang, $chamber, $type, $session ) = @{ $row->{key} };
    my ($parliament) = ( $session =~ /^(\d{2})-\d$/ );
    $self->_bt->{$lang}                      //= {};
    $self->_bt->{$lang}->{$chamber}          //= {};
    $self->_bt->{$lang}->{$chamber}->{$type} //= {};
    if ($session) {
      $self->_bt->{$lang}->{$chamber}->{$type}->{$parliament} //= {};
      $self->_bt->{$lang}->{$chamber}->{$type}->{$parliament}->{$session} =
        $row->{value};
    } else {
      $self->_bt->{$lang}->{$chamber}->{$type} = $row->{value};
    }
  }

  return $self->_bt;
}

sub tree {
  my ($self) = @_;
  if ( !( keys %{ $self->_bt } ) || time - $self->_bt_updated > 3600 ) {
    $self->_fetch_tree();
    $self->_set__bt_updated(time);
  }
  return $self->_bt;
}

sub _issue_title {
  my ( $full_title, $lang ) = @_;
  my ( $eng, $fra ) = split " = ", $full_title;
  my $title = $fra && $lang eq "fra" ? $fra : $eng;
  return trim( ( split ":", $title )[1] || $title );
}

sub leaf {
  my ( $self, $lang, $chamber, $type, $session ) = @_;

  my $session_lookup_start = $session ? qq/"$session"/  : qq/null/;
  my $session_lookup_end   = $session ? qq/"$session!"/ : qq/"a"/;
  my $startkey = qq/["$lang","$chamber","$type",$session_lookup_start]/;
  my $endkey   = qq/["$lang","$chamber","$type",$session_lookup_end]/;
  my $response = $self->get(
    '/_design/parl/_view/browseTree',
    {
      reduce   => 'false',
      startkey => $startkey,
      endkey   => $endkey,
      stale    => 'update_after'
    }
  );

  my $leaf = [];
  return $leaf unless $response->data->{rows};

  foreach my $row ( @{ $response->data->{rows} } ) {
    push @$leaf,
      { id => $row->{id}, label => _issue_title( $row->{value}, $lang ) };
  }

  return {
    title => $self->leaf_to_string( [$lang, $chamber, $type, $session] ),
    leaf => $leaf
  };
}

has _type_labels => (
  is      => 'ro',
  default => sub {
    return {
      en => {
        debates    => "Debates",
        journals   => "Journals",
        committees => "Committees",
        bills      => "Bills",
        proc       => "Votes and Proceedings",
        rules      => "Rules of the Senate",
        orders     => "Standing Orders of the House of Commons",
        sessional  => "Sessional Papers"
      },
      fr => {
        debates    => "Débats",
        journals   => "Journaux",
        committees => "Comités",
        bills      => "Projets de loi",
        proc       => "Procès-verbaux",
        rules      => "Règlement du Sénat",
        orders     => "Règlement de la Chambre des communes",
        sessional  => "Documents parlementaires"
      }
    };
  }
);

sub type_labels {
  my ( $self, $lang ) = @_;
  return $self->_type_labels->{$lang};
}

has _chamber_labels => (
  is      => 'ro',
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
    };
  }
);

sub chamber_labels {
  my ( $self, $lang ) = @_;
  return $self->_chamber_labels->{$lang};
}

has _publications => (
  is      => 'ro',
  default => sub {
    return {
      en => {
        sdebates    => 'Senate Debates',
        sjournals   => 'Senate Journals',
        scommittees => 'Senate Committees',
        sbills      => 'Senate Bills',
        sproc       => 'Senate Votes and Proceedings',
        srules      => 'Rules of the Senate',
        cdebates    => 'House of Commons Debates',
        cjournals   => 'House of Commons Journals',
        ccommittees => 'House of Commons Committees',
        cbills      => 'House of Commons Bills',
        cproc       => 'House of Commons Votes and Proceedings',
        corders     => 'Standing Orders of the House of Commons',
        csessional  => 'Sessional Papers'
      },
      fr => {
        sdebates    => 'Débats du Sénat',
        sjournals   => 'Journaux du Sénat',
        scommittees => 'Comités du Sénat',
        sbills      => 'Projets de loi du Sénat',
        sproc       => 'Procès-verbaux du Sénat',
        srules      => 'Règlement du Sénat',
        cdebates    => 'Débats de la Chambre des communes',
        cjournals   => 'Journaux de la Chambre des communes',
        ccommittees => 'Comités de la Chambre des communes',
        cbills      => 'Projets de loi de la Chambre des communes',
        cproc       => 'Procès-verbaux de la Chambre des communes',
        corders     => 'Règlement de la Chambre des communes',
        csessional  => 'Documents parlementaires'
      }
    };
  }
);

sub _ordinate {
  my ( $self, $num, $lang ) = @_;

  if ( $lang eq 'fr' ) {
    if ( $num == 1 ) {
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
  my ( $self, $node ) = @_;
  my $lang = $node->[0] eq 'fra' ? 'fr' : 'en';
  my $pub  = $self->_publications->{$lang}->{ $node->[1] . $node->[2] };

  if ( $node->[3] ) {
    my $pl      = $lang eq 'fr' ? 'Législature' : 'Parliament';
    my $p       = $self->_ordinate( ( substr $node->[3], 0, 2 ) + 0, $lang );
    my $s       = $self->_ordinate( ( substr $node->[3], 3, 1 ) + 0, $lang );
    my $session = "$p $pl, $s Session";
    return "$pub, $session";
  } else {
    return $pub;
  }
}
1;
