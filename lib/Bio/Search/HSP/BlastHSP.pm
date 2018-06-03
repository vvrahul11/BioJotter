#line 1 "Bio/Search/HSP/BlastHSP.pm"
#-----------------------------------------------------------------
# $Id: BlastHSP.pm,v 1.20 2002/12/24 15:45:33 jason Exp $
#
# BioPerl module Bio::Search::HSP::BlastHSP
#
# (This module was originally called Bio::Tools::Blast::HSP)
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

## POD Documentation:

#line 137


# END of main POD documentation.

#line 147

# Let the code begin...

package Bio::Search::HSP::BlastHSP;

use strict;
use Bio::SeqFeature::SimilarityPair;
use Bio::SeqFeature::Similarity;
use Bio::Search::HSP::HSPI; 

use vars qw( @ISA $GAP_SYMBOL $Revision %STRAND_SYMBOL );

use overload 
    '""' => \&to_string;

$Revision = '$Id: BlastHSP.pm,v 1.20 2002/12/24 15:45:33 jason Exp $';  #'

@ISA = qw(Bio::SeqFeature::SimilarityPair Bio::Search::HSP::HSPI);

$GAP_SYMBOL    = '-';          # Need a more general way to handle gap symbols.
%STRAND_SYMBOL = ('Plus' => 1, 'Minus' => -1 );


#line 202

#----------------
sub new {
#----------------
    my ($class, @args ) = @_;

    my $self = $class->SUPER::new( @args );
    # Initialize placeholders
    $self->{'_queryGaps'} = $self->{'_sbjctGaps'} = 0;
    my ($raw_data, $qname, $hname, $qlen, $hlen);

    ($self->{'_prog'}, $self->{'_rank'}, $raw_data,
     $qname, $hname) = 
      $self->_rearrange([qw( PROGRAM
			     RANK
			     RAW_DATA
			     QUERY_NAME
			     HIT_NAME
			   )], @args );
    
    # _set_data() does a fair amount of parsing. 
    # This will likely change (see comment above.)
    $self->_set_data( @{$raw_data} );
    # Store the aligned query as sequence feature
    my ($qb, $hb) = ($self->start());
    my ($qe, $he) = ($self->end());
    my ($qs, $hs) = ($self->strand());
    my ($qf,$hf) = ($self->query->frame(),
		    $self->hit->frame);

    $self->query( Bio::SeqFeature::Similarity->new (-start   =>$qb, 
						    -end     =>$qe, 
						    -strand  =>$qs, 
						    -bits    =>$self->bits,
						    -score   =>$self->score, 
						    -frame   =>$qf,
						    -seq_id  => $qname,
						    -source  =>$self->{'_prog'} ));
    
    $self->hit( Bio::SeqFeature::Similarity->new (-start   =>$hb, 
						  -end     =>$he, 
						  -strand  =>$hs, 
						  -bits    =>$self->bits,
						  -score   =>$self->score,
                                                  -frame   =>$hf, 
						  -seq_id  => $hname,
						  -source  =>$self->{'_prog'} ));

    # set lengths
    $self->query->seqlength($qlen); # query
    $self->hit->seqlength($hlen); # subject

    $self->query->frac_identical($self->frac_identical('query'));
    $self->hit->frac_identical($self->frac_identical('hit'));
    return $self;
}

#sub DESTROY {
#    my $self = shift; 
#    #print STDERR "--->DESTROYING $self\n";
#}


# Title   : _id_str; 
# Purpose : Intended for internal use only to provide a string for use
#           within exception messages to help users figure out which 
#           query/hit caused the problem.
# Returns : Short string with name of query and hit seq 
sub _id_str {
    my $self = shift;
    if( not defined $self->{'_id_str'}) {
        my $qname = $self->query->seqname;
        my $hname = $self->hit->seqname;
        $self->{'_id_str'} = "QUERY=\"$qname\" HIT=\"$hname\"";
    }
    return $self->{'_id_str'};
}

#=================================================
# Begin Bio::Search::HSP::HSPI implementation
#=================================================

#line 297

#----------------
sub algorithm {
#----------------
    my ($self,@args) = @_;
    return $self->{'_prog'};
}




#line 324

#-----------
sub signif { 
#-----------
    my $self = shift; 
    my $val ||= defined($self->{'_p'}) ? $self->{'_p'} : $self->{'_expect'};
    $val; 
}



