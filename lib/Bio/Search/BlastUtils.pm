#line 1 "Bio/Search/BlastUtils.pm"

#line 24

#'

package Bio::Search::BlastUtils;



#line 107

#--------------
sub tile_hsps {
#--------------
    my $sbjct = shift;

    $sbjct->{'_tile_hsps'} = 1;
    $sbjct->{'_gaps_query'} = 0;
    $sbjct->{'_gaps_sbjct'} = 0;

    ## Simple summation scheme. Valid if there is only one HSP.
    if((defined($sbjct->{'_n'}) and $sbjct->{'_n'} == 1) or $sbjct->num_hsps == 1) {
	my $hsp = $sbjct->hsp;
	$sbjct->{'_length_aln_query'} = $hsp->length('query');
	$sbjct->{'_length_aln_sbjct'} = $hsp->length('sbjct');
	$sbjct->{'_length_aln_total'} = $hsp->length('total');
	($sbjct->{'_totalIdentical'},$sbjct->{'_totalConserved'}) = $hsp->matches();
	$sbjct->{'_gaps_query'} = $hsp->gaps('query');
	$sbjct->{'_gaps_sbjct'} = $hsp->gaps('sbjct');

#	print "_tile_hsps(): single HSP, easy stats.\n";
	return;
    } else {
#	print STDERR "Sbjct: _tile_hsps: summing multiple HSPs\n";
	$sbjct->{'_length_aln_query'} = 0;
	$sbjct->{'_length_aln_sbjct'} = 0;
	$sbjct->{'_length_aln_total'} = 0;
	$sbjct->{'_totalIdentical'}   = 0;
	$sbjct->{'_totalConserved'}   = 0;
    }

    ## More than one HSP. Must tile HSPs.
#    print "\nTiling HSPs for $sbjct\n";
    my($hsp, $qstart, $qstop, $sstart, $sstop);
    my($frame, $strand, $qstrand, $sstrand);
    my(@qcontigs, @scontigs);
    my $qoverlap = 0;
    my $soverlap = 0;
    my $max_overlap = $sbjct->{'_overlap'};

    foreach $hsp ($sbjct->hsps()) {
#	printf "  HSP: %s\n%s\n",$hsp->name, $hsp->str('query');
#	printf "  Length = %d; Identical = %d; Conserved = %d; Conserved(1-10): %d",$hsp->length, $hsp->length(-TYPE=>'iden'), $hsp->length(-TYPE=>'cons'), $hsp->length(-TYPE=>'cons',-START=>0,-STOP=>10); 
	($qstart, $qstop) = $hsp->range('query');
	($sstart, $sstop) = $hsp->range('sbjct');
	$frame = $hsp->frame;
	$frame = -1 unless defined $frame;
	($qstrand, $sstrand) = $hsp->strand;

	my ($qgaps, $sgaps)  = $hsp->gaps();
	$sbjct->{'_gaps_query'} += $qgaps;
	$sbjct->{'_gaps_sbjct'} += $sgaps;

	$sbjct->{'_length_aln_total'} += $hsp->length;
	## Collect contigs in the query sequence.
	$qoverlap = &_adjust_contigs('query', $hsp, $qstart, $qstop, \@qcontigs, $max_overlap, $frame, $qstrand);

	## Collect contigs in the sbjct sequence (needed for domain data and gapped Blast).
	$soverlap = &_adjust_contigs('sbjct', $hsp, $sstart, $sstop, \@scontigs, $max_overlap, $frame, $sstrand);

	## Collect overall start and stop data for query and sbjct over all HSPs.
	if(not defined $sbjct->{'_queryStart'}) {
	    $sbjct->{'_queryStart'} = $qstart;
	    $sbjct->{'_queryStop'}  = $qstop;
	    $sbjct->{'_sbjctStart'} = $sstart;
	    $sbjct->{'_sbjctStop'}  = $sstop;
	} else {
	    $sbjct->{'_queryStart'} = ($qstart < $sbjct->{'_queryStart'} ? $qstart : $sbjct->{'_queryStart'});
	    $sbjct->{'_queryStop'}  = ($qstop  > $sbjct->{'_queryStop'}  ? $qstop  : $sbjct->{'_queryStop'});
	    $sbjct->{'_sbjctStart'} = ($sstart < $sbjct->{'_sbjctStart'} ? $sstart : $sbjct->{'_sbjctStart'});
	    $sbjct->{'_sbjctStop'}  = ($sstop  > $sbjct->{'_sbjctStop'}  ? $sstop  : $sbjct->{'_sbjctStop'});
	}	    
    }

    ## Collect data across the collected contigs.

#    print "\nQUERY CONTIGS:\n";
#    print "  gaps = $sbjct->{'_gaps_query'}\n";

    # TODO: Account for strand/frame issue!
    # Strategy: collect data on a per strand+frame basis and save the most significant one.
    my (%qctg_dat);
    foreach(@qcontigs) {
#	print "  query contig: $_->{'start'} - $_->{'stop'}\n";
#	print "         iden = $_->{'iden'}; cons = $_->{'cons'}\n";
	($frame, $strand) = ($_->{'frame'}, $_->{'strand'});
	$qctg_dat{ "$frame$strand" }->{'length_aln_query'} += $_->{'stop'} - $_->{'start'} + 1;
	$qctg_dat{ "$frame$strand" }->{'totalIdentical'}   += $_->{'iden'};
	$qctg_dat{ "$frame$strand" }->{'totalConserved'}   += $_->{'cons'};
	$qctg_dat{ "$frame$strand" }->{'qstrand'}   = $strand;
    }

    # Find longest contig.
    my @sortedkeys = reverse sort { $qctg_dat{ $a }->{'length_aln_query'} <=> $qctg_dat{ $b }->{'length_aln_query'} } keys %qctg_dat;

    # Save the largest to the sbjct:
    my $longest = $sortedkeys[0];
    $sbjct->{'_length_aln_query'} = $qctg_dat{ $longest }->{'length_aln_query'};
    $sbjct->{'_totalIdentical'}   = $qctg_dat{ $longest }->{'totalIdentical'};
    $sbjct->{'_totalConserved'}   = $qctg_dat{ $longest }->{'totalConserved'};
    $sbjct->{'_qstrand'} = $qctg_dat{ $longest }->{'qstrand'};

    ## Collect data for sbjct contigs. Important for gapped Blast.
    ## The totalIdentical and totalConserved numbers will be the same
    ## as determined for the query contigs.

#    print "\nSBJCT CONTIGS:\n";
#    print "  gaps = $sbjct->{'_gaps_sbjct'}\n";

    my (%sctg_dat);
    foreach(@scontigs) {
#	print "  sbjct contig: $_->{'start'} - $_->{'stop'}\n";
#	print "         iden = $_->{'iden'}; cons = $_->{'cons'}\n";
	($frame, $strand) = ($_->{'frame'}, $_->{'strand'});
	$sctg_dat{ "$frame$strand" }->{'length_aln_sbjct'}   += $_->{'stop'} - $_->{'start'} + 1;
	$sctg_dat{ "$frame$strand" }->{'frame'}  = $frame;
	$sctg_dat{ "$frame$strand" }->{'sstrand'}  = $strand;
    }

    @sortedkeys = reverse sort { $sctg_dat{ $a }->{'length_aln_sbjct'} <=> $sctg_dat{ $b }->{'length_aln_sbjct'} } keys %sctg_dat;

    # Save the largest to the sbjct:
    $longest = $sortedkeys[0];

    $sbjct->{'_length_aln_sbjct'} = $sctg_dat{ $longest }->{'length_aln_sbjct'};
    $sbjct->{'_frame'} = $sctg_dat{ $longest }->{'frame'};
    $sbjct->{'_sstrand'} = $sctg_dat{ $longest }->{'sstrand'};

    if($qoverlap) {
	if($soverlap) { $sbjct->ambiguous_aln('qs'); 
#			print "\n*** AMBIGUOUS ALIGNMENT: Query and Sbjct\n\n";
		      }
	else { $sbjct->ambiguous_aln('q');
#	       print "\n*** AMBIGUOUS ALIGNMENT: Query\n\n";
	   }
    } elsif($soverlap) { 
	$sbjct->ambiguous_aln('s'); 
#	print "\n*** AMBIGUOUS ALIGNMENT: Sbjct\n\n";
    }

    # Adjust length based on BLAST flavor.
    my $prog = $sbjct->algorithm;
    if($prog eq 'TBLASTN') {
	$sbjct->{'_length_aln_sbjct'} /= 3;
    } elsif($prog eq 'BLASTX' ) {
	$sbjct->{'_length_aln_query'} /= 3;
    } elsif($prog eq 'TBLASTX') {
	$sbjct->{'_length_aln_query'} /= 3;
	$sbjct->{'_length_aln_sbjct'} /= 3;
    }
}



