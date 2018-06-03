#line 1 "Bio/LocatableSeq.pm"
# $Id: LocatableSeq.pm,v 1.22.2.1 2003/03/31 11:49:51 heikki Exp $
#
# BioPerl module for Bio::LocatableSeq
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 82

#'
# Let the code begin...

package Bio::LocatableSeq;
use vars qw(@ISA);
use strict;

use Bio::PrimarySeq;
use Bio::RangeI;
use Bio::Location::Simple;
use Bio::Location::Fuzzy;


@ISA = qw(Bio::PrimarySeq Bio::RangeI);

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my ($start,$end,$strand) =
	$self->_rearrange( [qw(START END STRAND)],
			   @args);

    defined $start && $self->start($start);
    defined $end   && $self->end($end);
    defined $strand && $self->strand($strand);

    return $self; # success - we hope!
}

#line 122

sub start{
   my $self = shift;
   if( @_ ) {
      my $value = shift;
      $self->{'start'} = $value;
    }
    return $self->{'start'};

}

#line 142

sub end {
   my $self = shift;
   if( @_ ) {
      my $value = shift;
      my $string = $self->seq;
      if ($string and $self->start) {
	  my $s2 = $string;
	  $string =~ s/[.-]+//g;
	  my $len = CORE::length $string;
	  my $new_end = $self->start + $len - 1 ;
	  my $id = $self->id;
	  $self->warn("In sequence $id residue count gives value $len.
Overriding value [$value] with value $new_end for Bio::LocatableSeq::end().")
	      and $value = $new_end if $new_end != $value and $self->verbose > 0;
      }

      $self->{'end'} = $value;
    }
    return $self->{'end'};

}

#line 174

sub strand{
   my $self = shift;
   if( @_ ) {
      my $value = shift;
      $self->{'strand'} = $value;
    }
    return $self->{'strand'};
}

#line 194

sub get_nse{
   my ($self,$char1,$char2) = @_;

   $char1 ||= "/";
   $char2 ||= "-";

   $self->throw("Attribute id not set") unless $self->id();
   $self->throw("Attribute start not set") unless $self->start();
   $self->throw("Attribute end not set") unless $self->end();

   return $self->id() . $char1 . $self->start . $char2 . $self->end ;

}


#line 227

sub no_gaps {
    my ($self,$char) = @_;
    my ($seq, $count) = (undef, 0);

    # default gap characters
    $char ||= '-.';

    $self->warn("I hope you know what you are doing setting gap to [$char]")
	unless $char =~ /[-.]/;

    $seq = $self->seq;
    return 0 unless $seq; # empty sequence does not have gaps

    $seq =~ s/^([$char]+)//;
    $seq =~ s/([$char]+)$//;
    $count++ while $seq =~ /[$char]+/g;

    return $count;

}


#line 274

sub column_from_residue_number {
    my ($self, $resnumber) = @_;

    $self->throw("Residue number has to be a positive integer, not [$resnumber]")
	unless $resnumber =~ /^\d+$/ and $resnumber > 0;

    if ($resnumber >= $self->start() and $resnumber <= $self->end()) {
	my @residues = split //, $self->seq;
	my $count = $self->start();
	my $i;
	for ($i=0; $i < @residues; $i++) {
	    if ($residues[$i] ne '.' and $residues[$i] ne '-') {
		$count == $resnumber and last;
		$count++;
	    }
	}
	# $i now holds the index of the column.
        # The actual column number is this index + 1
	
	return $i+1;
    }

    $self->throw("Could not find residue number $resnumber");

}


#line 340

sub location_from_column {
    my ($self, $column) = @_;

    $self->throw("Column number has to be a positive integer, not [$column]")
	unless $column =~ /^\d+$/ and $column > 0;
    $self->throw("Column number [column] is larger than".
		 " sequence length [". $self->length. "]")
	unless $column <= $self->length;

    my ($loc);
    my $s = $self->subseq(1,$column);
    $s =~ s/\W//g;
    my $pos = CORE::length $s;

    my $start = $self->start || 0 ;
    if ($self->subseq($column, $column) =~ /[a-zA-Z]/ ) {
	$loc = new Bio::Location::Simple
	    (-start => $pos + $start - 1,
	     -end => $pos + $start - 1,
	     -strand => 1
	     );
    }
    elsif ($pos == 0 and $self->start == 1) {
    } else {
	$loc = new Bio::Location::Simple
	    (-start => $pos + $start - 1,
	     -end => $pos +1 + $start - 1,
	     -strand => 1,
	     -location_type => 'IN-BETWEEN'
	     );
    }
    return $loc;
}

#line 388

sub revcom {
    my ($self) = @_;

    my $new = $self->SUPER::revcom;
    $new->strand($self->strand * -1);
    $new->start($self->start) if $self->start;
    $new->end($self->end) if $self->end;
    return $new;
}


#line 413

sub trunc {

    my ($self, $start, $end) = @_;
    my $new = $self->SUPER::trunc($start, $end);

    $start = $self->location_from_column($start);
    $start ? ($start = $start->start) : ($start = 1);

    $end = $self->location_from_column($end);
    $end = $end->start if $end;

    $new->strand($self->strand);
    $new->start($start) if $start;
    $new->end($end) if $end;

    return $new;
}

1;
