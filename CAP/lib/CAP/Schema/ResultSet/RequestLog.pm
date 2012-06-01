package CAP::Schema::ResultSet::RequestLog;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use POSIX qw(strftime);

# Log the current request.
sub log {

    my ( $self, $c ) = @_;

    my $get_id;
    eval { $get_id = $c->session->{auth}->{user}->id }; # have to do an eval because accessor throws exception if there's no user id
    my $user_id =
      $@ ? undef : $get_id;    # theoretically we shouldn't need this line

    my $institution_id = $c->session->{subscribing_institution_id} || undef;

    my $args = join( "/", @{ $c->request->arguments } );

    $self->create(
        {
            'time'    => strftime( '%Y-%m-%d %H:%M:%S', localtime(time) ),
            'user_id' => $user_id,
            'institution_id' => $institution_id,
            'session'        => $c->sessionid,
            'session_count'  => $c->session->{count},
            'portal'         => $c->stash->{portal},
            'view'           => $c->stash->{current_view},
            'action'         => $c->request->action,
            'args'           => $args
        }
    );
}

sub get_monthly_stats {

    my ( $self, $institution_id, $month, $year ) = @_;

    # get the number of searches
    my $search_logs = $self->search(
        {
            'month(time)'    => $month,
            'year(time)'     => $year,
            'institution_id' => $institution_id,
            'action'         => 'search'
        }
    );
    my $search_count = $search_logs->count;

    # get the numebr of views    
    my $view_logs = $self->search(
        {
            'month(time)'    => $month,
            'year(time)'     => $year,
            'institution_id' => $institution_id,
            -or =>  [
                      {'action'  => 'view'},
                      {'action'  => 'file/get_page_uri'} 
                    ]
        }
    ); 
    my $view_count = $view_logs->count;

    # get the number of sessions    
    my $session_logs = $self->search(
        {
            'month(time)'    => $month,
            'year(time)'     => $year,
            'institution_id' => $institution_id

        },        
        {
            columns  => [ 'session' ],
            distinct => 1
        }
    );      
    my $session_count = $session_logs->count;
    
    # Return everything as a hash reference
    my $stats = {
                  searches  => $search_count,
                  views     => $view_count,
                  sessions  => $session_count                  
                };
    
    return $stats;
}

sub get_start {

    # Returns a timedate object of first first entry in table
    my ( $self ) = @_;

    # search by date in ascending order    
    my $search_min = $self->search(
        {},        
        {
            order_by => { -asc => 'time' }
        }
    );
    my $result = $search_min->next;
    my $date = $result->time;
    
    return $date;
}

1;