#line 349

#----------
sub evalue { shift->{'_expect'} }
#----------


#line 370

#-----
sub p { my $self = shift; $self->{'_p'}; }
#-----

# alias
sub pvalue { shift->p(@_); }

#line 394

#-----------
sub length {
#-----------
## Developer note: when using the built-in length function within
##                 this module, call it as CORE::length().
    my( $self, $seqType ) = @_;
    $seqType  ||= 'total';
    $seqType = 'sbjct' if $seqType eq 'hit';

    $seqType ne 'total' and $self->_set_seq_data() unless $self->{'_set_seq_data'};

    ## Sensitive to member name format.
    $seqType = "_\L$seqType\E";
    $self->{$seqType.'Length'};
}



#line 433

#---------
sub gaps {
#---------
    my( $self, $seqType ) = @_;
    
    $self->_set_seq_data() unless $self->{'_set_seq_data'};

    $seqType  ||= (wantarray ? 'list' : 'total');
    $seqType = 'sbjct' if $seqType eq 'hit';
    
    if($seqType =~ /list|array/i) {
	return (($self->{'_queryGaps'} || 0), ($self->{'_sbjctGaps'} || 0));
    }
    
    if($seqType eq 'total') {
	return ($self->{'_queryGaps'} + $self->{'_sbjctGaps'}) || 0;
    } else {
	## Sensitive to member name format.
	$seqType = "_\L$seqType\E";
	return $self->{$seqType.'Gaps'} || 0;
    }
}


#line 485

#-------------------
sub frac_identical {
#-------------------
# The value is calculated as opposed to storing it from the parsed results.
# This saves storage and also permits flexibility in determining for which
# sequence (query or sbjct) the figure is to be calculated.

    my( $self, $seqType ) = @_;
    $seqType ||= 'total';
    $seqType = 'sbjct' if $seqType eq 'hit';

    if($seqType ne 'total') {
      $self->_set_seq_data() unless $self->{'_set_seq_data'};
    }
    ## Sensitive to member name format.
    $seqType = "_\L$seqType\E";

    sprintf( "%.2f", $self->{'_numIdentical'}/$self->{$seqType.'Length'});
}


#line 536

#--------------------
sub frac_conserved {
#--------------------
# The value is calculated as opposed to storing it from the parsed results.
# This saves storage and also permits flexibility in determining for which
# sequence (query or sbjct) the figure is to be calculated.
 
    my( $self, $seqType ) = @_;
    $seqType ||= 'total';
    $seqType = 'sbjct' if $seqType eq 'hit';

    if($seqType ne 'total') {
      $self->_set_seq_data() unless $self->{'_set_seq_data'};
    }

    ## Sensitive to member name format.
    $seqType = "_\L$seqType\E";

    sprintf( "%.2f", $self->{'_numConserved'}/$self->{$seqType.'Length'});
}

#line 568

#----------------
sub query_string{ shift->seq_str('query'); }
#----------------

#line 583

#----------------
sub hit_string{ shift->seq_str('hit'); }
#----------------


#line 601

#----------------
sub homology_string{ shift->seq_str('match'); }
#----------------

#=================================================
# End Bio::Search::HSP::HSPI implementation
#=================================================

# Older method delegating to method defined in HSPI.

#line 617

#----------
sub expect { shift->evalue( @_ ); }
#----------


#line 632

#'

#----------
sub rank { shift->{'_rank'} }
#----------

# For backward compatibility
#----------
sub name { shift->rank }
#----------

#line 658

#----------
sub to_string {
#----------
    my $self = shift;
    return "[BlastHSP] " . $self->rank();
}


#=head2 _set_data (Private method)
#
# Usage     : called automatically during object construction.
# Purpose   : Parses the raw HSP section from a flat BLAST report and
#             sets the query sequence, sbjct sequence, and the "match" data
#           : which consists of the symbols between the query and sbjct lines
#           : in the alignment.
# Argument  : Array (all lines for a single, complete HSP, from a raw, 
#             flat (i.e., non-XML) BLAST report)
# Throws    : Propagates any exceptions from the methods called ("See Also")
#
#See Also   : L<_set_seq()|_set_seq>, L<_set_score_stats()|_set_score_stats>, L<_set_match_stats()|_set_match_stats>, L<_initialize()|_initialize>
#
#=cut

