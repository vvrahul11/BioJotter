#line 1 "Bio/Tools/BPlite/HSP.pm"
###############################################################################
# Bio::Tools::BPlite::HSP
###############################################################################
# HSP = High Scoring Pair (to all non-experts as I am)
#
# The original BPlite.pm module has been written by Ian Korf !
# see http://sapiens.wustl.edu/~ikorf
#
# You may distribute this module under the same terms as perl itself


#
# BioPerl module for Bio::Tools::BPlite::HSP
#
# Cared for by Peter Schattner <schattner@alum.mit.edu>
#
# Copyright Peter Schattner
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 106

# Let the code begin...

package Bio::Tools::BPlite::HSP;

use vars qw(@ISA);
use strict;

# to disable overloading comment this out:
#use overload '""' => '_overload';

# Object preamble - inheriets from Bio::SeqFeature::SimilarityPair

use Bio::SeqFeature::SimilarityPair;
use Bio::SeqFeature::Similarity;

@ISA = qw(Bio::SeqFeature::SimilarityPair);

sub new {
    my ($class, @args) = @_;

    # workaround to make sure frame is not set before strand is
    # interpreted from query/hit info 
    # this workaround removes the key from the hash
    # so the superclass does not try and work with it
    # we'll take care of setting it in this module later on

    my %newargs = @args;
    foreach ( keys %newargs ) {
	if( /frame$/i ) {
	    delete $newargs{$_};
	} 
    }
    # done with workaround

    my $self = $class->SUPER::new(%newargs);
    
    my ($score,$bits,$match,$hsplength,$positive,$gaps,$p,$exp,$qb,$qe,$sb,
	$se,$qs,$ss,$hs,$qname,$sname,$qlength,$slength,$qframe,$sframe,
	$blasttype) = 
	    $self->_rearrange([qw(SCORE
				  BITS
				  MATCH
				  HSPLENGTH
				  POSITIVE
				  GAPS				  
				  P
				  EXP
				  QUERYBEGIN
				  QUERYEND
				  SBJCTBEGIN
				  SBJCTEND
				  QUERYSEQ
				  SBJCTSEQ
				  HOMOLOGYSEQ
				  QUERYNAME
				  SBJCTNAME
				  QUERYLENGTH
				  SBJCTLENGTH
				  QUERYFRAME
				  SBJCTFRAME
				  BLASTTYPE
				  )],@args);
    
    $blasttype = 'UNKNOWN' unless $blasttype;
    $self->report_type($blasttype);
    # Determine strand meanings
    my ($queryfactor, $sbjctfactor) = (1,0); # default
    if ($blasttype eq 'BLASTP' || $blasttype eq 'TBLASTN' ) {
	$queryfactor = 0;
    }
    if ($blasttype eq 'TBLASTN' || $blasttype eq 'TBLASTX' || 
	$blasttype eq 'BLASTN' )  {
	$sbjctfactor = 1;
    }
    
    # Set BLAST type
    $self->{'BLAST_TYPE'} = $blasttype;
	
    # Store the aligned query as sequence feature
    my $strand;
    if ($qe > $qb) {		# normal query: start < end
		if ($queryfactor) { $strand = 1; } else { $strand = undef; }
		$self->query( Bio::SeqFeature::Similarity->new
		      (-start=>$qb, -end=>$qe, -strand=>$strand, 
		       -source=>"BLAST" ) ) }
    else {			# reverse query (i dont know if this is possible, but feel free to correct)	
		if ($queryfactor) { $strand = -1; } else { $strand = undef; }
		$self->query( Bio::SeqFeature::Similarity->new
		      (-start=>$qe, -end=>$qb, -strand=>$strand,
		       -source=>"BLAST" ) ) }

    # store the aligned hit as sequence feature
    if ($se > $sb) {		# normal hit
	if ($sbjctfactor) { $strand = 1; } else { $strand = undef; }
	$self->hit( Bio::SeqFeature::Similarity->new
			(-start=>$sb, -end=>$se, -strand=>$strand,
			 -source=>"BLAST" ) ) }
    else { # reverse hit: start bigger than end
	if ($sbjctfactor) { $strand = -1; } else { $strand = undef; }
	$self->hit( Bio::SeqFeature::Similarity->new
			(-start=>$se, -end=>$sb, -strand=>$strand,
			 -source=>"BLAST" ) ) }
    
    # name the sequences
    $self->query->seq_id($qname); # query name
    $self->hit->seq_id($sname);   # hit name

    # set lengths
    $self->query->seqlength($qlength); # query length
    $self->hit->seqlength($slength);   # hit length

    # set object vars
    $self->score($score);
    $self->bits($bits);

    $self->significance($p);
    $self->{'EXP'} = $exp;
    
    $self->query->frac_identical($match);
    $self->hit->frac_identical($match);
    $self->{'HSPLENGTH'} = $hsplength;
    $self->{'PERCENT'} = int((1000 * $match)/$hsplength)/10;
    $self->{'POSITIVE'} = $positive;
    $self->{'GAPS'} = $gaps;
    $self->{'QS'} = $qs;
    $self->{'SS'} = $ss;
    $self->{'HS'} = $hs;
    
    $self->frame($qframe, $sframe);
    return $self;		# success - we hope!
}

