#line 1 "Bio/Location/Simple.pm"
# $Id: Simple.pm,v 1.31 2002/10/22 07:38:35 lapp Exp $
#
# BioPerl module for Bio::Location::Simple
# Cared for by Heikki Lehvaslaiho <heikki@ebi.ac.uk>
#
# Copyright Heikki Lehvaslaiho
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

#line 66

# Let the code begin...


package Bio::Location::Simple;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::Location::Atomic;


@ISA = qw( Bio::Location::Atomic );

BEGIN {
    use vars qw(  %RANGEENCODE  %RANGEDECODE  );

    %RANGEENCODE  = ('\.\.' => 'EXACT',
		     '\^' => 'IN-BETWEEN' );

    %RANGEDECODE  = ('EXACT' => '..',
		     'IN-BETWEEN' => '^' );

}

sub new { 
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my ($locationtype) = $self->_rearrange([qw(LOCATION_TYPE)],@args);

    $locationtype && $self->location_type($locationtype);

    return $self;
}

#line 112

sub start {
  my ($self, $value) = @_;

  $self->{'_start'} = $value if defined $value ;

  $self->throw("Only adjacent residues when location type ".
	       "is IN-BETWEEN. Not [". $self->{'_start'}. "] and [".
	       $self->{'_end'}. "]" )
      if defined $self->{'_start'} && defined $self->{'_end'} && 
	  $self->location_type eq 'IN-BETWEEN' &&
	  ($self->{'_end'} - 1 != $self->{'_start'});
  return $self->{'_start'};
}


#line 138

sub end {
  my ($self, $value) = @_;

  $self->{'_end'} = $value if defined $value ;
  $self->throw("Only adjacent residues when location type ".
	      "is IN-BETWEEN. Not [". $self->{'_start'}. "] and [".
	       $self->{'_end'}. "]" )
      if defined $self->{'_start'} && defined $self->{'_end'} && 
	  $self->location_type eq 'IN-BETWEEN' &&
	  ($self->{'_end'} - 1 != $self->{'_start'});

  return $self->{'_end'};
}

#line 163

#line 175

sub length {
   my ($self) = @_;
   if ($self->location_type eq 'IN-BETWEEN' ) {
       return 0;
   } else {
       return abs($self->end - $self->start) + 1;
   }

}

#line 195

#line 208

#line 220

#line 230


#line 244

#line 256

#line 266

sub location_type {
    my ($self, $value) = @_;

    if( defined $value || ! defined $self->{'_location_type'} ) {
	$value = 'EXACT' unless defined $value;
	$value = uc $value;
	if (! defined $RANGEDECODE{$value}) {
	    $value = '\^' if $value eq '^';
	    $value = '\.\.' if $value eq '..';
	    $value = $RANGEENCODE{$value};
	}
	$self->throw("Did not specify a valid location type. [$value] is no good")
	    unless defined $value;
	$self->{'_location_type'} = $value;
    }
    $self->throw("Only adjacent residues when location type ".
		 "is IN-BETWEEN. Not [". $self->{'_start'}. "] and [".
		 $self->{'_end'}. "]" )
	if $self->{'_location_type'} eq 'IN-BETWEEN' &&
	    defined $self->{'_start'} &&
		defined $self->{'_end'} &&
		    ($self->{'_end'} - 1 != $self->{'_start'});

    return $self->{'_location_type'};
}

#line 303

#line 313

sub to_FTstring { 
    my($self) = @_;

    my $str;
    if( $self->start == $self->end ) {
	return $self->start;
    }
    $str = $self->start . $RANGEDECODE{$self->location_type} . $self->end;
    if($self->is_remote() && $self->seq_id()) {
	$str = $self->seq_id() . ":" . $str;
    }
    if( $self->strand == -1 ) {
	$str = "complement(".$str.")";
    }
    return $str;
}

#
# not tested
#
sub trunc {
  my ($self,$start,$end,$relative_ori) = @_;

  my $newstart  = $self->start - $start+1;
  my $newend    = $self->end   - $start+1;
  my $newstrand = $relative_ori * $self->strand;

  my $out;
  if( $newstart < 1 || $newend > ($end-$start+1) ) {
    $out = Bio::Location::Simple->new();
    $out->start($self->start);
    $out->end($self->end);
    $out->strand($self->strand);
    $out->seq_id($self->seqid);
    $out->is_remote(1);
  } else {
    $out = Bio::Location::Simple->new();
    $out->start($newstart);
    $out->end($newend);
    $out->strand($newstrand);
    $out->seq_id();
  }

  return $out;
}

1;