#--------------
sub _set_data {
#--------------
    my $self = shift;
    my @data = @_;
    my @queryList  = ();  # 'Query' = SEQUENCE USED TO QUERY THE DATABASE.
    my @sbjctList  = ();  # 'Sbjct' = HOMOLOGOUS SEQUENCE FOUND IN THE DATABASE.
    my @matchList  = ();
    my $matchLine  = 0;   # Alternating boolean: when true, load 'match' data.
    my @linedat = ();
    
    #print STDERR "BlastHSP: set_data()\n";

    my($line, $aln_row_len, $length_diff);
    $length_diff = 0;

    # Collecting data for all lines in the alignment
    # and then storing the collections for possible processing later.
    #
    # Note that "match" lines may not be properly padded with spaces.
    # This loop now properly handles such cases:
    # Query: 1141 PSLVELTIRDCPRLEVGPMIRSLPKFPMLKKLDLAVANIIEEDLDVIGSLEELVIXXXXX 1200
    #             PSLVELTIRDCPRLEVGPMIRSLPKFPMLKKLDLAVANIIEEDLDVIGSLEELVI
    # Sbjct: 1141 PSLVELTIRDCPRLEVGPMIRSLPKFPMLKKLDLAVANIIEEDLDVIGSLEELVILSLKL 1200

    foreach $line( @data ) {
	next if $line =~ /^\s*$/;

	if( $line =~ /^ ?Score/ ) {
	    $self->_set_score_stats( $line );
	} elsif( $line =~ /^ ?(Identities|Positives|Strand)/ ) {
	    $self->_set_match_stats( $line );
	} elsif( $line =~ /^ ?Frame = ([\d+-]+)/ ) {
	  # Version 2.0.8 has Frame information on a separate line.
	  # Storing frame according to SeqFeature::Generic::frame()
	  # which does not contain strand info (use strand()).
	  my $frame = abs($1) - 1;
	  $self->frame( $frame );
	} elsif( $line =~ /^(Query:?[\s\d]+)([^\s\d]+)/ ) {
	    push @queryList, $line;
	    $self->{'_match_indent'} = CORE::length $1;
	    $aln_row_len = (CORE::length $1) + (CORE::length $2);
	    $matchLine = 1;
	} elsif( $matchLine ) {
	    # Pad the match line with spaces if necessary.
	    $length_diff = $aln_row_len - CORE::length $line;
	    $length_diff and $line .= ' 'x $length_diff;
	    push @matchList, $line;
	    $matchLine = 0;
	} elsif( $line =~ /^Sbjct/ ) {
	    push @sbjctList, $line;
	}
    }
    # Storing the query and sbjct lists in case they are needed later.
    # We could make this conditional to save memory.
    $self->{'_queryList'} = \@queryList; 
    $self->{'_sbjctList'} = \@sbjctList; 

    # Storing the match list in case it is needed later.
    $self->{'_matchList'} = \@matchList;

    if(not defined ($self->{'_numIdentical'})) {
        my $id_str = $self->_id_str;
        $self->throw( -text  => "Can't parse match statistics. Possibly a new or unrecognized Blast format. ($id_str)");
    }

    if(!scalar @queryList or !scalar @sbjctList) {
        my $id_str = $self->_id_str;
        $self->throw( "Can't find query or sbjct alignment lines. Possibly unrecognized Blast format. ($id_str)");
    }
}


#=head2 _set_score_stats (Private method)
#
# Usage     : called automatically by _set_data()
# Purpose   : Sets various score statistics obtained from the HSP listing.
# Argument  : String with any of the following formats:
#           : blast2:  Score = 30.1 bits (66), Expect = 9.2
#           : blast2:  Score = 158.2 bits (544), Expect(2) = e-110
#           : blast1:  Score = 410 (144.3 bits), Expect = 1.7e-40, P = 1.7e-40
#           : blast1:  Score = 55 (19.4 bits), Expect = 5.3, Sum P(3) = 0.99
# Throws    : Exception if the stats cannot be parsed, probably due to a change
#           : in the Blast report format.
#
#See Also   : L<_set_data()|_set_data>
#
#=cut

