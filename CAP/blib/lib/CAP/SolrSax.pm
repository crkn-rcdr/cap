package CAP::SolrSAX;
use strict;
use warnings;

use Time::HiRes qw/gettimeofday/;

sub new
{
    my($type) = @_;
    my $data = {};
    return bless($data, $type);
}

sub start_document
{
    my($self, $document) = @_;
    $self->{time} = gettimeofday();
    $self->{docs} = [];
    $self->{context} = [];
    $self->{nelements} = 0;
}

sub end_document
{
    my($self, $document) = @_;
    $self->{time} = int(1000 * (gettimeofday() - $self->{time}));
    warn "!! Processing $self->{nelements} elements took: $self->{time} ms\n";
}

sub start_element
{
    my($self, $element) = @_;
    push(@{$self->{context}}, $element->{Name});
    ++$self->{nelements};
    #warn "!! Context: " . join('/', @{$self->{context}});
}

sub end_element
{
    my($self, $element) = @_;
    pop(@{$self->{context}});
}

sub characters
{
    my($self, $characters) = @_;
}

sub dump
{
    my($self) = @_;
    use Data::Dumper;
    warn Dumper($self->{docs});
}

1;
