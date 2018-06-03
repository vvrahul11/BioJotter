#line 1 "Bio/SearchIO/exonerate.pm"
# $Id: exonerate.pm,v 1.3.2.3 2003/03/29 20:30:54 jason Exp $
#
# BioPerl module for Bio::SearchIO::exonerate
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 80


# Let the code begin...


package Bio::SearchIO::exonerate;
use strict;
use vars qw(@ISA @STATES %MAPPING %MODEMAP $DEFAULT_WRITER_CLASS $MIN_INTRON);
use Bio::SearchIO;

@ISA = qw(Bio::SearchIO );

use POSIX;


%MODEMAP = ('ExonerateOutput' => 'result',
    'Hit'             => 'hit',
    'Hsp'             => 'hsp'
    );
%MAPPING =
    (
    'Hsp_query-from'=>  'HSP-query_start',
    'Hsp_query-to'  =>  'HSP-query_end',
    'Hsp_hit-from'  =>  'HSP-hit_start',
    'Hsp_hit-to'    =>  'HSP-hit_end',
    'Hsp_qseq'      =>  'HSP-query_seq',
    'Hsp_hseq'      =>  'HSP-hit_seq',
    'Hsp_midline'   =>  'HSP-homology_seq',
    'Hsp_score'     =>  'HSP-score',
    'Hsp_qlength'   =>  'HSP-query_length',
    'Hsp_hlength'   =>  'HSP-hit_length',
    'Hsp_align-len' =>  'HSP-hsp_length',
    'Hsp_identity'  =>  'HSP-identical',
    'Hsp_gaps'       => 'HSP-hsp_gaps',
    'Hsp_hitgaps'    => 'HSP-hit_gaps',
    'Hsp_querygaps'  => 'HSP-query_gaps',

    'Hit_id'        => 'HIT-name',
    'Hit_desc'      => 'HIT-description',
    'Hit_len'       => 'HIT-length',
    'Hit_score'     => 'HIT-score',

    'ExonerateOutput_program'   => 'RESULT-algorithm_name',
    'ExonerateOutput_query-def' => 'RESULT-query_name',
    'ExonerateOutput_query-desc'=> 'RESULT-query_description',
    'ExonerateOutput_query-len' => 'RESULT-query_length',
    );

$DEFAULT_WRITER_CLASS = 'Bio::Search::Writer::HitTableWriter';

$MIN_INTRON=30; # This is the minimum intron size

#line 142

sub new {
    my ($class) = shift;
    my $self = $class->SUPER::new(@_);

    my ($min_intron) = $self->_rearrange([qw(MIN_INTRON)], @_);
    if( $min_intron ) {
	$MIN_INTRON = $min_intron;
    }
    $self;
}

#line 163