#--------------------
sub _set_score_stats {
#--------------------
    my ($self, $data) = @_;

    my ($expect, $p);

    if($data =~ /Score = +([\d.e+-]+) bits \(([\d.e+-]+)\), +Expect = +([\d.e+-]+)/) {
	# blast2 format n = 1
	$self->bits($1);
	$self->score($2);
	$expect            = $3;
    } elsif($data =~ /Score = +([\d.e+-]+) bits \(([\d.e+-]+)\), +Expect\((\d+)\) = +([\d.e+-]+)/) {
	# blast2 format n > 1
	$self->bits($1);
	$self->score($2);
	$self->{'_n'}      = $3;
	$expect            = $4;

    } elsif($data =~ /Score = +([\d.e+-]+) \(([\d.e+-]+) bits\), +Expect = +([\d.e+-]+), P = +([\d.e-]+)/) {
	# blast1 format, n = 1
	$self->score($1);
	$self->bits($2);
	$expect            = $3;
	$p                 = $4;

    } elsif($data =~ /Score = +([\d.e+-]+) \(([\d.e+-]+) bits\), +Expect = +([\d.e+-]+), +Sum P\((\d+)\) = +([\d.e-]+)/) {
	# blast1 format, n > 1
	$self->score($1);
	$self->bits($2);
	$expect            = $3;
	$self->{'_n'}      = $4;
	$p                 = $5;

    } else {
        my $id_str = $self->_id_str;
	$self->throw(-class => 'Bio::Root::Exception',
		     -text => "Can't parse score statistics: unrecognized format. ($id_str)", 
		     -value => $data);
    }
    $expect = "1$expect" if $expect =~ /^e/i;    
    $p      = "1$p"      if defined $p and $p=~ /^e/i; 

    $self->{'_expect'} = $expect;
    $self->{'_p'}      = $p || undef;    
    $self->significance( $p || $expect );
}


#=head2 _set_match_stats (Private method)
#
# Usage     : Private method; called automatically by _set_data()
# Purpose   : Sets various matching statistics obtained from the HSP listing.
# Argument  : blast2: Identities = 23/74 (31%), Positives = 29/74 (39%), Gaps = 17/74 (22%)
#           : blast2: Identities = 57/98 (58%), Positives = 74/98 (75%)
#           : blast1: Identities = 87/204 (42%), Positives = 126/204 (61%)
#           : blast1: Identities = 87/204 (42%), Positives = 126/204 (61%), Frame = -3
#           : WU-blast: Identities = 310/553 (56%), Positives = 310/553 (56%), Strand = Minus / Plus
# Throws    : Exception if the stats cannot be parsed, probably due to a change
#           : in the Blast report format.
# Comments  : The "Gaps = " data in the HSP header has a different meaning depending
#           : on the type of Blast: for BLASTP, this number is the total number of
#           : gaps in query+sbjct; for TBLASTN, it is the number of gaps in the
#           : query sequence only. Thus, it is safer to collect the data
#           : separately by examining the actual sequence strings as is done
#           : in _set_seq().
#
#See Also   : L<_set_data()|_set_data>, L<_set_seq()|_set_seq>
#
#=cut

#--------------------
sub _set_match_stats {
#--------------------
    my ($self, $data) = @_;

    if($data =~ m!Identities = (\d+)/(\d+)!) {
      # blast1 or 2 format
      $self->{'_numIdentical'} = $1;
      $self->{'_totalLength'}  = $2;
    }
    
    if($data =~ m!Positives = (\d+)/(\d+)!) {
      # blast1 or 2 format
      $self->{'_numConserved'} = $1;
      $self->{'_totalLength'}  = $2;
    }
    
    if($data =~ m!Frame = ([\d+-]+)!) { 
      $self->frame($1); 
    }

    # Strand data is not always present in this line.
    # _set_seq() will also set strand information.
    if($data =~ m!Strand = (\w+) / (\w+)!) { 
	$self->{'_queryStrand'} = $1; 
	$self->{'_sbjctStrand'} = $2; 
    }

#    if($data =~ m!Gaps = (\d+)/(\d+)!) {
#	 $self->{'_totalGaps'} = $1;
#    } else {
#	 $self->{'_totalGaps'} = 0;
#    }
}



#=head2 _set_seq_data (Private method)
#
# Usage     : called automatically when sequence data is requested.
# Purpose   : Sets the HSP sequence data for both query and sbjct sequences.
#           : Includes: start, stop, length, gaps, and raw sequence.
# Argument  : n/a
# Throws    : Propagates any exception thrown by _set_match_seq()
# Comments  : Uses raw data stored by _set_data() during object construction.
#           : These data are not always needed, so it is conditionally
#           : executed only upon demand by methods such as gaps(), _set_residues(),
#           : etc. _set_seq() does the dirty work.
#
#See Also   : L<_set_seq()|_set_seq>
#
#=cut