#line 280

#-------------------
sub _adjust_contigs {
#-------------------
    my ($seqType, $hsp, $start, $stop, $contigs_ref, $max_overlap, $frame, $strand) = @_;

    my $overlap = 0;
    my ($numID, $numCons);

#    print STDERR "Testing $seqType data: HSP (${\$hsp->name});  $start, $stop, strand=$strand, frame=$frame\n"; 
    foreach(@$contigs_ref) {
#	print STDERR "  Contig: $_->{'start'} - $_->{'stop'}, strand=$_->{'strand'}, frame=$_->{'frame'}, iden= $_->{'iden'}, cons= $_->{'cons'}\n";

	# Don't merge things unless they have matching strand/frame.
	next unless ($_->{'frame'} == $frame and $_->{'strand'} == $strand);

	## Test special case of a nested HSP. Skip it.
	if($start >= $_->{'start'} and $stop <= $_->{'stop'}) { 
#	    print STDERR "----> Nested HSP. Skipping.\n";
	    $overlap = 1; 
	    next;
	}

	## Test for overlap at beginning of contig.
	if($start < $_->{'start'} and $stop > ($_->{'start'} + $max_overlap)) { 
#	    print STDERR "----> Overlaps beg: existing beg,end: $_->{'start'},$_->{'stop'}, new beg,end: $start,$stop\n";
	    # Collect stats over the non-overlapping region.
	    eval {
		($numID, $numCons) = $hsp->matches(-SEQ   =>$seqType, 
						   -START =>$start, 
						   -STOP  =>$_->{'start'}-1); 
	    };
	    if($@) { warn "\a\n$@\n"; }
	    else {
		$_->{'start'} = $start; # Assign a new start coordinate to the contig
		$_->{'iden'} += $numID; # and add new data to #identical, #conserved.
		$_->{'cons'} += $numCons;
		$overlap     = 1; 
	    }
	}

	## Test for overlap at end of contig.
	if($stop > $_->{'stop'} and $start < ($_->{'stop'} - $max_overlap)) { 
#	    print STDERR "----> Overlaps end: existing beg,end: $_->{'start'},$_->{'stop'}, new beg,end: $start,$stop\n";
	    # Collect stats over the non-overlapping region.
	    eval {
		($numID,$numCons) = $hsp->matches(-SEQ   =>$seqType, 
						  -START =>$_->{'stop'}, 
						  -STOP  =>$stop); 
	    };
	    if($@) { warn "\a\n$@\n"; }
	    else {
		$_->{'stop'}  = $stop;  # Assign a new stop coordinate to the contig
		$_->{'iden'} += $numID; # and add new data to #identical, #conserved.
		$_->{'cons'} += $numCons;
		$overlap    = 1; 
	    }
	}
	$overlap && do {
#		print STDERR " New Contig data:\n";
#		print STDERR "  Contig: $_->{'start'} - $_->{'stop'}, iden= $_->{'iden'}, cons= $_->{'cons'}\n";
		last;
	    };
    }
    ## If there is no overlap, add the complete HSP data.
    !$overlap && do {
#	print STDERR "No overlap. Adding new contig.\n";
	($numID,$numCons) = $hsp->matches(-SEQ=>$seqType); 
	push @$contigs_ref, {'start'=>$start, 'stop'=>$stop,
			     'iden'=>$numID,  'cons'=>$numCons,
			     'strand'=>$strand, 'frame'=>$frame};
    };
    $overlap;
}

