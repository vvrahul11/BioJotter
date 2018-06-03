#line 1 "Bio/PrimarySeqI.pm"
# $Id: PrimarySeqI.pm,v 1.50.2.3 2003/08/29 15:37:39 birney Exp $
#
# BioPerl module for Bio::PrimarySeqI
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 119


# Let the code begin...


package Bio::PrimarySeqI;
use vars qw(@ISA );
use strict;
use Bio::Root::RootI;
use Bio::Tools::CodonTable;

@ISA = qw(Bio::Root::RootI);

#line 151

sub seq {
   my ($self) = @_;
   $self->throw_not_implemented();
}

#line 172

sub subseq{
   my ($self) = @_;
   $self->throw_not_implemented();
}

#line 203

sub display_id {
   my ($self) = @_;
   $self->throw_not_implemented();
}


#line 229

sub accession_number {
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}



#line 257

sub primary_id {
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}


#line 287

sub can_call_new{
   my ($self,@args) = @_;

   # we default to 0 here

   return 0;
}

#line 314

sub alphabet{
    my ( $self ) = @_;
    $self->throw_not_implemented();
}

sub moltype{
   my ($self,@args) = @_;

   $self->warn("moltype: pre v1.0 method. Calling alphabet() instead...");
   $self->alphabet(@args);
}


#line 370

sub revcom{
   my ($self) = @_;

   # check the type is good first.
   my $t = $self->alphabet;

   if( $t eq 'protein' ) {
       $self->throw("Sequence is a protein. Cannot revcom");
   }

   if( $t ne 'dna' && $t ne 'rna' ) {
       if( $self->can('warn') ) {
	   $self->warn("Sequence is not dna or rna, but [$t]. ".
		       "Attempting to revcom, but unsure if this is right");
       } else {
	   warn("[$self] Sequence is not dna or rna, but [$t]. ".
		"Attempting to revcom, but unsure if this is right");
       }
   }

   # yank out the sequence string

   my $str = $self->seq();

   # if is RNA - map to DNA then map back

   if( $t eq 'rna' ) {
       $str =~ tr/uU/tT/;
   }

   # revcom etc...

   $str =~ tr/acgtrymkswhbvdnxACGTRYMKSWHBVDNX/tgcayrkmswdvbhnxTGCAYRKMSWDVBHNX/;
   my $revseq = CORE::reverse $str;

   if( $t eq 'rna' ) {
       $revseq =~ tr/tT/uU/;
   }

   my $seqclass;
   if($self->can_call_new()) {
       $seqclass = ref($self);
   } else {
       $seqclass = 'Bio::PrimarySeq';
       $self->_attempt_to_load_Seq();
   }
   my $out = $seqclass->new( '-seq' => $revseq,
			     '-display_id'  => $self->display_id,
			     '-accession_number' => $self->accession_number,
			     '-alphabet' => $self->alphabet,
			     '-desc' => $self->desc(),
                             '-verbose' => $self->verbose
			     );
   return $out;

}

#line 440

sub trunc{
   my ($self,$start,$end) = @_;

   my $str;
   if( defined $start && ref($start) &&
       $start->isa('Bio::LocationI') ) {
       $str = $self->subseq($start); # start is a location actually
   } elsif( !$end ) {
       $self->throw("trunc start,end -- there was no end for $start");
   } elsif( $end < $start ) {
       my $msg = "start [$start] is greater than end [$end]. \n".
	   "If you want to truncated and reverse complement, \n".
	       "you must call trunc followed by revcom. Sorry.";
       $self->throw($msg);
   } else {
       $str = $self->subseq($start,$end);
   }

   my $seqclass;
   if($self->can_call_new()) {
       $seqclass = ref($self);
   } else {
       $seqclass = 'Bio::PrimarySeq';
       $self->_attempt_to_load_Seq();
   }

   my $out = $seqclass->new( '-seq' => $str,
			     '-display_id'  => $self->display_id,
			     '-accession_number' => $self->accession_number,
			     '-alphabet' => $self->alphabet,
			     '-desc' => $self->desc(),
                             '-verbose' => $self->verbose
			     );
   return $out;
}

#line 509