#-----------------
sub _set_seq_data {
#-----------------
    my $self = shift;

    $self->_set_seq('query', @{$self->{'_queryList'}});
    $self->_set_seq('sbjct', @{$self->{'_sbjctList'}});

    # Liberate some memory.
    @{$self->{'_queryList'}} = @{$self->{'_sbjctList'}} = ();
    undef $self->{'_queryList'};
    undef $self->{'_sbjctList'};

    $self->{'_set_seq_data'} = 1;
}



#=head2 _set_seq (Private method)
#
# Usage     : called automatically by _set_seq_data()
#           : $hsp_obj->($seq_type, @data);
# Purpose   : Sets sequence information for both the query and sbjct sequences.
#           : Directly counts the number of gaps in each sequence (if gapped Blast).
# Argument  : $seq_type = 'query' or 'sbjct'
#           : @data = all seq lines with the form:
#           : Query: 61  SPHNVKDRKEQNGSINNAISPTATANTSGSQQINIDSALRDRSSNVAAQPSLSDASSGSN 120
# Throws    : Exception if data strings cannot be parsed, probably due to a change
#           : in the Blast report format.
# Comments  : Uses first argument to determine which data members to set
#           : making this method sensitive data member name changes.
#           : Behavior is dependent on the type of BLAST analysis (TBLASTN, BLASTP, etc).
# Warning   : Sequence endpoints are normalized so that start < end. This affects HSPs
#           : for TBLASTN/X hits on the minus strand. Normalization facilitates use
#           : of range information by methods such as match().
#
#See Also   : L<_set_seq_data()|_set_seq_data>, L<matches()|matches>, L<range()|range>, L<start()|start>, L<end()|end>
#
#=cut

