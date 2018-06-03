#line 1 "Bio/Tools/StateMachine/IOStateMachine.pm"
#-----------------------------------------------------------------
# $Id: IOStateMachine.pm,v 1.6 2002/10/22 07:38:49 lapp Exp $
#
# BioPerl module Bio::Tools::StateMachine::IOStateMachine
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

#line 75

#line 86

# Let the code begin...

package Bio::Tools::StateMachine::IOStateMachine;

use strict;
use vars qw( @ISA @EXPORT_OK );

use Bio::Root::IO;
use Bio::Tools::StateMachine::AbstractStateMachine qw($INITIAL_STATE $FINAL_STATE);

@ISA = qw( Bio::Root::IO
           Bio::Tools::StateMachine::AbstractStateMachine
         );

# Propagating the initial and final states from AbstractStateMachine
@EXPORT_OK = qw( $INITIAL_STATE $FINAL_STATE );

#line 111

sub _init_state_machine {
    my($self, @args) = @_;

    $self->SUPER::_init_state_machine(@args);

    my ($timeout) = $self->_rearrange( [qw(TIMEOUT_SECS)], @args);

    if( defined $timeout ) {
	if($timeout =~ /^\d+$/ ) {
	    $self->{'_timeout_secs'} = $timeout;
	}
	else {
	    $self->throw(-class =>'Bio::Root::BadParameter',
			 -text => "TIMEOUT_SECS must be a number: $timeout",
			 -value => $timeout
			);
	}
    }
}

#line 145

sub check_for_new_state {
    my ($self, $ignore_blank_lines) = @_;

    $self->verbose and print STDERR "Checking for new state...\n";

    my $chunk = $self->next_input_chunk();

    # Determine if we're supposed to ignore blanks and if so, loop
    # until we're either out of input or hit a non-blank line.
    if( defined $chunk && 
	$ignore_blank_lines and $chunk =~ /^\s*$/ ) {
        while(  $chunk = $self->next_input_chunk()) {
            last unless not $chunk or $chunk =~ /^\s*$/;
        }
    }

    $self->verbose and print STDERR "  Input chunk: " . $chunk, "\n";

    return $chunk;
}

#line 174

sub next_input_chunk {
    my $self = shift;

    $self->verbose and print STDERR "Getting next input chunk...\n", ;

    if(not defined $self->{'_alarm_available'}) {
        $self->_check_if_alarm_available();
    }

    $SIG{ALRM} = sub { die "Timed out!"; };

    my $chunk;

    eval {
        if( $self->{'_alarm_available'} and defined $self->{'_timeout_secs'}) {
	    alarm($self->{'_timeout_secs'});
	}

        $chunk = $self->_readline();

    };
    if($@ =~ /Timed out!/) {
	 $self->throw(-class => 'Bio::Root::IOException',
                      -text => "Timed out while waiting for input (timeout=$self->{'_timeout_secs'}s).");
     } elsif($@ =~ /\S/) {
         my $err = $@;
         $self->throw(-class => 'Bio::Root::IOException',
                      -text => "Unexpected error during readline: $err");
    }

    return $chunk;
}



# alarm() not available (ActiveState perl for win32 doesn't have it.
# See jitterbug PR#98)
sub _check_if_alarm_available {
    my $self = shift;
    eval {
        alarm(0);
    };
    if($@) {
        $self->{'_alarm_available'} = 0;
    }
    else {
        $self->{'_alarm_available'} = 1;
    }
}

sub append_input_cache {
    my ($self, $data) = @_;
    push( @{$self->{'_input_cache'}}, $data) if defined $data;
}

sub get_input_cache {
    my $self = shift;
    my @cache =  ();
    if( ref $self->{'_input_cache'} ) {
       @cache = @{$self->{'_input_cache'}};
    }
    return @cache;
}

sub clear_input_cache {
    my $self = shift;
    @{$self->{'_input_cache'}} = ();
}



1;



