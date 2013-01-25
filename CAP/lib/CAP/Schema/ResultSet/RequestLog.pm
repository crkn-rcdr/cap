package CAP::Schema::ResultSet::RequestLog;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use POSIX qw(strftime);

# Log the current request.
sub log {

    my ( $self, $c ) = @_;

    my $user_id = $c->user_exists() ? $c->user->id : undef;

    my $institution = $c->session->{$c->portal->id}->{subscribing_institution};
    my $institution_id = $institution ? $institution->{id} : 0;

    my $args = join( "/", @{ $c->request->arguments } );

    $self->create(
        {
            'time'    => strftime( '%Y-%m-%d %H:%M:%S', localtime(time) ),
            'user_id' => $user_id,
            'institution_id' => $institution_id,
            'session'        => $c->sessionid,
            'session_count'  => $c->session->{count},
            'portal'         => $c->portal->id,
            'view'           => $c->stash->{current_view},
            'action'         => $c->request->action,
            'args'           => $args
        }
    );
}

sub get_monthly_inst_stats {

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
    
    # get the number of requests    
    my $request_logs = $self->search(
        {
            'month(time)'    => $month,
            'year(time)'     => $year,
            'institution_id' => $institution_id

        }        
    );      
    my $request_count = $request_logs->count;   
    
    # Return everything as a hash reference

    my $stats = { 
                  searches       => $search_count,
                  page_views     => $view_count,
                  sessions       => $session_count,
                  requests       => $request_count                  
                };
    
    return $stats;
}

sub get_monthly_portal_stats {

    my ( $self, $portal, $month, $year ) = @_;

    # get the number of searches
    my $search_logs = $self->search(
        {
            'month(time)'    => $month,
            'year(time)'     => $year,
            'portal'         => $portal,
            'action'         => 'search'
        }
    );
    my $search_count = $search_logs->count;

    # get the number of views    
    my $view_logs = $self->search(
        {
            'month(time)'    => $month,
            'year(time)'     => $year,
            'portal'         => $portal,
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
            'portal'         => $portal

        },        
        {
            columns  => [ 'session' ],
            distinct => 1
        }
    );      
    my $session_count = $session_logs->count;
    
    # get the number of requests    
    my $request_logs = $self->search(
        {
            'month(time)'    => $month,
            'year(time)'     => $year,
            'portal'         => $portal

        }        
    );      
    my $request_count = $request_logs->count;   
    
    # Return everything as a hash reference

    my $stats = { 
                  searches       => $search_count,
                  page_views     => $view_count,
                  sessions       => $session_count,
                  requests       => $request_count                  
                };
    
    return $stats;
}

sub get_start {

    # Returns a timedate object of first entry in table
    my ( $self ) = @_;

    # search by date in ascending order
    # we do it this way because we want a date object, not a string    
    my $search_min = $self->search(
        { time => { 'IS NOT' => undef } },        
        {
            order_by => { -asc => 'time' }
        }
    );
    my $result = $search_min->next;
    my $date = $result->time;
    use Data::Dumper;
    warn Dumper($result);
    
    return $date;
}

sub get_institutions {

  my ($self, $c) = @_;
  
  my $rs = $self->search(
    { institution_id => { 'IS NOT' => undef } },
    {
      columns => 'institution_id',
      distinct => 1
    }
  );
  
  my $institutions = [];
  my $row;
  my $inst;
  my $value;
  while ($row = $rs->next()) {
     $inst = $row->institution_id->id;
     push (@$institutions, $inst);   
  }
  return $institutions;
  
}

sub get_portals {

  my ($self, $c) = @_;
  
  my $rs = $self->search(
    { portal => { 'IS NOT' => undef } },
    {
      columns => 'portal',
      distinct => 1
    }
  );
  
  my $portals = [];
  my $row;
  my $portal;
  my $value;
  while ($row = $rs->next()) {
     $portal = $row->portal;
     push (@$portals, $portal);   
  }
  return $portals;
  
}

1;