sub translate {
    my($self) = shift;
    my($stop, $unknown, $frame, $tableid, $fullCDS, $throw, $complete5,
$complete3) = @_;
    my($i, $len, $output) = (0,0,'');
    my($codon)   = "";
    my $aa;

    ## User can pass in symbol for stop and unknown codons
    unless(defined($stop) and $stop ne '')    { $stop = "*"; }
    unless(defined($unknown) and $unknown ne '') { $unknown = "X"; }
    unless(defined($frame) and $frame ne '') { $frame = 0; }

    ## the codon table ID
    unless(defined($tableid) and $tableid ne '')    { $tableid = 1; }

    ##Error if monomer is "Amino"
    $self->throw("Can't translate an amino acid sequence.") if
	($self->alphabet eq 'protein');

    ##Error if frame is not 0, 1 or 2
    $self->throw("Valid values for frame are 0, 1, 2, not [$frame].") unless
	($frame == 0 or $frame == 1 or $frame == 2);

    #warns if ID is invalid
    my $codonTable = Bio::Tools::CodonTable->new( -id => $tableid);

    my ($seq) = $self->seq();

    # deal with frame offset.
    if( $frame ) {
	$seq = substr ($seq,$frame);
    }

    # Translate it
    $output = $codonTable->translate($seq);
    # Use user-input stop/unknown
    $output =~ s/\*/$stop/g;
    $output =~ s/X/$unknown/g;

    # $complete5 and $complete3 indicate completeness of
    # the coding sequence at the 5' and 3' ends. Complete
    # if true, default to false. These are in addition to
    # $fullCDS, for backwards compatibility
    defined($complete5) or ($complete5 = $fullCDS ? 1 : 0);
    defined($complete3) or ($complete3 = $fullCDS ? 1 : 0);

    my $id = $self->display_id;

    # only if we are expecting to be complete at the 5' end
    if($complete5) {
	# if the initiator codon is not ATG, the amino acid needs to changed into M
	if(substr($output,0,1) ne 'M') {
	    if($codonTable->is_start_codon(substr($seq, 0, 3)) ) {
		$output = 'M' . substr($output, 1);
	    }
	    elsif($throw) {
		$self->throw("Seq [$id]: Not using a valid initiator codon!");
	    } else {
		$self->warn("Seq [$id]: Not using a valid initiator codon!");
	    }
	}
    }

    # only if we are expecting to be complete at the 3' end
    if($complete3) {
	#remove the stop character
	if(substr($output, -1, 1) eq $stop) {
	    chop $output;
	} else {
	    $throw && $self->throw("Seq [$id]: Not using a valid terminator codon!");
	    $self->warn("Seq [$id]: Not using a valid terminator codon!");
	}
    }

    # only if we are expecting to translate a complete coding region
    if($complete5 and $complete3) {
	# test if there are terminator characters inside the protein sequence!
	if($output =~ /\*/) {
	    $throw && $self->throw("Seq [$id]: Terminator codon inside CDS!");
	    $self->warn("Seq [$id]: Terminator codon inside CDS!");
	}
    }

    my $seqclass;
    if($self->can_call_new()) {
	$seqclass = ref($self);
    } else {
	$seqclass = 'Bio::PrimarySeq';
	$self->_attempt_to_load_Seq();
    }
    my $out = $seqclass->new( '-seq' => $output,
			      '-display_id'  => $self->display_id,
			      '-accession_number' => $self->accession_number,
			      # is there anything wrong with retaining the
			      # description?
			      '-desc' => $self->desc(),
			      '-alphabet' => 'protein',
                              '-verbose' => $self->verbose
			      );
    return $out;

}

#line 626

sub  id {
   return shift->display_id();
}


#line 643

sub  length {
   shift->throw_not_implemented();
}

#line 660

sub desc {
   my ($self,$value) = @_;
   $self->throw_not_implemented();
}


#line 676

sub is_circular{
    shift->throw_not_implemented();
}

#line 697

sub _attempt_to_load_Seq{
   my ($self) = @_;

   if( $main::{'Bio::PrimarySeq'} ) {
       return 1;
   } else {
       eval {
	   require Bio::PrimarySeq;
       };
       if( $@ ) {
	   my $text = "Bio::PrimarySeq could not be loaded for [$self]\n".
	       "This indicates that you are using Bio::PrimarySeqI ".
	       "without Bio::PrimarySeq loaded or without providing a ".
	       "complete implementation.\nThe most likely problem is that there ".
	       "has been a misconfiguration of the bioperl environment\n".
	       "Actual exception:\n\n";
	   $self->throw("$text$@\n");
	   return 0;
       }
       return 1;
   }

}

1;
