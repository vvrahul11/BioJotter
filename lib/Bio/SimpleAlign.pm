#line 1 "Bio/SimpleAlign.pm"
# $Id: SimpleAlign.pm,v 1.65.2.1 2003/07/02 16:00:19 jason Exp $
# BioPerl module for SimpleAlign
#
# Cared for by Heikki Lehvaslaiho <heikki@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code
#
#  History:
#	11/3/00 Added threshold feature to consensus and consensus_aa  - PS
#	May 2001 major rewrite - Heikki Lehvaslaiho

#line 137

# 'Let the code begin...

package Bio::SimpleAlign;
use vars qw(@ISA %CONSERVATION_GROUPS);
use strict;

use Bio::Root::Root;
use Bio::LocatableSeq;         # uses Seq's as list
use Bio::Align::AlignI;

BEGIN {
    # This data should probably be in a more centralized module...
    # it is taken from Clustalw documentation
    # These are all the positively scoring groups that occur in the
    # Gonnet Pam250 matrix. The strong and weak groups are
    # defined as strong score >0.5 and weak score =<0.5 respectively.

    %CONSERVATION_GROUPS = ( 'strong' => [ qw(STA
						 NEQK
						 NHQK
						 NDEQ
						 QHRK
						 MILV
						 MILF
						 HY
						 FYW)
					      ],
				'weak' => [ qw(CSA
					       ATV
					       SAG
					       STNK
					       STPA
					       SGND
					       SNDEQK
					       NDEQHK
					       NEQHRK
					       FVLIM
					       HFY) ],
				);

}

@ISA = qw(Bio::Root::Root Bio::Align::AlignI);

#line 192


sub new {
  my($class,@args) = @_;

  my $self = $class->SUPER::new(@args);

  my ($src) = $self->_rearrange([qw(SOURCE)], @args);
  $src && $self->source($src);
  # we need to set up internal hashs first!

  $self->{'_seq'} = {};
  $self->{'_order'} = {};
  $self->{'_start_end_lists'} = {};
  $self->{'_dis_name'} = {};
  $self->{'_id'} = 'NoName';
  $self->{'_symbols'} = {};
  # maybe we should automatically read in from args. Hmmm...

  return $self; # success - we hope!
}

#line 232

sub addSeq {
    my $self = shift;
    $self->warn(ref($self). "::addSeq - deprecated method. Use add_seq() instead.");
    $self->add_seq(@_);
}