# to disable overloading comment this out:
sub _overload {
	my $self = shift;
	return $self->start."..".$self->end." ".$self->bits;
}

#line 259

sub report_type {
    my ($self, $rpt) = @_;
    if($rpt) {
	$self->{'_report_type'} = $rpt;
    }
    return $self->{'_report_type'};
}

#line 279

sub EXP{
    return $_[0]->{'EXP'};
}


#line 294

sub P {
	my ($self, @args) = @_;
	my $float = $self->significance(@args);
	my $match = '([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?'; # Perl Cookbook 2.1
	if ($float =~ /^$match$/) {
	    # Is a C float
	    return $float;
	} elsif ("1$float" =~ /^$match$/) {
	    # Almost C float, Jitterbug 974
	    return "1$float";
	} else {
		$self->warn("[HSP::P()] '$float' is not a known number format. Returning zero (0) instead.");
		return 0;
	}
}

#line 320

sub percent         {shift->{'PERCENT'}}


#line 334

sub match           {shift->query->frac_identical(@_)}

#line 346

sub hsplength              {shift->{'HSPLENGTH'}}

#line 359

sub positive        {shift->{'POSITIVE'}}

#line 371

sub gaps        {shift->{'GAPS'}}

#line 383

sub querySeq        {shift->{'QS'}}

#line 395

sub sbjctSeq        {shift->{'SS'}}

#line 407

sub homologySeq     {shift->{'HS'}}

#line 419

sub qs              {shift->{'QS'}}

#line 431

sub ss              {shift->{'SS'}}

#line 443

sub hs              {shift->{'HS'}}

sub frame {
    my ($self, $qframe, $sframe) = @_;
    if( defined $qframe ) {
	if( $qframe == 0 ) {
	    $qframe = undef;
	} elsif( $qframe !~ /^([+-])?([1-3])/ ) {	    
	    $self->warn("Specifying an invalid query frame ($qframe)");
	    $qframe = undef;
	} else { 
	    if( ($1 eq '-' && $self->query->strand >= 0) || 
		($1 eq '+' && $self->query->strand <= 0) ) {
		$self->warn("Query frame ($qframe) did not match strand of query (". $self->query->strand() . ")");
	    }
	    # Set frame to GFF [0-2]
	    $qframe = $2 - 1;
	}
	$self->{'QFRAME'} = $qframe;
    }
    if( defined $sframe ) {
	  if( $sframe == 0 ) {
	    $sframe = undef;
	  } elsif( $sframe !~ /^([+-])?([1-3])/ ) {	    
	    $self->warn("Specifying an invalid hit frame ($sframe)");
	    $sframe = undef;
	  } else { 
	      if( ($1 eq '-' && $self->hit->strand >= 0) || 
		  ($1 eq '+' && $self->hit->strand <= 0) ) 
	      {
		  $self->warn("Hit frame ($sframe) did not match strand of hit (". $self->hit->strand() . ")");
	      }
	      
	      # Set frame to GFF [0-2]
	      $sframe = $2 - 1;
	  }
	  $self->{'SFRAME'} = $sframe;
      }

    (defined $qframe && $self->SUPER::frame($qframe) && 
     ($self->{'FRAME'} = $qframe)) || 
    (defined $sframe && $self->SUPER::frame($sframe) && 
     ($self->{'FRAME'} = $sframe));

    if (wantarray() && 
	$self->{'BLAST_TYPE'} eq 'TBLASTX') 
    { 
	return ($self->{'QFRAME'}, $self->{'SFRAME'}); 
    } elsif (wantarray())  { 
	(defined $self->{'QFRAME'} && 
	 return ($self->{'QFRAME'}, undef)) || 
	     (defined $self->{'SFRAME'} && 
	      return (undef, $self->{'SFRAME'})); 
    } else { 
	(defined $self->{'QFRAME'} && 
	 return $self->{'QFRAME'}) || 
	(defined $self->{'SFRAME'} && 
	 return $self->{'SFRAME'}); 
    }
}

1;
