package CAP::Schema::ResultSet::Feedback;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';
use base 'DBIx::Class::Row';
use POSIX qw(strftime);


sub insert_feedback
{
    ## inserts new row into feedback table
    my ($self, $userid, $submitted, $feedback) = @_;

    my $create = $self->create(
        {

            user_id    =>   $userid,
            submitted  =>   $submitted,
            feedback   =>   $feedback

        }
    );

    return $create;
}


sub get_row
{
    # returns an arrayref of all the values in the row for a given user_id
    my($self, $user_id) = @_;
           
    my $check_user_id =  $self->search(
         {
                                
             user_id => $user_id
                                  
         }         
    );
    my $getrow = $check_user_id->next();
    my $row = defined($getrow) ? $getrow : 0;

    return $row;
}


sub update_feedback
{
    # updates feedback row for admin user 
    my ($self, $userid, $resolved, $comments) = @_;

    my $update = $self->update({

            resolved   =>   $resolved,
            comments  =>    $comments

        },
        {

            user_id    =>   $userid

        }
    );

    return $update;
}


1;