sub add_seq {
    my $self = shift;
    my $seq  = shift;
    my $order = shift;
    my ($name,$id,$start,$end);

    if( !ref $seq || ! $seq->isa('Bio::LocatableSeq') ) {
	$self->throw("Unable to process non locatable sequences [", ref($seq), "]");
    }

    $id = $seq->id() ||$seq->display_id || $seq->primary_id;
    $start = $seq->start();
    $end  = $seq->end();

    # build the symbol list for this sequence,
    # will prune out the gap and missing/match chars
    # when actually asked for the symbol list in the
    # symbol_chars
    map { $self->{'_symbols'}->{$_} = 1; } split(//,$seq->seq);

    if( !defined $order ) {
	$order = keys %{$self->{'_seq'}};
    }
    $name = sprintf("%s/%d-%d",$id,$start,$end);

    if( $self->{'_seq'}->{$name} ) {
	$self->warn("Replacing one sequence [$name]\n");
    }
    else {
	#print STDERR "Assigning $name to $order\n";

	$self->{'_order'}->{$order} = $name;

	unless( exists( $self->{'_start_end_lists'}->{$id})) {
	    $self->{'_start_end_lists'}->{$id} = [];
	}
	push @{$self->{'_start_end_lists'}->{$id}}, $seq;
    }

    $self->{'_seq'}->{$name} = $seq;

}


#line 292

sub removeSeq {
    my $self = shift;
    $self->warn(ref($self). "::removeSeq - deprecated method. Use remove_seq() instead.");
    $self->remove_seq(@_);
}

sub remove_seq {
    my $self = shift;
    my $seq = shift;
    my ($name,$id,$start,$end);

    $self->throw("Need Bio::Locatable seq argument ")
	unless ref $seq && $seq->isa('Bio::LocatableSeq');

    $id = $seq->id();
    $start = $seq->start();
    $end  = $seq->end();
    $name = sprintf("%s/%d-%d",$id,$start,$end);

    if( !exists $self->{'_seq'}->{$name} ) {
	$self->throw("Sequence $name does not exist in the alignment to remove!");
    }

    delete $self->{'_seq'}->{$name};

    # we need to remove this seq from the start_end_lists hash

    if (exists $self->{'_start_end_lists'}->{$id}) {
	# we need to find the sequence in the array.

	my ($i, $found);;
	for ($i=0; $i < @{$self->{'_start_end_lists'}->{$id}}; $i++) {
	    if (${$self->{'_start_end_lists'}->{$id}}[$i] eq $seq) {
		$found = 1;
		last;
	    }
	}
	if ($found) {
	    splice @{$self->{'_start_end_lists'}->{$id}}, $i, 1;
	}
	else {
	    $self->throw("Could not find the sequence to remoce from the start-end list");
	}
    }
    else {
	$self->throw("There is no seq list for the name $id");
    }
    return 1;
    # we can't do anything about the order hash but that is ok
    # because each_seq will handle it
}


#line 360

sub purge {
    my ($self,$perc) = @_;
    my (%duplicate, @dups);

    my @seqs = $self->each_seq();

    for (my $i=0;$i< @seqs - 1;$i++ ) { #for each seq in alignment
	my $seq = $seqs[$i];

	#skip if already in duplicate hash
	next if exists $duplicate{$seq->display_id} ;
	my $one = $seq->seq();

	my @one = split '', $one;	#split to get 1aa per array element

	for (my $j=$i+1;$j < @seqs;$j++) {
	    my $seq2 = $seqs[$j];

	    #skip if already in duplicate hash
	    next if exists $duplicate{$seq2->display_id} ;

	    my $two = $seq2->seq();
	    my @two = split '', $two;

	    my $count = 0;
	    my $res = 0;
	    for (my $k=0;$k<@one;$k++) {
		if ( $one[$k] ne '.' && $one[$k] ne '-' && defined($two[$k]) &&
		     $one[$k] eq $two[$k]) {
		    $count++;
		}
		if ( $one[$k] ne '.' && $one[$k] ne '-' && defined($two[$k]) &&
		     $two[$k] ne '.' && $two[$k] ne '-' ) {
		    $res++;
		}
	    }

	    my $ratio = 0;
	    $ratio = $count/$res unless $res == 0;

	    # if above threshold put in duplicate hash and push onto
	    # duplicate array for returning to get_unique
	    if ( $ratio > $perc ) {
		print STDERR "duplicate!", $seq2->display_id, "\n" if $self->verbose > 0;
		$duplicate{$seq2->display_id} = 1;
		push @dups, $seq2;
	    }
	}
    }
    foreach my $seq (@dups) {
	$self->remove_seq($seq);
    }
    return @dups;
}

#line 429

sub sort_alphabetically {
    my $self = shift;
    my ($seq,$nse,@arr,%hash,$count);

    foreach $seq ( $self->each_seq() ) {
	$nse = $seq->get_nse;
	$hash{$nse} = $seq;
    }

    $count = 0;

    %{$self->{'_order'}} = (); # reset the hash;

    foreach $nse ( sort _alpha_startend keys %hash) {
	$self->{'_order'}->{$count} = $nse;

	$count++;
    }
    1;
}

#line 464

sub eachSeq {
    my $self = shift;
    $self->warn(ref($self). "::eachSeq - deprecated method. Use each_seq() instead.");
    $self->each_seq();
}

sub each_seq {
    my $self = shift;
    my (@arr,$order);

    foreach $order ( sort { $a <=> $b } keys %{$self->{'_order'}} ) {
	if( exists $self->{'_seq'}->{$self->{'_order'}->{$order}} ) {
	    push(@arr,$self->{'_seq'}->{$self->{'_order'}->{$order}});
	}
    }

    return @arr;
}


#line 499

sub each_alphabetically {
    my $self = shift;
    my ($seq,$nse,@arr,%hash,$count);

    foreach $seq ( $self->each_seq() ) {
	$nse = $seq->get_nse;
	$hash{$nse} = $seq;
    }

    foreach $nse ( sort _alpha_startend keys %hash) {
	push(@arr,$hash{$nse});
    }

    return @arr;

}

sub _alpha_startend {
    my ($aname,$astart,$bname,$bstart);
    ($aname,$astart) = split (/-/,$a);
    ($bname,$bstart) = split (/-/,$b);

    if( $aname eq $bname ) {
	return $astart <=> $bstart;
    }
    else {
	return $aname cmp $bname;
    }

}

#line 545

sub eachSeqWithId {
    my $self = shift;
    $self->warn(ref($self). "::eachSeqWithId - deprecated method. Use each_seq_with_id() instead.");
    $self->each_seq_with_id(@_);
}

sub each_seq_with_id {
    my $self = shift;
    my $id = shift;

    $self->throw("Method each_seq_with_id needs a sequence name argument")
	unless defined $id;

    my (@arr, $seq);

    if (exists($self->{'_start_end_lists'}->{$id})) {
	@arr = @{$self->{'_start_end_lists'}->{$id}};
    }
    return @arr;
}

#line 581

sub get_seq_by_pos {

    my $self = shift;
    my ($pos) = @_;

    $self->throw("Sequence position has to be a positive integer, not [$pos]")
	unless $pos =~ /^\d+$/ and $pos > 0;
    $self->throw("No sequence at position [$pos]")
	unless $pos <= $self->no_sequences ;

    my $nse = $self->{'_order'}->{--$pos};
    return $self->{'_seq'}->{$nse};
}

#line 616

sub select {
    my $self = shift;
    my ($start, $end) = @_;

    $self->throw("Select start has to be a positive integer, not [$start]")
	unless $start =~ /^\d+$/ and $start > 0;
    $self->throw("Select end has to be a positive integer, not [$end]")
	unless $end  =~ /^\d+$/ and $end > 0;
    $self->throw("Select $start [$start] has to be smaller than or equal to end [$end]")
	unless $start <= $end;

    my $aln = new $self;
    foreach my $pos ($start .. $end) {
	$aln->add_seq($self->get_seq_by_pos($pos));
    }
    $aln->id($self->id);	
    return $aln;
}

#line 650

sub select_noncont {
    my $self = shift;
    my (@pos) = @_;
    my $end = $self->no_sequences;
    foreach ( @pos ) {
	$self->throw("position must be a positive integer, > 0 and <= $end not [$_]")
	    unless( /^\d+$/ && $_ > 0 && $_ <= $end );
    }
    my $aln = new $self;
    foreach my $p (@pos) {
	$aln->add_seq($self->get_seq_by_pos($p));
    }
    $aln->id($self->id);
    return $aln;
}

#line 684

sub slice {
    my $self = shift;
    my ($start, $end) = @_;

    $self->throw("Slice start has to be a positive integer, not [$start]")
	unless $start =~ /^\d+$/ and $start > 0;
    $self->throw("Slice end has to be a positive integer, not [$end]")
	unless $end =~ /^\d+$/ and $end > 0;
    $self->throw("Slice $start [$start] has to be smaller than or equal to end [$end]")
	unless $start <= $end;
    my $aln_length = $self->length;
    $self->throw("This alignment has only ". $self->length.
		  " residues. Slice start [$start] is too bigger.")
	 if $start > $self->length;

    my $aln = new $self;
    $aln->id($self->id);
    foreach my $seq ( $self->each_seq() ) {

	my $new_seq = new Bio::LocatableSeq (-id => $seq->id);

	# seq
	my $seq_end = $end;
	$seq_end = $seq->length if $end > $seq->length;
	my $slice_seq = $seq->subseq($start, $seq_end);
	$new_seq->seq( $slice_seq );

	# start
	if ($start > 1) {
	    my $pre_start_seq = $seq->subseq(1, $start - 1);
	    $pre_start_seq =~ s/\W//g; #print "$pre_start_seq\n";
	    $new_seq->start( $seq->start + CORE::length($pre_start_seq)  );
	} else {
	    $new_seq->start( $seq->start);
	}

	# end
	$slice_seq =~ s/\W//g;
	$new_seq->end( $new_seq->start + CORE::length($slice_seq) - 1 );

	if ($new_seq->start and $new_seq->end >= $new_seq->start) {
	    $aln->add_seq($new_seq);
	} else {
	    my $nse = $seq->get_nse();
	    $self->warn("Slice [$start-$end] of sequence [$nse] contains no residues.".
			" Sequence excluded from the new alignment.");
	}

    }

    return $aln;
}

#line 749

sub remove_columns{
    my ($self,$type) = @_;
    my %matchchars = ( 'match'  => '\*',
                       'weak'   => '\.',
                       'strong' => ':',
                       'mismatch'=> ' ',
               );
   #get the characters to delete against
   my $del_char;
   foreach my $type(@{$type}){
    $del_char.= $matchchars{$type};
   }

   my $match_line = $self->match_line;
   my $aln = new $self;

   my @remove;
   my $length = 0;

   #do the matching to get the segments to remove
   while($match_line=~m/[$del_char]/g){
    my $start = pos($match_line)-1;
    $match_line=~/\G[$del_char]+/gc;
    my $end = pos($match_line)-1;

    #have to offset the start and end for subsequent removes
    $start-=$length;
    $end  -=$length;
    $length += ($end-$start+1);
    push @remove, [$start,$end];
   }

  #remove the segments
  $aln = $self->_remove_col($aln,\@remove);

  return $aln;
}

sub _remove_col {
    my ($self,$aln,$remove) = @_;
    my @new;

    #splice out the segments and create new seq
    foreach my $seq($self->each_seq){
        my $new_seq = new Bio::LocatableSeq(-id=>$seq->id);
        my $sequence;
        foreach my $pair(@{$remove}){
            my $start = $pair->[0];
            my $end   = $pair->[1];
            $sequence = $seq->seq unless $sequence;
            my $spliced;
            $spliced .= $start > 0 ? substr($sequence,0,$start) : '';
            $spliced .= substr($sequence,$end+1,$seq->length-$end+1);
            $sequence = $spliced;
            if ($start == 1) {
              $new_seq->start($end);
            }
            else {
              $new_seq->start( $seq->start);
            }
            # end
            if($end >= $seq->end){
             $new_seq->end( $start);
            }
            else {
             $new_seq->end($seq->end);
            }
        }
        $new_seq->seq($sequence);
        push @new, $new_seq;
    }
    #add the new seqs to the alignment
    foreach my $new(@new){
        $aln->add_seq($new);
    }
    return $aln;
}

#line 852

sub map_chars {
    my $self = shift;
    my $from = shift;
    my $to   = shift;
    my ($seq,$temp);

    $self->throw("Need exactly two arguments") 
	unless defined $from and defined $to;

    foreach $seq ( $self->each_seq() ) {
	$temp = $seq->seq();
	$temp =~ s/$from/$to/g;
	$seq->seq($temp);
    }
    return 1;
}


#line 880

sub uppercase {
    my $self = shift;
    my $seq;
    my $temp;

    foreach $seq ( $self->each_seq() ) {
      $temp = $seq->seq();
      $temp =~ tr/[a-z]/[A-Z]/;

      $seq->seq($temp);
    }
    return 1;
}

#line 906

sub cigar_line {
    my ($self) = @_;

    my %cigar;
    my %clines;
    my @seqchars;
    my $seqcount = 0;
    my $sc;
    foreach my $seq ( $self->each_seq ) {
	push @seqchars, [ split(//, uc ($seq->seq)) ];
	$sc = scalar(@seqchars);
    }

    foreach my $pos ( 0..$self->length ) {
	my $i=0;
	foreach my $seq ( @seqchars ) {
	    $i++;
#	    print STDERR "Seq $i at pos $pos: ".$seq->[$pos]."\n";
	    if ($seq->[$pos] eq '.') {
		if (defined $cigar{$i} && $clines{$i} !~ $cigar{$i}) {
		    $clines{$i}.=$cigar{$i};
		}
	    }
	    else {
		if (! defined $cigar{$i}) {
		    $clines{$i}.=($pos+1).",";
		}
		$cigar{$i}=$pos+1;
	    }
	    if ($pos+1 == $self->length && ($clines{$i} =~ /\,$/) ) {
		$clines{$i}.=$cigar{$i};
	     }
	}
    }
    for(my $i=1; $i<$sc+1;$i++) {
	print STDERR "Seq $i cigar line ".$clines{$i}."\n";
    }
    return %clines;
}

#line 958

sub match_line {
    my ($self,$matchlinechar, $strong, $weak) = @_;
    my %matchchars = ( 'match'  => $matchlinechar || '*',
		       'weak'   => $weak          || '.',
		       'strong' => $strong        || ':',
		       'mismatch'=> ' ', 
	       );


    my @seqchars;
    my $seqcount = 0;
    my $alphabet;
    foreach my $seq ( $self->each_seq ) {
	push @seqchars, [ split(//, uc ($seq->seq)) ];
	$alphabet = $seq->alphabet unless defined $alphabet;
    }
    my $refseq = shift @seqchars;
    # let's just march down the columns
    my $matchline;
    POS: foreach my $pos ( 0..$self->length ) {
	my $refchar = $refseq->[$pos];
	next unless $refchar; # skip '' 
	my %col = ($refchar => 1);
	my $dash = ($refchar eq '-' || $refchar eq '.' || $refchar eq ' ');
	foreach my $seq ( @seqchars ) {
	    $dash = 1 if( $seq->[$pos] eq '-' || $seq->[$pos] eq '.' || 
			  $seq->[$pos] eq ' ' );
	    $col{$seq->[$pos]}++;
	}
	my @colresidues = sort keys %col;
	my $char = $matchchars{'mismatch'};
	# if all the values are the same
	if( $dash ) { $char =  $matchchars{'mismatch'} }
	elsif( @colresidues == 1 ) { $char = $matchchars{'match'} }
	elsif( $alphabet eq 'protein' ) { # only try to do weak/strong
	                                  # matches for protein seqs
	    TYPE: foreach my $type ( qw(strong weak) ) {
                # iterate through categories
		my %groups;
		# iterate through each of the aa in the col
		# look to see which groups it is in
		foreach my $c ( @colresidues ) {
		    foreach my $f ( grep /\Q$c/, @{$CONSERVATION_GROUPS{$type}} ) {
			push @{$groups{$f}},$c;
		    }
		}
		GRP: foreach my $cols ( values %groups ) {
		    @$cols = sort @$cols;
		    # now we are just testing to see if two arrays
		    # are identical w/o changing either one

		    # have to be same len
		    next if( scalar @$cols != scalar @colresidues );
		    # walk down the length and check each slot
		    for($_=0;$_ < (scalar @$cols);$_++ ) {
			next GRP if( $cols->[$_] ne $colresidues[$_] );
		    }
		    $char = $matchchars{$type};
		    last TYPE;
		}
	    }
	  }
	$matchline .= $char;
    }
    return $matchline;
}

#line 1045

sub match {
    my ($self, $match) = @_;

    $match ||= '.';
    my ($matching_char) = $match;
    $matching_char = "\\$match" if $match =~ /[\^.$|()\[\]]/ ;  #'; 
    $self->map_chars($matching_char, '-');

    my @seqs = $self->each_seq();
    return 1 unless scalar @seqs > 1;

    my $refseq = shift @seqs ;
    my @refseq = split //, $refseq->seq;
    my $gapchar = $self->gap_char;

    foreach my $seq ( @seqs ) {
	my @varseq = split //, $seq->seq();
	for ( my $i=0; $i < scalar @varseq; $i++) {
	    $varseq[$i] = $match if defined $refseq[$i] &&
		( $refseq[$i] =~ /[A-Za-z\*]/ ||
		  $refseq[$i] =~ /$gapchar/ )
		      && $refseq[$i] eq $varseq[$i];
	}
	$seq->seq(join '', @varseq);
    }
    $self->match_char($match);
    return 1;
}


#line 1088

sub unmatch {
    my ($self, $match) = @_;

    $match ||= '.';

    my @seqs = $self->each_seq();
    return 1 unless scalar @seqs > 1;

    my $refseq = shift @seqs ;
    my @refseq = split //, $refseq->seq;
    my $gapchar = $self->gap_char;
    foreach my $seq ( @seqs ) {
	my @varseq = split //, $seq->seq();
	for ( my $i=0; $i < scalar @varseq; $i++) {
	    $varseq[$i] = $refseq[$i] if defined $refseq[$i] && 
		( $refseq[$i] =~ /[A-Za-z\*]/ ||
		  $refseq[$i] =~ /$gapchar/ ) &&
		      $varseq[$i] eq $match;
	}
	$seq->seq(join '', @varseq);
    }
    $self->match_char('');
    return 1;
}

#line 1131

sub id {
    my ($self, $name) = @_;

    if (defined( $name )) {
	$self->{'_id'} = $name;
    }

    return $self->{'_id'};
}

#line 1153

sub missing_char {
    my ($self, $char) = @_;

    if (defined $char ) {
	$self->throw("Single missing character, not [$char]!") if CORE::length($char) > 1;
	$self->{'_missing_char'} = $char;
    }

    return $self->{'_missing_char'};
}

#line 1174

sub match_char {
    my ($self, $char) = @_;

    if (defined $char ) {
	$self->throw("Single match character, not [$char]!") if CORE::length($char) > 1;
	$self->{'_match_char'} = $char;
    }

    return $self->{'_match_char'};
}

#line 1195

sub gap_char {
    my ($self, $char) = @_;

    if (defined $char || ! defined $self->{'_gap_char'} ) {
	$char= '-' unless defined $char;
	$self->throw("Single gap character, not [$char]!") if CORE::length($char) > 1;
	$self->{'_gap_char'} = $char;
    }
    return $self->{'_gap_char'};
}

#line 1216

sub symbol_chars{
   my ($self,$includeextra) = @_;
   if( ! defined $self->{'_symbols'} ) {
       $self->warn("Symbol list was not initialized");
       return ();
   }
   my %copy = %{$self->{'_symbols'}};
   if( ! $includeextra ) {
       foreach my $char ( $self->gap_char, $self->match_char,
			  $self->missing_char) {
	   delete $copy{$char} if( defined $char );
       }
   }
   return keys %copy;
}

#line 1251

sub consensus_string {
    my $self = shift;
    my $threshold = shift;
    my $len;
    my ($out,$count);

    $out = "";

    $len = $self->length - 1;

    foreach $count ( 0 .. $len ) {
	$out .= $self->_consensus_aa($count,$threshold);
    }
    return $out;
}

sub _consensus_aa {
    my $self = shift;
    my $point = shift;
    my $threshold_percent = shift || -1 ;
    my ($seq,%hash,$count,$letter,$key);

    foreach $seq ( $self->each_seq() ) {
	$letter = substr($seq->seq,$point,1);
	$self->throw("--$point-----------") if $letter eq '';
	($letter =~ /\./) && next;
	# print "Looking at $letter\n";
	$hash{$letter}++;
    }
    my $number_of_sequences = $self->no_sequences();
    my $threshold = $number_of_sequences * $threshold_percent / 100. ;
    $count = -1;
    $letter = '?';

    foreach $key ( sort keys %hash ) {
	# print "Now at $key $hash{$key}\n";
	if( $hash{$key} > $count && $hash{$key} >= $threshold) {
	    $letter = $key;
	    $count = $hash{$key};
	}
    }
    return $letter;
}


#line 1317

sub consensus_iupac {
    my $self = shift;
    my $out = "";
    my $len = $self->length-1;

    # only DNA and RNA sequences are valid
    foreach my $seq ( $self->each_seq() ) {
	$self->throw("Seq [". $seq->get_nse. "] is a protein")
	    if $seq->alphabet eq 'protein';
    }
    # loop over the alignment columns
    foreach my $count ( 0 .. $len ) {
	$out .= $self->_consensus_iupac($count);
    }
    return $out;
}

sub _consensus_iupac {
    my ($self, $column) = @_;
    my ($string, $char, $rna);

    #determine all residues in a column
    foreach my $seq ( $self->each_seq() ) {
	$string .= substr($seq->seq, $column, 1);
    }
    $string = uc $string;

    # quick exit if there's an N in the string
    if ($string =~ /N/) {	
	$string =~ /\W/ ? return 'n' : return 'N';
    }
    # ... or if there are only gap characters
    return '-' if $string =~ /^\W+$/;

    # treat RNA as DNA in regexps
    if ($string =~ /U/) {	
	$string =~ s/U/T/;
	$rna = 1;
    }

    # the following s///'s only need to be done to the _first_ ambiguity code
    # as we only need to see the _range_ of characters in $string

    if ($string =~ /[VDHB]/) {
	$string =~ s/V/AGC/;
	$string =~ s/D/AGT/;
	$string =~ s/H/ACT/;
	$string =~ s/B/CTG/;
    }

    if ($string =~ /[SKYRWM]/) {
	$string =~ s/S/GC/;
	$string =~ s/K/GT/;
	$string =~ s/Y/CT/;
	$string =~ s/R/AG/;
	$string =~ s/W/AT/;
	$string =~ s/M/AC/;
    }

    # and now the guts of the thing

    if ($string =~ /A/) {
        $char = 'A';                     # A                      A
        if ($string =~ /G/) {
            $char = 'R';                 # A and G (purines)      R
            if ($string =~ /C/) {
                $char = 'V';             # A and G and C          V
                if ($string =~ /T/) {
                    $char = 'N';         # A and G and C and T    N
                }
            } elsif ($string =~ /T/) {
                $char = 'D';             # A and G and T          D
            }
        } elsif ($string =~ /C/) {
            $char = 'M';                 # A and C                M
            if ($string =~ /T/) {
                $char = 'H';             # A and C and T          H
            }
        } elsif ($string =~ /T/) {
            $char = 'W';                 # A and T                W
        }
    } elsif ($string =~ /C/) {
        $char = 'C';                     # C                      C
        if ($string =~ /T/) {
            $char = 'Y';                 # C and T (pyrimidines)  Y
            if ($string =~ /G/) {
                $char = 'B';             # C and T and G          B
            }
        } elsif ($string =~ /G/) {
            $char = 'S';                 # C and G                S
        }
    } elsif ($string =~ /G/) {
        $char = 'G';                     # G                      G
        if ($string =~ /C/) {
            $char = 'S';                 # G and C                S
        } elsif ($string =~ /T/) {
            $char = 'K';                 # G and T                K
        }
    } elsif ($string =~ /T/) {
        $char = 'T';                     # T                      T
    }

    $char = 'U' if $rna and $char eq 'T';
    $char = lc $char if $string =~ /\W/;

    return $char;
}

#line 1440

sub is_flush {
    my ($self,$report) = @_;
    my $seq;
    my $length = (-1);
    my $temp;

    foreach $seq ( $self->each_seq() ) {
	if( $length == (-1) ) {
	    $length = CORE::length($seq->seq());
	    next;
	}

	$temp = CORE::length($seq->seq());
	if( $temp != $length ) {
	    $self->warn("expecting $length not $temp from ".
			$seq->display_id) if( $report );
	    $self->debug("expecting $length not $temp from ".
			 $seq->display_id);
	    $self->debug($seq->seq(). "\n");
	    return 0;
	}
    }

    return 1;
}


#line 1478

sub length_aln {
    my $self = shift;
    $self->warn(ref($self). "::length_aln - deprecated method. Use length() instead.");
    $self->length(@_);
}

sub length {
    my $self = shift;
    my $seq;
    my $length = (-1);
    my ($temp,$len);

    foreach $seq ( $self->each_seq() ) {
	$temp = CORE::length($seq->seq());
	if( $temp > $length ) {
	    $length = $temp;
	}
    }

    return $length;
}


#line 1515

sub maxname_length {
    my $self = shift;
    $self->warn(ref($self). "::maxname_length - deprecated method.".
		" Use maxdisplayname_length() instead.");
    $self->maxdisplayname_length();
}

sub maxnse_length {
    my $self = shift;
    $self->warn(ref($self). "::maxnse_length - deprecated method.".
		" Use maxnse_length() instead.");
    $self->maxdisplayname_length();
}

sub maxdisplayname_length {
    my $self = shift;
    my $maxname = (-1);
    my ($seq,$len);

    foreach $seq ( $self->each_seq() ) {
	$len = CORE::length $self->displayname($seq->get_nse());

	if( $len > $maxname ) {
	    $maxname = $len;
	}
    }

    return $maxname;
}

#line 1555

sub no_residues {
    my $self = shift;
    my $count = 0;

    foreach my $seq ($self->each_seq) {
	my $str = $seq->seq();

	$count += ($str =~ s/[^A-Za-z]//g);
    }

    return $count;
}

#line 1578

sub no_sequences {
    my $self = shift;

    return scalar($self->each_seq);
}


#line 1601

sub average_percentage_identity{
   my ($self,@args) = @_;

   my @alphabet = ('A','B','C','D','E','F','G','H','I','J','K','L','M',
                   'N','O','P','Q','R','S','T','U','V','W','X','Y','Z');

   my ($len, $total, $subtotal, $divisor, $subdivisor, @seqs, @countHashes);

   if (! $self->is_flush()) {
       $self->throw("All sequences in the alignment must be the same length");
   }

   @seqs = $self->each_seq();
   $len = $self->length();

   # load the each hash with correct keys for existence checks

   for( my $index=0; $index < $len; $index++) {
       foreach my $letter (@alphabet) {
	   $countHashes[$index]->{$letter} = 0;
       }
   }
   foreach my $seq (@seqs)  {
       my @seqChars = split //, $seq->seq();
       for( my $column=0; $column < @seqChars; $column++ ) {
	   my $char = uc($seqChars[$column]);
	   if (exists $countHashes[$column]->{$char}) {
	       $countHashes[$column]->{$char}++;
	   }
       }
   }

   $total = 0;
   $divisor = 0;
   for(my $column =0; $column < $len; $column++) {
       my %hash = %{$countHashes[$column]};
       $subdivisor = 0;
       foreach my $res (keys %hash) {
	   $total += $hash{$res}*($hash{$res} - 1);
	   $subdivisor += $hash{$res};
       }
       $divisor += $subdivisor * ($subdivisor - 1);
   }
   return $divisor > 0 ? ($total / $divisor )*100.0 : 0;
}

#line 1658

sub percentage_identity {
    my $self = shift;
    return $self->average_percentage_identity();
}

#line 1674

sub overall_percentage_identity{
   my ($self,@args) = @_;

   my @alphabet = ('A','B','C','D','E','F','G','H','I','J','K','L','M',
                   'N','O','P','Q','R','S','T','U','V','W','X','Y','Z');

   my ($len, $total, @seqs, @countHashes);

   if (! $self->is_flush()) {
       $self->throw("All sequences in the alignment must be the same length");
   }

   @seqs = $self->each_seq();
   $len = $self->length();

   # load the each hash with correct keys for existence checks
   for( my $index=0; $index < $len; $index++) {
       foreach my $letter (@alphabet) {
	   $countHashes[$index]->{$letter} = 0;
       }
   }
   foreach my $seq (@seqs)  {
       my @seqChars = split //, $seq->seq();
       for( my $column=0; $column < @seqChars; $column++ ) {
	   my $char = uc($seqChars[$column]);
	   if (exists $countHashes[$column]->{$char}) {
	       $countHashes[$column]->{$char}++;
	   }
       }
   }

   $total = 0;
   for(my $column =0; $column < $len; $column++) {
       my %hash = %{$countHashes[$column]};
       foreach ( values %hash ) {
	   next if( $_ == 0 );
	   $total++ if( $_ == scalar @seqs );
	   last;
       }
   }
   return ($total / $len ) * 100.0;
}

#line 1765

sub column_from_residue_number {
    my ($self, $name, $resnumber) = @_;

    $self->throw("No sequence with name [$name]") unless $self->{'_start_end_lists'}->{$name};
    $self->throw("Second argument residue number missing") unless $resnumber;

    foreach my $seq ($self->each_seq_with_id($name)) {
	my $col;
	eval {
	    $col = $seq->column_from_residue_number($resnumber);
	};
	next if $@;		
	return $col;
    }

    $self->throw("Could not find a sequence segment in $name ".
		 "containing residue number $resnumber");

}

#line 1803

sub get_displayname {
    my $self = shift;
    $self->warn(ref($self). "::get_displayname - deprecated method. Use displayname() instead.");
    $self->displayname(@_);
}

sub set_displayname {
    my $self = shift;
    $self->warn(ref($self). "::set_displayname - deprecated method. Use displayname() instead.");
    $self->displayname(@_);
}

sub displayname {
    my ($self, $name, $disname) = @_;

    $self->throw("No sequence with name [$name]") unless $self->{'_seq'}->{$name};

    if(  $disname and  $name) {
	$self->{'_dis_name'}->{$name} = $disname;
	return $disname;
    }
    elsif( defined $self->{'_dis_name'}->{$name} ) {
	return  $self->{'_dis_name'}->{$name};
    } else {
	return $name;
    }
}

#line 1845

sub set_displayname_count {
    my $self= shift;
    my (@arr,$name,$seq,$count,$temp,$nse);

    foreach $seq ( $self->each_alphabetically() ) {
	$nse = $seq->get_nse();

	#name will be set when this is the second
	#time (or greater) is has been seen

	if( defined $name and $name eq ($seq->id()) ) {
	    $temp = sprintf("%s_%s",$name,$count);
	    $self->displayname($nse,$temp);
	    $count++;
	} else {
	    $count = 1;
	    $name = $seq->id();
	    $temp = sprintf("%s_%s",$name,$count);
	    $self->displayname($nse,$temp);
	    $count++;
	}
    }
    return 1;
}

#line 1881

sub set_displayname_flat {
    my $self = shift;
    my ($nse,$seq);

    foreach $seq ( $self->each_seq() ) {
	$nse = $seq->get_nse();
	$self->displayname($nse,$seq->id());
    }
    return 1;
}

#line 1902

sub set_displayname_normal {
    my $self = shift;
    my ($nse,$seq);

    foreach $seq ( $self->each_seq() ) {
	$nse = $seq->get_nse();
	$self->displayname($nse,$nse);
    }
    return 1;
}

#line 1925

sub source{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'_source'} = $value;
    }
    return $self->{'_source'};
}

1;
