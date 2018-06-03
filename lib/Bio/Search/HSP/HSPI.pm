#line 1 "Bio/Search/HSP/HSPI.pm"
#-----------------------------------------------------------------
# $Id: HSPI.pm,v 1.21.2.1 2003/01/22 22:51:00 jason Exp $
#
# BioPerl module for Bio::Search::HSP::HSPI
#
# Cared for by Steve Chervitz <sac@bioperl.org>
# and Jason Stajich <jason@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

# POD documentation - main docs before the code

#line 100


# Let the code begin...


package Bio::Search::HSP::HSPI;
use vars qw(@ISA);

use Bio::Root::RootI;
use Bio::SeqFeature::SimilarityPair;

use strict;
use Carp;

@ISA = qw(Bio::SeqFeature::SimilarityPair Bio::Root::RootI);


#line 126

sub algorithm{
   my ($self,@args) = @_;
   $self->throw_not_implemented;
}

#line 142

sub pvalue {
   my ($self) = @_;
   $self->throw_not_implemented;
}

#line 157

sub evalue {
   my ($self) = @_;
   $self->throw_not_implemented;
}

#line 175

sub frac_identical {
   my ($self, $type) = @_;
   $self->throw_not_implemented;
}

#line 195

sub frac_conserved {
    my ($self, $type) = @_;
    $self->throw_not_implemented;
}

#line 211

sub num_identical{
    shift->throw_not_implemented;
}

#line 226

sub num_conserved{
    shift->throw_not_implemented();
}

#line 243

sub gaps        {
    my ($self, $type) = @_;
    $self->throw_not_implemented;
}

#line 259

sub query_string{
   my ($self) = @_;
   $self->throw_not_implemented;
}

#line 275

sub hit_string{
   my ($self) = @_;
   $self->throw_not_implemented;
}

#line 293

sub homology_string{
   my ($self) = @_;
   $self->throw_not_implemented;
}

#line 314

sub length{
    shift->throw_not_implemented();
}

#line 329

sub percent_identity{
   my ($self) = @_;
   return $self->frac_identical('hsp') * 100;   
}

#line 344

sub get_aln {
   my ($self) = @_;
   $self->throw_not_implemented;
}


#line 377

sub seq_inds {
    shift->throw_not_implemented();
}

#line 431

# override 

#line 445

sub strand {
    my $self = shift;
    my $val = shift;
    $val = 'query' unless defined $val;
    $val =~ s/^\s+//;

    if( $val =~ /^q/i ) { 
	return $self->query->strand(shift);
    } elsif( $val =~ /^(hi|s)/i ) {
	return $self->hit->strand(shift);
    } elsif ( $val =~ m/^(list|array)/) {
	return ($self->query->strand(shift), $self->hit->strand(shift));
    } else { 
	$self->warn("unrecognized component $val requested\n");
    }
    return 0;
}

#line 474

sub start {
    my $self = shift;
    my $val = shift;
    $val = 'query' unless defined $val;
    $val =~ s/^\s+//;

    if( $val =~ /^q/i ) { 
	return $self->query->start(shift);
    } elsif( $val =~ /^(hi|s)/i ) {
	return $self->hit->start(shift);
    } else { 
	$self->warn("unrecognized component $val requested\n");
    }
    return 0;
}

#line 501

sub end {
    my $self = shift;
    my $val = shift;
    $val = 'query' unless defined $val;
    $val =~ s/^\s+//;

    if( $val =~ /^q/i ) { 
	return $self->query->end(shift);
    } elsif( $val =~ /^(hi|s)/i ) {
	return $self->hit->end(shift);
    } else { 
	$self->warn("unrecognized component $val requested\n");
    }
    return 0;
}

#line 535

sub seq_str {  
    my $self = shift;
    my $type = shift;
    if( $type =~ /^q/i ) { return $self->query_string(shift) }
    elsif( $type =~ /^(s|hi)/i ) { return $self->hit_string(shift)}
    elsif ( $type =~ /^(ho|ma)/i ) { return $self->hit_string(shift) }
    else { 
	$self->warn("unknown sequence type $type");
    }
    return '';
}


#line 558

sub rank { shift->throw_not_implemented }

#line 584

#-----------
sub matches {
#-----------
    my( $self, %param ) = @_;
    my(@data);
    my($seqType, $beg, $end) = ($param{-SEQ}, $param{-START}, $param{-STOP});
    $seqType ||= 'query';
   $seqType = 'sbjct' if $seqType eq 'hit';

    if(!defined $beg && !defined $end) {
	## Get data for the whole alignment.
	push @data, ($self->num_identical, $self->num_conserved);
    } else {
	## Get the substring representing the desired sub-section of aln.
	$beg ||= 0;
	$end ||= 0;
	my($start,$stop) = $self->range($seqType);
	if($beg == 0) { $beg = $start; $end = $beg+$end; }
	elsif($end == 0) { $end = $stop; $beg = $end-$beg; }

	if($end >= $stop) { $end = $stop; } ##ML changed from if (end >stop)
	else { $end += 1;}   ##ML moved from commented position below, makes
                             ##more sense here
#	if($end > $stop) { $end = $stop; }
	if($beg < $start) { $beg = $start; }
#	else { $end += 1;}

#	my $seq = substr($self->seq_str('match'), $beg-$start, ($end-$beg));

	## ML: START fix for substr out of range error ------------------
	my $seq = "";
	if (($self->algorithm eq 'TBLASTN') and ($seqType eq 'sbjct'))
	{
	    $seq = substr($self->seq_str('match'),
			  int(($beg-$start)/3), int(($end-$beg+1)/3));

	} elsif (($self->algorithm eq 'BLASTX') and ($seqType eq 'query'))
	{
	    $seq = substr($self->seq_str('match'),
			  int(($beg-$start)/3), int(($end-$beg+1)/3));
	} else {
	    $seq = substr($self->seq_str('match'), 
			  $beg-$start, ($end-$beg));
	}
	## ML: End of fix for  substr out of range error -----------------

	
	## ML: debugging code
	## This is where we get our exception.  Try printing out the values going
	## into this:
	##
#	 print STDERR 
#	     qq(*------------MY EXCEPTION --------------------\nSeq: ") , 
#	     $self->seq_str("$seqType"), qq("\n),$self->rank,",(  index:";
#	 print STDERR  $beg-$start, ", len: ", $end-$beg," ), (HSPRealLen:", 
#	     CORE::length $self->seq_str("$seqType");
#	 print STDERR ", HSPCalcLen: ", $stop - $start +1 ," ), 
#	     ( beg: $beg, end: $end ), ( start: $start, stop: stop )\n";
	 ## ML: END DEBUGGING CODE----------

	if(!CORE::length $seq) {
	    $self->throw("Undefined sub-sequence ($beg,$end). Valid range = $start - $stop");
	}
	## Get data for a substring.
#	printf "Collecting HSP subsection data: beg,end = %d,%d; start,stop = %d,%d\n%s<---\n", $beg, $end, $start, $stop, $seq;
#	printf "Original match seq:\n%s\n",$self->seq_str('match');
	$seq =~ s/ //g;  # remove space (no info).
	my $len_cons = CORE::length $seq;
	$seq =~ s/\+//g;  # remove '+' characters (conservative substitutions)
	my $len_id = CORE::length $seq;
	push @data, ($len_id, $len_cons);
#	printf "  HSP = %s\n  id = %d; cons = %d\n", $self->rank, $len_id, $len_cons; <STDIN>;
    }
    @data;
}

#line 678

sub n { shift->throw_not_implemented }

#line 696

sub range { shift->throw_not_implemented }


1;

