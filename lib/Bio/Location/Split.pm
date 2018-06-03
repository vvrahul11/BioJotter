#line 1 "Bio/Location/Split.pm"
# $Id: Split.pm,v 1.35 2002/12/28 03:26:32 lapp Exp $
#
# BioPerl module for Bio::Location::SplitLocation
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

#line 71

# Let the code begin...


package Bio::Location::Split;
use vars qw(@ISA @CORBALOCATIONOPERATOR);
use strict;

use Bio::Root::Root;
use Bio::Location::SplitLocationI;
use Bio::Location::Atomic;

@ISA = qw(Bio::Location::Atomic Bio::Location::SplitLocationI );

BEGIN { 
    # as defined by BSANE 0.03
    @CORBALOCATIONOPERATOR= ('NONE','JOIN', undef, 'ORDER');  
}

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    # initialize
    $self->{'_sublocations'} = [];
    my ( $type, $seqid, $locations ) = 
	$self->_rearrange([qw(SPLITTYPE
                              SEQ_ID
			      LOCATIONS
                              )], @args);
    if( defined $locations && ref($locations) =~ /array/i ) {
	$self->add_sub_Location(@$locations);
    }
    $seqid  && $self->seq_id($seqid);
    $type = lc ($type);    
    $self->splittype($type || 'JOIN');
    return $self;
}

#line 121

sub each_Location {
    my ($self, $order) = @_;
    my @locs = ();
    foreach my $subloc ($self->sub_Location($order)) {
	# Recursively check to get hierarchical split locations:
	push @locs, $subloc->each_Location($order);
    }
    return @locs;
}

#line 150

sub sub_Location {
    my ($self, $order) = @_;
    $order = 0 unless defined $order;
    if( defined($order) && ($order !~ /^-?\d+$/) ) {
	$self->throw("value $order passed in to sub_Location is $order, an invalid value");
    } 
    $order = 1 if($order > 1);
    $order = -1 if($order < -1);

    my @sublocs = defined $self->{'_sublocations'} ? @{$self->{'_sublocations'}} : ();

    # return the array if no ordering requested
    return @sublocs if( ($order == 0) || (! @sublocs) );
    
    # sort those locations that are on the same sequence as the top (`master')
    # if the top seq is undefined, we take the first defined in a sublocation
    my $seqid = $self->seq_id();
    my $i = 0;
    while((! defined($seqid)) && ($i <= $#sublocs)) {
	$seqid = $sublocs[$i++]->seq_id();
    }
    if((! $self->seq_id()) && $seqid) {
	$self->warn("sorted sublocation array requested but ".
		    "root location doesn't define seq_id ".
		    "(at least one sublocation does!)");
    }
    my @locs = ($seqid ?
		grep { $_->seq_id() eq $seqid; } @sublocs :
		@sublocs);
    if(@locs) {
      if($order == 1) {
	  # Schwartzian transforms for performance boost	  
	  @locs = map { $_->[0] }
	  sort { (defined $a && defined $b) ? 
		     $a->[1] <=> $b->[1] : $a ? -1 : 1 }
	  map { [$_, $_->start] } @locs;

      } else { # $order == -1
	@locs = map {$_->[0]}
	        sort { 
		    (defined $a && defined $b) ? 
			$b->[1] <=> $a->[1] : $a ? -1 : 1 }
 	        map { [$_, $_->end] } @locs;
      }
    }
    # push the rest unsorted
    if($seqid) {
	push(@locs, grep { $_->seq_id() ne $seqid; } @sublocs);
    }
    # done!
    return @locs;
}

#line 213

sub add_sub_Location {
    my ($self,@args) = @_;
    my @locs;    
    foreach my $loc ( @args ) {
	if( !ref($loc) || ! $loc->isa('Bio::LocationI') ) {
	    $self->throw("Trying to add $loc as a sub Location but it doesn't implement Bio::LocationI!");
	    next;
	}	
	push @{$self->{'_sublocations'}}, $loc;
    }

    return scalar @{$self->{'_sublocations'}};
}

#line 237

sub splittype {
    my ($self, $value) = @_;
    if( defined $value || ! defined $self->{'_splittype'} ) {
	$value = 'JOIN' unless( defined $value );
	$self->{'_splittype'} = uc ($value);
    }
    return $self->{'_splittype'};
}

#line 265

sub is_single_sequence {
    my ($self) = @_;

    my $seqid = $self->seq_id();
    foreach my $loc ($self->sub_Location(0)) {
	$seqid = $loc->seq_id() if(! $seqid);
	if(defined($loc->seq_id()) && ($loc->seq_id() ne $seqid)) {
	    return 0;
	}
    }
    return 1;
}

#line 300

sub strand{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'strand'} = $value;
	# propagate to all sublocs
	foreach my $loc ($self->sub_Location(0)) {
	    $loc->strand($value) if ! $loc->is_remote();
	}
    } else {
	my ($strand, $lstrand);
	foreach my $loc ($self->sub_Location(0)) {
	    # we give up upon any location that's remote or doesn't have
	    # the strand specified, or has a differing one set than 
	    # previously seen.
	    # calling strand() is potentially expensive if the subloc is also
	    # a split location, so we cache it
	    $lstrand = $loc->strand();
	    if((! $lstrand) ||
	       ($strand && ($strand != $lstrand)) ||
	       $loc->is_remote()) {
		$strand = undef;
		last;
	    } elsif(! $strand) {
		$strand = $lstrand;
	    }
	}
	return $strand;
    }
}