#-------------
sub _set_seq {
#-------------
    my $self      = shift;
    my $seqType   = shift;
    my @data      = @_;
    my @ranges    = ();
    my @sequence  = ();
    my $numGaps   = 0;

    foreach( @data ) {
        if( m/(\d+) *([^\d\s]+) *(\d+)/) {
            push @ranges, ( $1, $3 ) ;
            push @sequence, $2;
        #print STDERR "_set_seq found sequence \"$2\"\n";
	} else {
	    $self->warn("Bad sequence data: $_");
	}
    }

    if( !(scalar(@sequence) and scalar(@ranges))) {
        my $id_str = $self->_id_str;
	$self->throw("Can't set sequence: missing data. Possibly unrecognized Blast format. ($id_str)");
   }
 
    # Sensitive to member name changes.
    $seqType = "_\L$seqType\E";
    $self->{$seqType.'Start'} = $ranges[0];
    $self->{$seqType.'Stop'}  = $ranges[ $#ranges ];
    $self->{$seqType.'Seq'}   = \@sequence;
	
    $self->{$seqType.'Length'} = abs($ranges[ $#ranges ] - $ranges[0]) + 1;

    # Adjust lengths for BLASTX, TBLASTN, TBLASTX sequences
    # Converting nucl coords to amino acid coords.

    my $prog = $self->algorithm;
    if($prog eq 'TBLASTN' and $seqType eq '_sbjct') {
	$self->{$seqType.'Length'} /= 3;
    } elsif($prog eq 'BLASTX' and $seqType eq '_query') {
	$self->{$seqType.'Length'} /= 3;
    } elsif($prog eq 'TBLASTX') {
	$self->{$seqType.'Length'} /= 3;
    }

    if( $prog ne 'BLASTP' ) {
        $self->{$seqType.'Strand'} = 'Plus' if $prog =~ /BLASTN/;
        $self->{$seqType.'Strand'} = 'Plus' if ($prog =~ /BLASTX/ and $seqType eq '_query');
        # Normalize sequence endpoints so that start < end.
        # Reverse complement or 'minus strand' HSPs get flipped here.
        if($self->{$seqType.'Start'} > $self->{$seqType.'Stop'}) {
            ($self->{$seqType.'Start'}, $self->{$seqType.'Stop'}) = 
                ($self->{$seqType.'Stop'}, $self->{$seqType.'Start'});
            $self->{$seqType.'Strand'} = 'Minus';
        }
    }

    ## Count number of gaps in each seq. Only need to do this for gapped Blasts.
#    if($self->{'_gapped'}) {
	my $seqstr = join('', @sequence);
	$seqstr =~ s/\s//g;
        my $num_gaps = CORE::length($seqstr) - $self->{$seqType.'Length'};
	$self->{$seqType.'Gaps'} = $num_gaps if $num_gaps > 0;
#    }
}


#=head2 _set_residues (Private method)
#
# Usage     : called automatically when residue data is requested.
# Purpose   : Sets the residue numbers representing the identical and
#           : conserved positions. These data are obtained by analyzing the
#           : symbols between query and sbjct lines of the alignments.
# Argument  : n/a
# Throws    : Propagates any exception thrown by _set_seq_data() and _set_match_seq().
# Comments  : These data are not always needed, so it is conditionally
#           : executed only upon demand by methods such as seq_inds().
#           : Behavior is dependent on the type of BLAST analysis (TBLASTN, BLASTP, etc).
#
#See Also   : L<_set_seq_data()|_set_seq_data>, L<_set_match_seq()|_set_match_seq>, seq_inds()
#
#=cut

#------------------
sub _set_residues {
#------------------
    my $self      = shift;
    my @sequence  = ();

    $self->_set_seq_data() unless $self->{'_set_seq_data'};

    # Using hashes to avoid saving duplicate residue numbers.
    my %identicalList_query = ();
    my %identicalList_sbjct = ();
    my %conservedList_query = ();
    my %conservedList_sbjct = ();
    
    my $aref = $self->_set_match_seq() if not ref $self->{'_matchSeq'};
    $aref  ||= $self->{'_matchSeq'};
    my $seqString = join('', @$aref );

    my $qseq = join('',@{$self->{'_querySeq'}});
    my $sseq = join('',@{$self->{'_sbjctSeq'}});
    my $resCount_query = $self->{'_queryStop'} || 0;
    my $resCount_sbjct = $self->{'_sbjctStop'} || 0;

    my $prog = $self->algorithm;
    if($prog !~ /^BLASTP|^BLASTN/) {
	if($prog eq 'TBLASTN') {
	    $resCount_sbjct /= 3;
	} elsif($prog eq 'BLASTX') {
	    $resCount_query /= 3;
	} elsif($prog eq 'TBLASTX') {
	    $resCount_query /= 3;
	    $resCount_sbjct /= 3;
	}
    }

    my ($mchar, $schar, $qchar);
    while( $mchar = chop($seqString) ) {
	($qchar, $schar) = (chop($qseq), chop($sseq));
	if( $mchar eq '+' ) { 
	    $conservedList_query{ $resCount_query } = 1; 
	    $conservedList_sbjct{ $resCount_sbjct } = 1; 
	} elsif( $mchar ne ' ' ) { 
	    $identicalList_query{ $resCount_query } = 1; 
	    $identicalList_sbjct{ $resCount_sbjct } = 1;
	}
	$resCount_query-- if $qchar ne $GAP_SYMBOL;
	$resCount_sbjct-- if $schar ne $GAP_SYMBOL;
    }
    $self->{'_identicalRes_query'} = \%identicalList_query;
    $self->{'_conservedRes_query'} = \%conservedList_query;
    $self->{'_identicalRes_sbjct'} = \%identicalList_sbjct;
    $self->{'_conservedRes_sbjct'} = \%conservedList_sbjct;

}




#=head2 _set_match_seq (Private method)
#
# Usage     : $hsp_obj->_set_match_seq()
# Purpose   : Set the 'match' sequence for the current HSP (symbols in between
#           : the query and sbjct lines.)				
# Returns   : Array reference holding the match sequences lines.
# Argument  : n/a
# Throws    : Exception if the _matchList field is not set.
# Comments  : The match information is not always necessary. This method
#           : allows it to be conditionally prepared.
#           : Called by _set_residues>() and seq_str().
#
#See Also   : L<_set_residues()|_set_residues>, L<seq_str()|seq_str>
#
#=cut

#-------------------
sub _set_match_seq {
#-------------------
    my $self = shift;

    if( ! ref($self->{'_matchList'}) ) {
        my $id_str = $self->_id_str;
        $self->throw("Can't set HSP match sequence: No data ($id_str)");
    }
    
    my @data = @{$self->{'_matchList'}};

    my(@sequence);
    foreach( @data ) {
	chomp($_);
	## Remove leading spaces; (note: aln may begin with a space
	## which is why we can't use s/^ +//).
	s/^ {$self->{'_match_indent'}}//;   
	push @sequence, $_;
    }
    # Liberate some memory.
    @{$self->{'_matchList'}} = undef;
    $self->{'_matchList'} = undef;

    $self->{'_matchSeq'} = \@sequence;

    return $self->{'_matchSeq'};
}


#line 1139

#-----
sub n { my $self = shift; $self->{'_n'} || ''; }
#-----


#line 1168

#-----------
sub matches {
#-----------
    my( $self, %param ) = @_;
    my(@data);
    my($seqType, $beg, $end) = ($param{-SEQ}, $param{-START}, $param{-STOP});
    $seqType ||= 'query';
    $seqType = 'sbjct' if $seqType eq 'hit';

    my($start,$stop);

    if(!defined $beg && !defined $end) {
	## Get data for the whole alignment.
	push @data, ($self->{'_numIdentical'}, $self->{'_numConserved'});
    } else {
	## Get the substring representing the desired sub-section of aln.
	$beg ||= 0;
	$end ||= 0;
	($start,$stop) = $self->range($seqType);
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
        my $prog = $self->algorithm;
	if (($prog eq 'TBLASTN') and ($seqType eq 'sbjct'))
	{
	    $seq = substr($self->seq_str('match'),
			  int(($beg-$start)/3), int(($end-$beg+1)/3));

	} elsif (($prog eq 'BLASTX') and ($seqType eq 'query'))
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
            my $id_str = $self->_id_str;
	    $self->throw("Undefined $seqType sub-sequence ($beg,$end). Valid range = $start - $stop ($id_str)");
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


#line 1262

#-------------------
sub num_identical {
#-------------------
    my( $self) = shift;

    $self->{'_numIdentical'};
}


#line 1284

#-------------------
sub num_conserved {
#-------------------
    my( $self) = shift;

    $self->{'_numConserved'};
}



#line 1310

#----------
sub range {
#----------
    my ($self, $seqType) = @_;

    $self->_set_seq_data() unless $self->{'_set_seq_data'};

    $seqType ||= 'query';
    $seqType = 'sbjct' if $seqType eq 'hit';

    ## Sensitive to member name changes.
    $seqType = "_\L$seqType\E";

    return ($self->{$seqType.'Start'},$self->{$seqType.'Stop'});
}

#line 1347

#----------
sub start {
#----------
    my ($self, $seqType) = @_;

    $seqType ||= (wantarray ? 'list' : 'query');
    $seqType = 'sbjct' if $seqType eq 'hit';

    $self->_set_seq_data() unless $self->{'_set_seq_data'};

    if($seqType =~ /list|array/i) {
	return ($self->{'_queryStart'}, $self->{'_sbjctStart'});
    } else {
	## Sensitive to member name changes.
	$seqType = "_\L$seqType\E";
	return $self->{$seqType.'Start'};
    }
}

#line 1387

#----------
sub end {
#----------
    my ($self, $seqType) = @_;

    $seqType ||= (wantarray ? 'list' : 'query');
    $seqType = 'sbjct' if $seqType eq 'hit';

    $self->_set_seq_data() unless $self->{'_set_seq_data'};

    if($seqType =~ /list|array/i) {
	return ($self->{'_queryStop'}, $self->{'_sbjctStop'});
    } else {
	## Sensitive to member name changes.
	$seqType = "_\L$seqType\E";
	return $self->{$seqType.'Stop'};
    }
}



#line 1431

#-----------
sub strand {
#-----------
    my( $self, $seqType ) = @_;

    # Hack to deal with the fact that SimilarityPair calls strand()
    # which will lead to an error because parsing hasn't yet occurred.
    # See SimilarityPair::new().
    return if $self->{'_initializing'};

    $seqType  ||= (wantarray ? 'list' : 'query');
    $seqType = 'sbjct' if $seqType eq 'hit';

    ## Sensitive to member name format.
    $seqType = "_\L$seqType\E";

    # $seqType could be '_list'.
    $self->{'_queryStrand'} or $self->_set_seq_data() unless $self->{'_set_seq_data'};

    my $prog = $self->algorithm;

    if($seqType  =~ /list|array/i) {
        my ($qstr, $hstr);
        if( $prog eq 'BLASTP') {
            $qstr = 0;
            $hstr = 0;
        }
        elsif( $prog eq 'TBLASTN') {
            $qstr = 0;
            $hstr = $STRAND_SYMBOL{$self->{'_sbjctStrand'}};
        }
        elsif( $prog eq 'BLASTX') {
            $qstr = $STRAND_SYMBOL{$self->{'_queryStrand'}};
            $hstr = 0;
        }
        else {
            $qstr = $STRAND_SYMBOL{$self->{'_queryStrand'}} if defined $self->{'_queryStrand'};
            $hstr = $STRAND_SYMBOL{$self->{'_sbjctStrand'}} if defined $self->{'_sbjctStrand'};
        }
        $qstr ||= 0;
        $hstr ||= 0;  
	return ($qstr, $hstr);
    }
    local $^W = 0;
    $STRAND_SYMBOL{$self->{$seqType.'Strand'}} || 0;
}


#line 1497

#-------
sub seq {
#-------
    my($self,$seqType) = @_; 
    $seqType ||= 'query';
    $seqType = 'sbjct' if $seqType eq 'hit';
    my $str = $self->seq_str($seqType);
	
    require Bio::Seq;

    new Bio::Seq (-ID   => $self->to_string,
		  -SEQ  => $str,
		  -DESC => "$seqType sequence",
		  );
}

#line 1531

#------------
sub seq_str {  
#------------
    my($self,$seqType) = @_; 

    $seqType ||= 'query';
    $seqType = 'sbjct' if $seqType eq 'hit';
    ## Sensitive to member name changes.
    $seqType = "_\L$seqType\E";

    $self->_set_seq_data() unless $self->{'_set_seq_data'};

    if($seqType =~ /sbjct|query/) {
	my $seq = join('',@{$self->{$seqType.'Seq'}}); 
	$seq =~ s/\s+//g;
	return $seq;

    } elsif( $seqType =~ /match/i) {
	# Only need to call _set_match_seq() if the match seq is requested.
	my $aref = $self->_set_match_seq() unless ref $self->{'_matchSeq'};
	$aref =  $self->{'_matchSeq'};

	return join('',@$aref); 

    } else {
        my $id_str = $self->_id_str;
	$self->throw(-class => 'Bio::Root::BadParameter',
		     -text => "Invalid or undefined sequence type: $seqType ($id_str)\n" . 
		               "Valid types: query, sbjct, match",
		     -value => $seqType);
    }
}

#line 1591

#---------------
sub seq_inds {
#---------------
    my ($self, $seqType, $class, $collapse) = @_;

    $seqType  ||= 'query';
    $class ||= 'identical';
    $collapse ||= 0;
    $seqType = 'sbjct' if $seqType eq 'hit';

    $self->_set_residues() unless defined $self->{'_identicalRes_query'};

    $seqType  = ($seqType !~ /^q/i ? 'sbjct' : 'query');
    $class = ($class !~ /^id/i ? 'conserved' : 'identical');

    ## Sensitive to member name changes.
    $seqType  = "_\L$seqType\E";
    $class = "_\L$class\E";

    my @ary = sort { $a <=> $b } keys %{ $self->{"${class}Res$seqType"}};

    require Bio::Search::BlastUtils if $collapse;

    return $collapse ? &Bio::Search::BlastUtils::collapse_nums(@ary) : @ary;
}


#line 1637

#------------
sub get_aln {
#------------
    my $self = shift;

    require Bio::SimpleAlign;
    require Bio::LocatableSeq;
    my $qseq = $self->seq('query');
    my $sseq = $self->seq('sbjct');

    my $type = $self->algorithm =~ /P$|^T/ ? 'amino' : 'dna';
    my $aln = new Bio::SimpleAlign();
    $aln->add_seq(new Bio::LocatableSeq(-seq => $qseq->seq(),
					-id  => 'query_'.$qseq->display_id(),
					-start => 1,
					-end   => CORE::length($qseq)));
		  
    $aln->add_seq(new Bio::LocatableSeq(-seq => $sseq->seq(),
					-id  => 'hit_'.$sseq->display_id(),
					-start => 1,
					-end   => CORE::length($sseq)));
		  
    return $aln;
}


1;
__END__


#line 1733

1;

