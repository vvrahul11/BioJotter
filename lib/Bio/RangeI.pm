#line 1 "Bio/RangeI.pm"
# $Id: RangeI.pm,v 1.30 2002/11/05 02:55:12 lapp Exp $
#
# BioPerl module for Bio::RangeI
#
# Cared for by Lehvaslaiho <heikki@ebi.ac.uk>
#
# Copyright Matthew Pocock
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

#line 74

package Bio::RangeI;

use strict;
use Carp;
use Bio::Root::RootI;
use vars qw(@ISA);
use integer;
use vars qw( @ISA %STRAND_OPTIONS );

@ISA = qw( Bio::Root::RootI );

BEGIN {
# STRAND_OPTIONS contains the legal values for the strand options
    %STRAND_OPTIONS = map { $_, '_'.$_ }
    (
     'strong', # ranges must have the same strand
     'weak',   # ranges must have the same strand or no strand
     'ignore', # ignore strand information
     );
}

# utility methods
#

# returns true if strands are equal and non-zero
sub _strong {
    my ($r1, $r2) = @_;
    my ($s1, $s2) = ($r1->strand(), $r2->strand());
    
    return 1 if $s1 != 0 && $s1 == $s2;
}

# returns true if strands are equal or either is zero
sub _weak {
    my ($r1, $r2) = @_;
    my ($s1, $s2) = ($r1->strand(), $r2->strand());
    return 1 if $s1 == 0 || $s2 == 0 || $s1 == $s2;
}

# returns true for any strandedness
sub _ignore {
    return 1;
}

# works out what test to use for the strictness and returns true/false
# e.g. $r1->_testStrand($r2, 'strong')
sub _testStrand() {
    my ($r1, $r2, $comp) = @_;
    return 1 unless $comp;
    my $func = $STRAND_OPTIONS{$comp};
    return $r1->$func($r2);
}

#line 142

sub start {
    shift->throw_not_implemented();
}

#line 157

sub end {
    shift->throw_not_implemented();
}

#line 172

sub length {
    shift->throw_not_implemented();
}

#line 187

sub strand {
    shift->throw_not_implemented();
}

#line 209

sub overlaps {
    my ($self, $other, $so) = @_;
    
    $self->throw("start is undefined") unless defined $self->start;
    $self->throw("end is undefined") unless defined $self->end;
    $self->throw("not a Bio::RangeI object") unless defined $other && 
	$other->isa('Bio::RangeI');
    $other->throw("start is undefined") unless defined $other->start;
    $other->throw("end is undefined") unless defined $other->end;
    
    return
	($self->_testStrand($other, $so) 
	 and not (
		  ($self->start() > $other->end() or
		   $self->end() < $other->start()   )
		  ));
}

#line 239

sub contains {
  my ($self, $other, $so) = @_;
  $self->throw("start is undefined") unless defined $self->start;
  $self->throw("end is undefined") unless defined $self->end;

  if(defined $other && ref $other) { # a range object?
      $other->throw("Not a Bio::RangeI object") unless  $other->isa('Bio::RangeI');
      $other->throw("start is undefined") unless defined $other->start;
      $other->throw("end is undefined") unless defined $other->end;

      return ($self->_testStrand($other, $so)      and
	      $other->start() >= $self->start() and
	      $other->end() <= $self->end());
  } else { # a scalar?
      $self->throw("'$other' is not an integer.\n") unless $other =~ /^[-+]?\d+$/;
      return ($other >= $self->start() and $other <= $self->end());
  }
}

#line 268

sub equals {
    my ($self, $other, $so) = @_;

    $self->throw("start is undefined") unless defined $self->start;
    $self->throw("end is undefined") unless defined $self->end;
    $other->throw("Not a Bio::RangeI object") unless  $other->isa('Bio::RangeI');
    $other->throw("start is undefined") unless defined $other->start;
    $other->throw("end is undefined") unless defined $other->end;

    return ($self->_testStrand($other, $so)   and
	    $self->start() == $other->start() and
	    $self->end()   == $other->end()       );
}

#line 302

sub intersection {
    my ($self, $other, $so) = @_;
    return unless $self->_testStrand($other, $so);

    $self->throw("start is undefined") unless defined $self->start;
    $self->throw("end is undefined") unless defined $self->end;
    $other->throw("Not a Bio::RangeI object") unless  $other->isa('Bio::RangeI');
    $other->throw("start is undefined") unless defined $other->start;
    $other->throw("end is undefined") unless defined $other->end;

    my @start = sort {$a<=>$b}
    ($self->start(), $other->start());
    my @end   = sort {$a<=>$b}
    ($self->end(),   $other->end());

    my $start = pop @start;
    my $end = shift @end;

    my $union_strand;  # Strand for the union range object.

    if($self->strand == $other->strand) {
	$union_strand = $other->strand;
    } else {
	$union_strand = 0;
    }

    if($start > $end) {
	return undef;
    } else {
	return $self->new('-start' => $start,
			  '-end' => $end,
			  '-strand' => $union_strand
			  );
	#return ($start, $end, $union_strand);
    }
}

#line 351

sub union {
    my $self = shift;
    my @ranges = @_;
    if(ref $self) {
	unshift @ranges, $self;
    }

    my @start = sort {$a<=>$b}
    map( { $_->start() } @ranges);
    my @end   = sort {$a<=>$b}
    map( { $_->end()   } @ranges);

    my $start = shift @start;
    while( !defined $start ) {
	$start = shift @start;
    }

    my $end = pop @end;

    my $union_strand;  # Strand for the union range object.

    foreach(@ranges) {
	if(! defined $union_strand) {
	    $union_strand = $_->strand;
	    next;
	} else {
	    if($union_strand ne $_->strand) {
		$union_strand = 0;
		last;
	    }
	}
    }
    return undef unless $start or $end;
    if( wantarray() ) {
	return ( $start,$end,$union_strand);
    } else { 
	return $self->new('-start' => $start,
			  '-end' => $end,
			  '-strand' => $union_strand
			  );
    }
}

#line 410

sub overlap_extent{
    my ($a,$b) = @_;

    $a->throw("start is undefined") unless defined $a->start;
    $a->throw("end is undefined") unless defined $a->end;
    $b->throw("Not a Bio::RangeI object") unless  $b->isa('Bio::RangeI');
    $b->throw("start is undefined") unless defined $b->start;
    $b->throw("end is undefined") unless defined $b->end;
    
    my ($au,$bu,$is,$ie);
    if( ! $a->overlaps($b) ) {
	return ($a->length,0,$b->length);
    }

    if( $a->start < $b->start ) {
	$au = $b->start - $a->start;
    } else {
	$bu = $a->start - $b->start;
    }

    if( $a->end > $b->end ) {
	$au += $a->end - $b->end;
    } else {
	$bu += $b->end - $a->end;
    }
    my $intersect = $a->intersection($b);
    $ie = $intersect->end;
    $is = $intersect->start;

    return ($au,$ie-$is+1,$bu);
}

1;