#line 340

sub start {
    my ($self,$value) = @_;    
    if( defined $value ) {
	$self->throw("Trying to set the starting point of a split location, that is not possible, try manipulating the sub Locations");
    }
    return $self->SUPER::start();
}

#line 358

sub end {
    my ($self,$value) = @_;    
    if( defined $value ) {
	$self->throw("Trying to set the ending point of a split location, that is not possible, try manipulating the sub Locations");
    }
    return $self->SUPER::end();
}

#line 376

sub min_start {
    my ($self, $value) = @_;    

    if( defined $value ) {
	$self->throw("Trying to set the minimum starting point of a split location, that is not possible, try manipulating the sub Locations");
    }
    my @locs = $self->sub_Location(1);
    return $locs[0]->min_start() if @locs; 
    return undef;
}

#line 397

sub max_start {
    my ($self,$value) = @_;

    if( defined $value ) {
	$self->throw("Trying to set the maximum starting point of a split location, that is not possible, try manipulating the sub Locations");
    }
    my @locs = $self->sub_Location(1);
    return $locs[0]->max_start() if @locs; 
    return undef;
}

#line 419

sub start_pos_type {
    my ($self,$value) = @_;

    if( defined $value ) {
	$self->throw("Trying to set the start_pos_type of a split location, that is not possible, try manipulating the sub Locations");
    }
    my @locs = $self->sub_Location();
    return ( @locs ) ? $locs[0]->start_pos_type() : undef;    
}

#line 439

sub min_end {
    my ($self,$value) = @_;

    if( defined $value ) {
	$self->throw("Trying to set the minimum end point of a split location, that is not possible, try manipulating the sub Locations");
    }
    # reverse sort locations by largest ending to smallest ending
    my @locs = $self->sub_Location(-1);
    return $locs[0]->min_end() if @locs; 
    return undef;
}

#line 461

sub max_end {
    my ($self,$value) = @_;

    if( defined $value ) {
	$self->throw("Trying to set the maximum end point of a split location, that is not possible, try manipulating the sub Locations");
    }
    # reverse sort locations by largest ending to smallest ending
    my @locs = $self->sub_Location(-1);
    return $locs[0]->max_end() if @locs; 
    return undef;
}

#line 484

sub end_pos_type {
    my ($self,$value) = @_;

    if( defined $value ) {
	$self->throw("Trying to set end_pos_type of a split location, that is not possible, try manipulating the sub Locations");
    }
    my @locs = $self->sub_Location();
    return ( @locs ) ? $locs[0]->end_pos_type() : undef;    
}


#line 509

sub seq_id {
    my ($self, $seqid) = @_;

    if(! $self->is_remote()) {
	foreach my $subloc ($self->sub_Location(0)) {
	    $subloc->seq_id($seqid) if ! $subloc->is_remote();
	}
    }
    return $self->SUPER::seq_id($seqid);
}

#line 555

sub to_FTstring {
    my ($self) = @_;
    my @strs;
    foreach my $loc ( $self->sub_Location() ) {	
	my $str = $loc->to_FTstring();
	# we only append the remote seq_id if it hasn't been done already
	# by the sub-location (which it should if it knows it's remote)
	# (and of course only if it's necessary)
	if( (! $loc->is_remote) &&
	    defined($self->seq_id) && defined($loc->seq_id) &&
	    ($loc->seq_id ne $self->seq_id) ) {
	    $str = sprintf("%s:%s", $loc->seq_id, $str);
	} 
	push @strs, $str;
    }    

    my $str = sprintf("%s(%s)",lc $self->splittype, join(",", @strs));
    return $str;
}

# we'll probably need to override the RangeI methods since our locations will
# not be contiguous.

1;
