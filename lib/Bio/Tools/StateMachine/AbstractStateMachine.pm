#line 1 "Bio/Tools/StateMachine/AbstractStateMachine.pm"
#-----------------------------------------------------------------
# $Id: AbstractStateMachine.pm,v 1.9 2002/10/22 07:38:49 lapp Exp $
#
# BioPerl module Bio::Tools::StateMachine::AbstractStateMachine
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

#line 208

#line 219


# Let the code begin...

package Bio::Tools::StateMachine::AbstractStateMachine;

use strict;
use Bio::Root::RootI;
use Exporter ();

use vars qw( @ISA @EXPORT_OK $INITIAL_STATE $FINAL_STATE $PAUSE_STATE $ERROR_STATE );
@ISA = qw( Bio::Root::RootI  Exporter );
@EXPORT_OK = qw( $INITIAL_STATE $FINAL_STATE $PAUSE_STATE $ERROR_STATE );

@Bio::Tools::StateMachine::StateException::ISA = qw( Bio::Root::Exception );

$INITIAL_STATE = 'Initial';
$FINAL_STATE = 'Final';
$PAUSE_STATE = 'Pause';
$ERROR_STATE = 'Error';

sub _init_state_machine {
    my  ($self, @args ) = @_;
    my ($transition_table) = $self->_rearrange( [qw(TRANSITION_TABLE)], @args);

    $self->verbose and print STDERR "Initializing State Machine...\n";

    if($transition_table) {
        $self->_set_transition_table( $transition_table );
    }

    $self->add_transition( $INITIAL_STATE, $FINAL_STATE );
    $self->_set_current_state( $INITIAL_STATE );
}

sub reset {
    my $self = shift;
    $self->verbose and print STDERR "Resetting state machine\n";
    $self->_set_current_state( $INITIAL_STATE );
}

sub _set_current_state {
    my ($self, $state) = @_;
    if( defined $state) {
	$self->verbose and print STDERR "  setting current state to $state\n";
	$self->{'_current_state'} = $state;
    }
}

sub current_state { shift->{'_current_state'} }

sub initial_state { $INITIAL_STATE }

sub final_state { $FINAL_STATE }

sub pause_state { $PAUSE_STATE }

sub error_state { $ERROR_STATE }

sub resume_state {
    my ($self, $state) = @_;
    if( $state ) {
      $self->{'_resume_state'} = $state;
    }
    $self->{'_resume_state'};
}

sub _clear_resume_state {
    my $self = shift;
    undef $self->{'_resume_state'};
}

#line 298

sub running { shift->{'_running'} }

sub _set_running {
    my $self = shift;
    $self->{'_running'} = shift;
}

sub run {
    my ($self, @args) = @_;

    my $verbose = $self->verbose;
    my $curr_state = $self->current_state;
    $self->_set_running( 1 );

    while( not ($curr_state eq $PAUSE_STATE ||
                $curr_state eq $ERROR_STATE ||
                $curr_state eq $FINAL_STATE )) {

	$verbose and print STDERR "Current state (run): ${\$self->current_state}\n";

        if( my $state = $self->check_for_new_state()) {
            $self->change_state( $state );
        }

        $curr_state = $self->current_state;
    }

    # Handle EOF situations
    if( not ($curr_state eq $PAUSE_STATE ||
             $curr_state eq $FINAL_STATE )) {

        $self->change_state( $FINAL_STATE );
	$self->_set_running( 0 );
    }

    $verbose and print STDERR "StateMachine Run complete ($curr_state).\n";
}

# The pause() and resume() methods don't go through change_state()
sub pause {
    my ($self) = @_;
#    print "PAUSING...\n";
    $self->resume_state( $self->current_state );
    $self->_set_current_state( $PAUSE_STATE );
#    print "After pause(): Current state: ${\$self->current_state}\n";
}

sub paused {
    my ($self) = @_;
    return $self->current_state eq $PAUSE_STATE;
}

sub throw{
   my ($self,@args) = @_;
   $self->_set_current_state( $ERROR_STATE );
   $self->_set_running( 0 );
   $self->SUPER::throw( @args );
}