sub next_result{
   my ($self) = @_;
   $self->{'_last_data'} = '';
   my ($reporttype,$seenquery,$reportline);
   $self->start_document();
   my @hit_signifs;
   my $seentop;
   my (@q_ex, @m_ex, @h_ex); ## gc addition
   while( defined($_ = $self->_readline) ) {
       if( /^Query:\s+(\S+)(\s+(.+))?/ ) {
	   if( $seentop ) {
	       $self->end_element({'Name' => 'ExonerateOutput'});
	       $self->_pushback($_);
	       return $self->end_document();
	   }
	   $seentop = 1;
	   my ($nm,$desc) = ($1,$2);
	   chomp($desc) if defined $desc;
	   $self->{'_result_count'}++;
	   $self->start_element({'Name' => 'ExonerateOutput'});
	   $self->element({'Name' => 'ExonerateOutput_query-def',
			   'Data' => $nm });
	   $self->element({'Name' => 'ExonerateOutput_query-desc',
			   'Data' => $desc });
	   $self->element({'Name' => 'ExonerateOutput_program',
			    'Data' => 'Exonerate' });

       } elsif ( /^Target:\s+(\S+)(\s+(.+))?/ ) {
	    my ($nm,$desc) = ($1,$2);
	   chomp($desc) if defined $desc;
	   $self->start_element({'Name' => 'Hit'});
	   $self->element({'Name' => 'Hit_id',
			   'Data' => $nm});
	   $self->element({'Name' => 'Hit_desc',
			   'Data' => $desc});
       } elsif(  s/^cigar:\s+(\S+)\s+          # query sequence id
		 (\d+)\s+(\d+)\s+([\-\+])\s+   # query start-end-strand
		 (\S+)\s+                      # target sequence id
		 (\d+)\s+(\d+)\s+([\-\+])\s+   # target start-end-strand
		 (\d+)\s+                      # score
		 //ox ) {
	
	   ## gc note:
	   ## $qe and $he are no longer used for calculating the ends,
	   ## just the $qs and $hs values and the alignment and insert lenghts
	   my ($qs,$qe,$qstrand) = ($2,$3,$4);
	   my ($hs,$he,$hstrand) = ($6,$7,$8);
	   my $score = $9;
#	   $self->element({'Name' => 'ExonerateOutput_query-len',
#			   'Data' => $qe});
#	   $self->element({'Name' => 'Hit_len',
#			   'Data' => $he});
	
	   my @rest = split;
	   if( $qstrand eq '-' ) {
	       $qstrand = -1;
	       ($qs,$qe) = ($qe,$qs); # flip-flop if we're on opp strand
	   		$qs--; $qe++;
	   } else { $qstrand = 1; }
	   if( $hstrand eq '-' ) {
	       $hstrand = -1;
	       ($hs,$he) = ($he,$hs); # flip-flop if we're on opp strand
	       $hs--; $he++;
	   } else { $hstrand = 1; }
	   # okay let's do this right and generate a set of HSPs
	   # from the cigar line

		## gc note:
		## add one because these values are zero-based
		## this calculation was originally done lower in the code,
		## but it's clearer to do it just once at the start
	   $qs++;
	   $hs++;

	   my ($aln_len,$inserts,$deletes) = (0,0,0);
	   while( @rest >= 2 ) {
	       my ($state,$len) = (shift @rest, shift @rest);
	       if( $state eq 'I' ) {
		   $inserts+=$len;
	       } elsif( $state eq 'D' ) {
		   if( $len >= $MIN_INTRON ) {
		       $self->start_element({'Name' => 'Hsp'});

		       $self->element({'Name' => 'Hsp_score',
				       'Data' => $score});
		       $self->element({'Name' => 'Hsp_align-len',
				       'Data' => $aln_len});
		       $self->element({'Name' => 'Hsp_identity',
				       'Data' => $aln_len -
					   ($inserts + $deletes)});
		
		       # HSP ends where the other begins
		       $self->element({'Name' => 'Hsp_query-from',
				       'Data' => $qs});
		       ## gc note:
		       ## $qs is now the start of the next hsp
		       ## the end of this hsp is 1 before this position
		       ## (or 1 after in case of reverse strand)
		       $qs += $aln_len*$qstrand;
		       $self->element({'Name' => 'Hsp_query-to',
				       'Data' => $qs - ($qstrand*1)});
		
		       $hs += $deletes*$hstrand;
		       $self->element({'Name' => 'Hsp_hit-from',
				       'Data' => $hs});
		       $hs += $aln_len*$hstrand;
		       $self->element({'Name' => 'Hsp_hit-to',
				       'Data' => $hs-($hstrand*1)});
		
		       $self->element({'Name' => 'Hsp_align-len',
				       'Data' => $aln_len + $inserts
					   + $deletes});
		       $self->element({'Name' => 'Hsp_identity',
				       'Data' => $aln_len });

		       $self->element({'Name' => 'Hsp_gaps',
				       'Data' => $inserts + $deletes});
		       $self->element({'Name' => 'Hsp_querygaps',
				       'Data' => $inserts});
		       $self->element({'Name' => 'Hsp_hitgaps',
				       'Data' => $deletes});
		
## gc addition start
		
		       $self->element({'Name' => 'Hsp_qseq',
				       'Data' => shift @q_ex,
				   });
		       $self->element({'Name' => 'Hsp_hseq',
				       'Data' => shift @h_ex,
				   });
		       $self->element({'Name' => 'Hsp_midline',
				       'Data' => shift @m_ex,
				   });
## gc addition end
		       $self->end_element({'Name' => 'Hsp'});
		       		
		       $aln_len = $inserts = $deletes = 0;
		   }
		   $deletes+=$len;		
	       } else {
		   $aln_len += $len;
	       }
	   }
	   $self->start_element({'Name' => 'Hsp'});
	
## gc addition start
		
		       $self->element({'Name' => 'Hsp_qseq',
				       'Data' => shift @q_ex,
				   });
		       $self->element({'Name' => 'Hsp_hseq',
				       'Data' => shift @h_ex,
				   });
		       $self->element({'Name' => 'Hsp_midline',
				       'Data' => shift @m_ex,
				   });
## gc addition end

	   $self->element({'Name' => 'Hsp_score',
			   'Data' => $score});
	
	   $self->element({'Name' => 'Hsp_query-from',
			   'Data' => $qs});

	   $qs += $aln_len*$qstrand;
	   $self->element({'Name' => 'Hsp_query-to',
				       'Data' => $qs - ($qstrand*1)});

	   $hs += $deletes*$hstrand;
	   $self->element({'Name' => 'Hsp_hit-from',
			   'Data' => $hs});
	   $hs += $aln_len*$hstrand;
	   $self->element({'Name' => 'Hsp_hit-to',
			   'Data' => $hs -($hstrand*1)});	

	   $self->element({'Name' => 'Hsp_align-len',
			   'Data' => $aln_len});
	
	   $self->element({'Name' => 'Hsp_identity',
			   'Data' => $aln_len - ($inserts + $deletes)});

	   $self->element({'Name' => 'Hsp_gaps',
			   'Data' => $inserts + $deletes});
	
	   $self->element({'Name' => 'Hsp_querygaps',
			   'Data' => $inserts});
	   $self->element({'Name' => 'Hsp_hitgaps',
			   'Data' => $deletes});	   	
	   $self->end_element({'Name' => 'Hsp'});
	   $self->element({'Name' => 'Hit_score',
			   'Data' => $score});
	   $self->end_element({'Name' => 'Hit'});
	   $self->end_element({'Name' => 'ExonerateOutput'});

	   return $self->end_document();	
       } else {
       }
   }
   return $self->end_document() if( $seentop );
}