#line 372

#------------------
sub get_exponent {
#------------------
    my $data = shift;

    my($num, $exp) = split /[eE]/, $data;

    if( defined $exp) { 
	$num = 1 if not $num;
	$num >= 5 and $exp++;
	$num <= -5 and $exp--;
    } elsif( $num == 0) {
	$exp = -999;
    } elsif( not $num =~ /\./) {
	$exp = CORE::length($num) -1;
    } else {
	$exp = 0;
	$num .= '0' if $num =~ /\.$/;
	my ($c);
	my $rev = 0;
	if($num !~ /^0/) {
	    $num = reverse($num);
	    $rev = 1;
	}
	do { $c = chop($num);
	     $c == 0 && $exp++; 
	 } while( $c ne '.');

	$exp = -$exp if $num == 0 and not $rev;
	$exp -= 1 if $rev;
    }
    return $exp;
}

#line 423

#------------------
sub collapse_nums {
#------------------
# This is probably not the slickest connectivity algorithm, but will do for now.
    my @a = @_;
    my ($from, $to, $i, @ca, $consec);
    
    $consec = 0;
    for($i=0; $i < @a; $i++) {
	not $from and do{ $from = $a[$i]; next; };
	if($a[$i] == $a[$i-1]+1) {
	    $to = $a[$i];
	    $consec++;
	} else {
	    if($consec == 1) { $from .= ",$to"; }
	    else { $from .= $consec>1 ? "\-$to" : ""; }
	    push @ca, split(',', $from);
	    $from =  $a[$i];
	    $consec = 0;
	    $to = undef;
	}
    }
    if(defined $to) {
	if($consec == 1) { $from .= ",$to"; }
	else { $from .= $consec>1 ? "\-$to" : ""; }
    }
    push @ca, split(',', $from) if $from;

    @ca;
}


#line 492

#--------------------
sub strip_blast_html {
#--------------------
      # This may not best way to remove html tags. However, it is simple.
      # it won't work under following conditions:
      #    1) if quoted > appears in a tag  (does this ever happen?)
      #    2) if a tag is split over multiple lines and this method is
      #       used to process one line at a time.
      
    my ($string_ref) = shift;

    ref $string_ref eq 'SCALAR' or 
	croak ("Can't strip HTML: ".
	       "Argument is should be a SCALAR reference not a ${\ref $string_ref}\n");

    my $str = $$string_ref;
    my $stripped = 0;

    # Removing "<a name =...>" and adding the '>' character for 
    # HSP alignment listings.
    $str =~ s/(\A|\n)<a name ?=[^>]+> ?/>/sgi and $stripped = 1;

    # Removing all "<>" tags. 
    $str =~ s/<[^>]+>|&nbsp//sgi and $stripped = 1;

    # Re-uniting any lone '>' characters.
    $str =~ s/(\A|\n)>\s+/\n\n>/sgi and $stripped = 1;

    $$string_ref = $str;
    $stripped;
}


1;


