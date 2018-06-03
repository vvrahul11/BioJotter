#line 1 "Bio/Location/Atomic.pm"
# $Id: Atomic.pm,v 1.6 2002/12/01 00:05:20 jason Exp $
#
# BioPerl module for Bio::Location::Atomic
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

#line 61

# Let the code begin...


package Bio::Location::Atomic;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::LocationI;


@ISA = qw(Bio::Root::Root Bio::LocationI);

sub new { 
    my ($class, @args) = @_;
    my $self = {};

    bless $self,$class;

    my ($v,$start,$end,$strand,$seqid) = $self->_rearrange([qw(VERBOSE
							       START
							       END
							       STRAND
							       SEQ_ID)],@args);
    defined $v && $self->verbose($v);
    defined $strand && $self->strand($strand);

    defined $start  && $self->start($start);
    defined $end    && $self->end($end);
    if( defined $self->start && defined $self->end &&
	$self->start > $self->end && $self->strand != -1 ) {
	$self->warn("When building a location, start ($start) is expected to be less than end ($end), ".
		    "however it was not. Switching start and end and setting strand to -1");

	$self->strand(-1);
	my $e = $self->end;
	my $s = $self->start;
	$self->start($e);
	$self->end($s);
    }
    $seqid          && $self->seq_id($seqid);

    return $self;
}

#line 117

sub start {
  my ($self, $value) = @_;
  $self->min_start($value) if( defined $value );
  return $self->SUPER::start();
}

#line 134

sub end {
  my ($self, $value) = @_;

  $self->min_end($value) if( defined $value );
  return $self->SUPER::end();
}

#line 152

sub strand {
  my ($self, $value) = @_;

  if ( defined $value ) {
       if ( $value eq '+' ) { $value = 1; }
       elsif ( $value eq '-' ) { $value = -1; }
       elsif ( $value eq '.' ) { $value = 0; }
       elsif ( $value != -1 && $value != 1 && $value != 0 ) {
	   $self->throw("$value is not a valid strand info");
       }
       $self->{'_strand'} = $value
   }
  # let's go ahead and force to '0' if
  # we are requesting the strand without it
  # having been set previously
   return $self->{'_strand'} || 0;
}

#line 182

sub length {
   my ($self) = @_;
   return abs($self->end() - $self->start()) + 1;
}

#line 197

sub min_start {
    my ($self,$value) = @_;

    if(defined($value)) {
	$self->{'_start'} = $value;
    }
    return $self->{'_start'};
}

#line 219

sub max_start {
    my ($self,@args) = @_;
    return $self->min_start(@args);
}

#line 238

sub start_pos_type {
    my($self) = @_;
    return 'EXACT';
}

#line 253

sub min_end {
    my($self,$value) = @_;

    if(defined($value)) {
	$self->{'_end'} = $value;
    }
    return $self->{'_end'};
}

#line 275

sub max_end {
    my($self,@args) = @_;
    return $self->min_end(@args);
}

#line 294

sub end_pos_type {
    my($self) = @_;
    return 'EXACT';
}

#line 309

sub location_type {
    my ($self) = @_;
    return 'EXACT';
}

#line 325

sub is_remote {
   my $self = shift;
   if( @_ ) {
       my $value = shift;
       $self->{'is_remote'} = $value;
   }
   return $self->{'is_remote'};

}

#line 349

sub each_Location {
   my ($self) = @_;
   return ($self);
}

#line 364

sub to_FTstring { 
    my($self) = @_;
    if( $self->start == $self->end ) {
	return $self->start;
    }
    my $str = $self->start . ".." . $self->end;
    if( $self->strand == -1 ) {
	$str = sprintf("complement(%s)", $str);
    }
    return $str;
}


sub trunc {
  my ($self,$start,$end,$relative_ori) = @_;

  my $newstart  = $self->start - $start+1;
  my $newend    = $self->end   - $start+1;
  my $newstrand = $relative_ori * $self->strand;

  my $out;
  if( $newstart < 1 || $newend > ($end-$start+1) ) {
    $out = Bio::Location::Atomic->new();
    $out->start($self->start);
    $out->end($self->end);
    $out->strand($self->strand);
    $out->seq_id($self->seqid);
    $out->is_remote(1);
  } else {
    $out = Bio::Location::Atomic->new();
    $out->start($newstart);
    $out->end($newend);
    $out->strand($newstrand);
    $out->seq_id();
  }

  return $out;
}

1;

