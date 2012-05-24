package CAP::Schema::ResultSet::Slide;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use POSIX qw(strftime);

sub get_slides {
    my ($self, $portal, $slideshow) = @_;
    my @slide_records = $self->search({ portal => $portal, slideshow => $slideshow }, { order_by => { -asc => 'sort' } });
    my $slides = [];
    foreach my $record (@slide_records) {
        my $slide = {
            id => $record->id,
            url => $record->url,
            thumb_url => $record->thumb_url,
            'sort' => $record->get_column('sort'),
            descriptions => {},
        };
        foreach my $desc ($record->search_related('slide_descriptions')) {
            $slide->{descriptions}->{$desc->lang} = $desc->description;
        }
        push($slides, $slide);
    }
    return $slides;
}

1;