sub error {
    my ($self, $err) = @_;
    return $self->current_state eq $ERROR_STATE;
}

sub resume {
    my ($self) = @_;

    # Don't resume if we're done.
    return if $self->current_state eq $FINAL_STATE;

#    print "RESUMING...\n";
    $self->_set_current_state( $self->resume_state );
    $self->_clear_resume_state;
    $self->run();
}

#line 390

sub transition_table {
    my ($self) = @_;

    return @{$self->{'_transition_table'}};
}

sub _set_transition_table {
    my ($self, $table_ref) = @_;

    my $verbose = $self->verbose;
    $verbose and print STDERR "Setting state transition table:\n";

    if( not ref($table_ref) eq 'ARRAY') {
	$self->throw( -class => 'Bio::Root::BadParameter',
                      -text => "Can't set state transition table: Arg wasn't an array reference."
                    );
    }

    foreach my $t (@$table_ref) {
        if( ref($t) and scalar(@$t) == 2 ) {
            push @{$self->{'_transition_table'}->{$t->[0]}}, $t->[1];
            $verbose and print STDERR "  adding: $t->[0] -> $t->[1]\n";
        }
        else {
            $self->throw( -class => 'Bio::Root::BadParameter',
                          -text => "Can't add state transition from table: Not a 2-element array reference ($t)"
                        );
        }
    }
}

#line 431

sub add_transition {
    my ($self, $from, $to) = @_;

    if( defined($from) and defined($to) ) {
	push @{$self->{'_transition_table'}->{$from}}, $to;
    }
    else {
	$self->throw( -class => 'Bio::Root::BadParameter',
                      -text => "Can't add state transition: Insufficient arguments."
                    );
    }
}


#line 462

sub change_state {
    my ($self, $new_state) = @_;

    $self->verbose and print STDERR "  changing state to $new_state\n";

    if ( $self->validate_transition( $self->current_state, $new_state, 1 ) ) {
      $self->finalize_state_change( $new_state, 1 );
    }

}


#line 481

sub get_transitions_from {
    my ($self, $state) = @_;

    my @trans = ();
    if( ref $self->{'_transition_table'}->{$state}) {
        @trans = @{$self->{'_transition_table'}->{$state}};
    }

    return @trans;
}

#line 508

sub validate_transition {
    my ($self, $from_state, $to_state ) = @_;

    #print STDERR "  validating transition $from_state -> $to_state\n";

    if( not( defined($from_state) and defined($to_state))) {
        $self->throw( -class => 'Bio::Root::BadParameter',
                      -text => "Can't validate state transition: Insufficient arguments.");
    }

    my $is_valid = 0;

    foreach my $t ( $self->get_transitions_from( $from_state ) ) {
        if( $t eq $to_state ) {
#        if( $t->[1] eq $to_state ) {
            $is_valid = 1;
            last;
        }
    }

    if( not $is_valid ) {
        $self->throw( -class => 'Bio::Tools::StateMachine::StateException',
                      -text => "The desired state change is not valid for this machine: $from_state -> $to_state");
    }

    #print STDERR "  valid!\n";

    return $to_state;
}

#line 555

sub check_for_new_state {
    my ($self, $data) = @_;
    $self->throw_not_implemented;
}

sub append_input_cache {
    my ($self, $data) = @_;
}

sub get_input_cache {
    my $self = shift;
}

sub clear_input_cache {
    my $self = shift;
}

sub state_change_cache {
    my ($self, $data) = @_;
    if( defined $data ) {
        $self->{'_state_change_cache'} = $data;
    }
    return $self->{'_state_change_cache'};
}

sub clear_state_change_cache {
    my ($self, $data) = @_;
    $self->{'_state_change_cache'} = undef;
}


#line 598

sub finalize_state_change {
    my ($self, $to_state, $clear_input_cache ) = @_;

    if( $self->paused ) {
        $self->resume_state( $to_state );
    }
    else {
        $self->_set_current_state( $to_state );
    }
    $self->clear_input_cache() if $clear_input_cache;
    $self->append_input_cache( $self->state_change_cache );
    $self->clear_state_change_cache();
}


1;