#line 375

sub start_element{
   my ($self,$data) = @_;
   # we currently don't care about attributes
   my $nm = $data->{'Name'};
   my $type = $MODEMAP{$nm};

   if( $type ) {
       if( $self->_eventHandler->will_handle($type) ) {
	   my $func = sprintf("start_%s",lc $type);
	   $self->_eventHandler->$func($data->{'Attributes'});
       }
       unshift @{$self->{'_elements'}}, $type;

       if($type eq 'result') {
	   $self->{'_values'} = {};
	   $self->{'_result'}= undef;
       }
   }

}

#line 407

sub end_element {
    my ($self,$data) = @_;
    my $nm = $data->{'Name'};
    my $type = $MODEMAP{$nm};
    my $rc;

    if( $type = $MODEMAP{$nm} ) {
	if( $self->_eventHandler->will_handle($type) ) {
	    my $func = sprintf("end_%s",lc $type);
	    $rc = $self->_eventHandler->$func($self->{'_reporttype'},
					      $self->{'_values'});
	}
	shift @{$self->{'_elements'}};

    } elsif( $MAPPING{$nm} ) {

	if ( ref($MAPPING{$nm}) =~ /hash/i ) {
	    my $key = (keys %{$MAPPING{$nm}})[0];
	    $self->{'_values'}->{$key}->{$MAPPING{$nm}->{$key}} = $self->{'_last_data'};
	} else {
	    $self->{'_values'}->{$MAPPING{$nm}} = $self->{'_last_data'};
	}
    } else {
	$self->debug( "unknown nm $nm, ignoring\n");
    }
    $self->{'_last_data'} = ''; # remove read data if we are at
				# end of an element
    $self->{'_result'} = $rc if( defined $type && $type eq 'result' );
    return $rc;
}

#line 449

sub element{
   my ($self,$data) = @_;
   $self->start_element($data);
   $self->characters($data);
   $self->end_element($data);
}

#line 467

sub characters{
   my ($self,$data) = @_;

   return unless ( defined $data->{'Data'} && $data->{'Data'} !~ /^\s+$/ );

   $self->{'_last_data'} = $data->{'Data'};
}

#line 488

sub within_element{
   my ($self,$name) = @_;
   return 0 if ( ! defined $name &&
		 ! defined  $self->{'_elements'} ||
		 scalar @{$self->{'_elements'}} == 0) ;
   foreach (  @{$self->{'_elements'}} ) {
       if( $_ eq $name  ) {
	   return 1;
       }
   }
   return 0;
}


#line 515

sub in_element{
   my ($self,$name) = @_;
   return 0 if ! defined $self->{'_elements'}->[0];
   return ( $self->{'_elements'}->[0] eq $name)
}

#line 532

sub start_document{
    my ($self) = @_;
    $self->{'_lasttype'} = '';
    $self->{'_values'} = {};
    $self->{'_result'}= undef;
    $self->{'_elements'} = [];
    $self->{'_reporttype'} = 'exonerate';
}


#line 553

sub end_document{
   my ($self,@args) = @_;
   return $self->{'_result'};
}


sub write_result {
   my ($self, $blast, @args) = @_;

   if( not defined($self->writer) ) {
       $self->warn("Writer not defined. Using a $DEFAULT_WRITER_CLASS");
       $self->writer( $DEFAULT_WRITER_CLASS->new() );
   }
   $self->SUPER::write_result( $blast, @args );
}

sub result_count {
    my $self = shift;
    return $self->{'_result_count'};
}

sub report_count { shift->result_count }

1;

