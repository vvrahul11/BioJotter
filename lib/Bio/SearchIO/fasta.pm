#line 1 "Bio/SearchIO/fasta.pm"
# $Id: fasta.pm,v 1.33.2.3 2003/08/28 16:01:03 jason Exp $
#
# BioPerl module for Bio::SearchIO::fasta
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 67


# Let the code begin...


package Bio::SearchIO::fasta;
use vars qw(@ISA %MODEMAP %MAPPING $IDLENGTH);
use strict;

# Object preamble - inherits from Bio::Root::RootI

use Bio::SearchIO;
use POSIX;

BEGIN { 
    # Set IDLENGTH to a new value if you have
    # compile FASTA with a different ID length
    # (actually newest FASTA allows the setting of this
    #  via -C parameter, default is 6)
    $IDLENGTH = 6;

    # mapping of NCBI Blast terms to Bioperl hash keys
    %MODEMAP = ('FastaOutput' => 'result',
		'Hit'         => 'hit',
		'Hsp'         => 'hsp'
		);

    # This should really be done more intelligently, like with
    # XSLT

    %MAPPING = 
	( 
	  'Hsp_bit-score' => 'HSP-bits',
	  'Hsp_score'     => 'HSP-score',
	  'Hsp_sw-score'  => 'HSP-swscore',
	  'Hsp_evalue'    => 'HSP-evalue',
	  'Hsp_query-from'=> 'HSP-query_start',
	  'Hsp_query-to'  => 'HSP-query_end',
	  'Hsp_hit-from'  => 'HSP-hit_start',
	  'Hsp_hit-to'    => 'HSP-hit_end',
	  'Hsp_positive'  => 'HSP-conserved',
	  'Hsp_identity'  => 'HSP-identical',
	  'Hsp_gaps'      => 'HSP-hsp_gaps',
	  'Hsp_hitgaps'   => 'HSP-hit_gaps',
	  'Hsp_querygaps' => 'HSP-query_gaps',
	  'Hsp_qseq'      => 'HSP-query_seq',
	  'Hsp_hseq'      =>  'HSP-hit_seq',
	  'Hsp_midline'   =>  'HSP-homology_seq',
	  'Hsp_align-len' =>  'HSP-hsp_length',
	  'Hsp_query-frame'=> 'HSP-query_frame',
	  'Hsp_hit-frame'  => 'HSP-hit_frame',

	  'Hit_id'        => 'HIT-name',
	  'Hit_len'       => 'HIT-length',
	  'Hit_accession' => 'HIT-accession',
	  'Hit_def'       => 'HIT-description',
	  'Hit_signif'    => 'HIT-significance',
	  'Hit_score'     => 'HIT-score',

	  'FastaOutput_program'  => 'RESULT-algorithm_name',
	  'FastaOutput_version'  => 'RESULT-algorithm_version',
	  'FastaOutput_query-def'=> 'RESULT-query_name',
	  'FastaOutput_querydesc'=> 'RESULT-query_description',
	  'FastaOutput_query-len'=> 'RESULT-query_length',
	  'FastaOutput_db'       => 'RESULT-database_name',
	  'FastaOutput_db-len'   => 'RESULT-database_entries',
	  'FastaOutput_db-let'   => 'RESULT-database_letters',

	  'Parameters_matrix'    => { 'RESULT-parameters' => 'matrix'},
	  'Parameters_expect'    => { 'RESULT-parameters' => 'expect'},
	  'Parameters_include'   => { 'RESULT-parameters' => 'include'},
	  'Parameters_sc-match'  => { 'RESULT-parameters' => 'match'},
	  'Parameters_sc-mismatch' => { 'RESULT-parameters' => 'mismatch'},
	  'Parameters_gap-open'  => { 'RESULT-parameters' => 'gapopen'},
	  'Parameters_gap-ext'   => { 'RESULT-parameters' => 'gapext'},
	  'Parameters_word-size' => { 'RESULT-parameters' => 'wordsize'},
	  'Parameters_ktup'      => { 'RESULT-parameters' => 'ktup'},
	  'Parameters_filter'    => {'RESULT-parameters' => 'filter'},
	  'Statistics_db-num'    => { 'RESULT-statistics' => 'dbentries'},
	  'Statistics_db-len'    => { 'RESULT-statistics' => 'dbletters'},
	  'Statistics_hsp-len'   => { 'RESULT-statistics' => 'hsplength'},
	  'Statistics_eff-space' => { 'RESULT-statistics' => 'effectivespace'},
	  'Statistics_kappa'     => { 'RESULT-statistics' => 'kappa' },
	  'Statistics_lambda'    => { 'RESULT-statistics' => 'lambda' },
	  'Statistics_entropy'   => { 'RESULT-statistics' => 'entropy'},
	  );
}


@ISA = qw(Bio::SearchIO );

#line 171

sub _initialize {
  my($self,@args) = @_;
  $self->SUPER::_initialize(@args);
  return unless @args;
  my ($idlength) = $self->_rearrange([qw(IDLENGTH)],@args);
  $self->idlength($idlength || $IDLENGTH);
  $self->_eventHandler->register_factory('hsp', Bio::Search::HSP::HSPFactory->new(-type => 'Bio::Search::HSP::FastaHSP'));

  return 1;
}

#line 192

sub next_result{
   my ($self) = @_;

   my $data = '';
   my $seentop = 0;
   my $current_hsp;
   $self->start_document();
   my @hit_signifs;
   while( defined ($_ = $self->_readline )) {
       next if( ! $self->in_element('hsp')  &&
		/^\s+$/); # skip empty lines
       if( /(\S+)\s+searches\s+a\s+((protein\s+or\s+DNA\s+sequence)|(sequence\s+database))/i || /(\S+) compares a/ ||
	   ( m/^# / && ($_ = $self->_readline) &&
	     /(\S+)\s+searches\s+a\s+((protein\s+or\s+DNA\s+sequence)|(sequence\s+database))/i || /(\S+) compares a/
	   )
	 ) {
	   if( $seentop ) {
	       $self->_pushback($_);
	       $self->end_element({ 'Name' => 'FastaOutput'});
	       return $self->end_document();
	   }
	   $self->{'_reporttype'} = $1;
	   $self->start_element({ 'Name' => 'FastaOutput' } );
	   $self->{'_result_count'}++;
	   $seentop = 1;
	   
	   $self->element({ 'Name' => 'FastaOutput_program',
			    'Data' => $self->{'_reporttype'}});
	   $_ = $self->_readline();
	   my ($version) = (/version\s+(\S+)/);
	   $version = '' unless defined $version;
	   $self->{'_version'} = $version;
	   $self->element({ 'Name' => 'FastaOutput_version',
			    'Data' => $version});

	   my ($last, $leadin, $type, $querylen, $querytype, $querydef);

	   while( defined($_ = $self->_readline()) ) {
	       if( /^ (
                       (?:\s+>) |             # fa33 lead-in
                       (?:\s*\d+\s*>>>)       # fa34 mlib lead-in
                      )
                      (.*)
                   /x
		 ) {
		   ($leadin, $querydef) = ($1, $2);
		   if ($leadin =~ m/>>>/) {
		       if($querydef =~ /^(.*?)\s+(?:\-\s+)?(\d+)\s+(aa|nt)\s*$/o ) {
			   ($querydef, $querylen, $querytype) = ($1, $2, $3);
			   last;
		       }
		   } else {
		       if( $last =~ /(\S+)[:,]\s*(\d+)\s+(aa|nt)/ ) {
			   ($querylen, $querytype) = ($2, $3);
			   $querydef ||= $1;
			   last;
		       }
		   }
	       } elsif ( m/^\s*vs\s+\S+/o ) {
		   if ( $last =~ /(\S+)[,:]\s+(\d+)\s+(aa|nt)/o) {
		       ($querydef, $querylen, $querytype) = ($1, $2, $3);
		       last;
		   }
	       }
	       $last = $_;
	   }
	   
	   if( $self->{'_reporttype'} &&
	       $self->{'_reporttype'} eq 'FASTA'
	       ) {
	       if( $querytype eq 'nt') {
		   $self->{'_reporttype'} = 'FASTN' ;
	       } elsif( $querytype eq 'aa' ) {
		   $self->{'_reporttype'} = 'FASTP' ;
	       }
	   }
	   my ($name, $descr) = $querydef =~ m/^(\S+)\s*(.*?)\s*$/o;
	   $self->element({'Name' => 'FastaOutput_query-def',
			   'Data' => $name});
	   $self->element({'Name' => 'FastaOutput_querydesc',
			   'Data' => $descr});
	   if ($querylen) {
	       $self->element({'Name' => 'FastaOutput_query-len',
			       'Data' => $querylen});
	   } else {
	       $self->warn("unable to find and set query length");
	   }

	   if( $last =~ /^\s*vs\s+(\S+)/ ||	       	       
	       ($last =~ /^searching\s+(\S+)\s+library/)  ||
	       (defined $_ && /^\s*vs\s+(\S+)/) ||
	       (defined ($_ = $self->_readline()) && /^\s*vs\s+(\S+)/)
	     ) {
	       $self->element({'Name' => 'FastaOutput_db',
                           'Data' => $1});
	   } elsif (m/^\s+opt(?:\s+E\(\))?$/o) {
	       # histogram ... read over it more rapidly than the larger outer loop:
	       while (defined($_ = $self->_readline)) {
		   last if m/^>\d+/;
	       }
	   }

       } elsif( /(\d+) residues in\s+(\d+)\s+sequences/ ) {
	   $self->element({'Name' => 'FastaOutput_db-let',
			   'Data' => $1});
	   $self->element({'Name' => 'FastaOutput_db-len',
			   'Data' => $2});
	   $self->element({'Name' => 'Statistics_db-len',
			   'Data' => $1});
	   $self->element({'Name' => 'Statistics_db-num',
			   'Data' => $2});	   
       } elsif( /Lambda=\s*(\S+)/ ) {
	   $self->element({'Name' => 'Statistics_lambda',
			   'Data' => $1});	  
       } elsif (/K=\s*(\S+)/) {
	   $self->element({'Name' => 'Statistics_kappa',
			   'Data' => $1});
       } elsif( /^\s*(Smith-Waterman).+(\S+)\s*matrix [^\]]*?(xS)?\]/ ) {	   
	   $self->element({'Name' => 'Parameters_matrix',
			   'Data' => $2});
	   $self->element({'Name' => 'Parameters_filter',
			   'Data' => defined $3 ? 1 : 0,
			  });
	   $self->{'_reporttype'} = $1;

	   $self->element({ 'Name' => 'FastaOutput_program',
			    'Data' => $self->{'_reporttype'}});
	   
       } elsif( /The best( related| unrelated)? scores are:/ ) {
	   my $rel = $1;
	   my @labels = split;
	   @labels = map {
	       if ($_ =~ m/^E\((\d+)\)$/o) {
		   $self->element({'Name' => 'Statistics_eff-space', 'Data' => $1});
		   "evalue";
	       } else {
		   $_;
	       }
	   } @labels[$rel ? 5 : 4 .. $#labels];

	   while( defined ($_ = $self->_readline() ) && 
		  ! /^\s+$/ ) {
	       my @line = split;

	       if ($line[-1] =~ m/\=/o && $labels[-1] eq 'fs') {
		   # unlabelled alignment hit;
		   push @labels, "aln_code";
	       }

	       my %data;
	       @data{@labels} = splice(@line, @line - @labels);
	       if ($line[-1] =~ m/\[([1-6rf])\]/o) {
               my $fr = $1;
               $data{lframe} = ($fr =~ /\d/o ?
                                ($fr <= 3   ? "+$fr" : "-@{[$fr-3]}") :
                                ($fr eq 'f' ? '+1'  : '-1')
                               );
               pop @line;
	       } else {
               $data{lframe} = '0';
	       }

	       if ($line[-1] =~ m/^\(?(\d+)\)$/) {
		   $data{hit_len} = $1;
		   pop @line;
		   if ($line[-1] =~ m/^\($/) {
		       pop @line;
		   }
	       } else {
		   $data{hit_len} = 0;
	       }

	       # rebuild the first part of the line, preserving spaces:
	       ($_) = m/^(\S+(?:\s+\S+){$#line})/;

	       my ($id, $desc) = split(/\s+/,$_,2);
	       my @pieces = split(/\|/,$id);
	       my $acc = pop @pieces;
	       $acc =~ s/\.\d+$//;

	       @data{qw(id desc acc)} = ($id, $desc, $acc);

	       push @hit_signifs, \%data;
	   }
       } elsif( /^\s*([T]?FAST[XYAF]).+,\s*(\S+)\s*matrix[^\]]+?(xS)?\]\s*ktup:\s*(\d+)/ ) {
	   $self->element({'Name' => 'Parameters_matrix',
			   'Data' => $2});
	   $self->element({'Name' => 'Parameters_filter',
			   'Data' => defined $3 ? 1 : 0,
			  });
	   $self->element({'Name' => 'Parameters_ktup',
			   'Data' => $4});
	   $self->{'_reporttype'} = $1 if( $self->{'_reporttype'} !~ /FAST[PN]/i ) ;

	   $self->element({ 'Name' => 'FastaOutput_program',
			    'Data' => $self->{'_reporttype'}});
	   
       } elsif( /(?:gap\-pen|open\/ext):\s+([\-\+]?\d+)\s*\/\s*([\-\+]?\d+).+width:\s+(\d+)/ ) {
	   $self->element({'Name' => 'Parameters_gap-open',
			   'Data' => $1});
	   $self->element({'Name' => 'Parameters_gap-ext',
			   'Data' => $2});
	   $self->element({'Name' => 'Parameters_word-size',
			   'Data' => $3});
       } elsif( /^>>(.+?)\s+\((\d+)\s*(aa|nt)\)$/ ) {
	   if( $self->in_element('hsp') ) {
	       $self->end_element({ 'Name' => 'Hsp'});
	   }
	   if( $self->in_element('hit') ) {
	       $self->end_element({ 'Name' => 'Hit'});
	   }
	   
	   $self->start_element({'Name' => 'Hit'});
	   $self->element({ 'Name' => 'Hit_len',
			    'Data' => $2});  
	   my ($id,$desc) = split(/\s+/,$1,2);
	   $self->element({ 'Name' => 'Hit_id',
			    'Data' => $id}); 	   
	   my @pieces = split(/\|/,$id);
	   my $acc = pop @pieces;
	   $acc =~ s/\.\d+$//;
	   $self->element({ 'Name' =>  'Hit_accession',
			    'Data'  => $acc});	
	   $self->element({ 'Name' => 'Hit_def',
			    'Data' => $desc});	   

	   $_ = $self->_readline();
	   my ($score,$bits,$e) = /Z-score: \s* (\S+) \s*
                               (?: bits: \s* (\S+) \s+ )?
                               (?: E|expect ) \s* \(\) :? \s*(\S+)/x;
	   $bits = $score unless defined $bits;

	   my $v = shift @hit_signifs;
	   if( defined $v ) {
	       @{$v}{qw(evalue bits z-sc)} = ($e, $bits, $score);
	   }

	   $self->element({'Name' => 'Hit_signif',
			   'Data' => $v ? $v->{evalue} : $e });
	   $self->element({'Name' => 'Hit_score',
			   'Data' => $v ? $v->{bits} : $bits });
	   $self->start_element({'Name' => 'Hsp'});

	   $self->element({'Name' => 'Hsp_score',
			   'Data' => $v ? $v->{'z-sc'} : $score });
	   $self->element({'Name' => 'Hsp_evalue',
			   'Data' => $v ? $v->{evalue} : $e });
	   $self->element({'Name' => 'Hsp_bit-score',
			   'Data' => $v ? $v->{bits} : $bits });
	   $_ = $self->_readline();
	   if( /Smith-Waterman score:\s*(\d+)/ ) {
	       $self->element({'Name' => 'Hsp_sw-score',
			       'Data' => $1});
	   }
	   if( / (\S+)\% \s* identity
                 (?:\s* \( \s* (\S+)\% \s* ungapped \) )?
                 \s* in \s* (\d+) \s+ (?:aa|nt) \s+ overlap \s*
                 \( (\d+) \- (\d+) : (\d+) \- (\d+) \)
               /x ) {
	       my ($identper,$gapper,$len,$querystart,
		   $queryend,$hitstart,$hitend) = ($1,$2,$3,$4,$5,$6,$7);
	       my $ident = POSIX::ceil(($identper/100) * $len);
	       my $gaps = ( defined $gapper ) ? POSIX::ceil ( ($gapper/100) * $len) : undef;
	       
	       $self->element({'Name' => 'Hsp_gaps',
			       'Data' => $gaps});
	       $self->element({'Name' => 'Hsp_identity',
			       'Data' => $ident});
	       $self->element({'Name' => 'Hsp_positive',
			       'Data' => $ident});
	       $self->element({'Name' => 'Hsp_align-len',
			       'Data' => $len});
	       
	       $self->element({'Name' => 'Hsp_query-from',
			       'Data' => $querystart});
	       $self->element({'Name' => 'Hsp_query-to',
			       'Data' => $queryend});
	       $self->element({'Name' => 'Hsp_hit-from',
			       'Data' => $hitstart});
	       $self->element({'Name' => 'Hsp_hit-to',
			       'Data' => $hitend});
	       
	       }

	   if ($v) {
	       $self->element({'Name' => 'Hsp_querygaps', 'Data' => $v->{qgaps} }) if exists $v->{qgaps};
	       $self->element({'Name' => 'Hsp_hitgaps', 'Data' => $v->{lgaps} }) if exists $v->{lgaps};

	       if ($self->{'_reporttype'} =~ m/^FAST[NXY]$/o) {
		   if( 8 == scalar grep { exists $v->{$_} } qw(an0 ax0 pn0 px0 an1 ax1 pn1 px1) ) {
		       if ($v->{ax0} < $v->{an0}) {
			   $self->element({'Name' => 'Hsp_query-frame', 'Data' => "-@{[(($v->{px0} - $v->{ax0}) % 3) + 1]}" });
		       } else {
			   $self->element({'Name' => 'Hsp_query-frame', 'Data' => "+@{[(($v->{an0} - $v->{pn0}) % 3) + 1]}" });
		       }
		       if ($v->{ax1} < $v->{an1}) {
			   $self->element({'Name' => 'Hsp_hit-frame', 'Data' => "-@{[(($v->{px1} - $v->{ax1}) % 3) + 1]}" });
		       } else {
			   $self->element({'Name' => 'Hsp_hit-frame', 'Data' => "+@{[(($v->{an1} - $v->{pn1}) % 3) + 1]}" });
		       }
		   } else {
		       $self->element({'Name' => 'Hsp_query-frame', 'Data' => $v->{lframe} });
		       $self->element({'Name' => 'Hsp_hit-frame', 'Data' => 0 });
		   }
	       } else {
		   $self->element({'Name' => 'Hsp_query-frame', 'Data' => 0 });
		   $self->element({'Name' => 'Hsp_hit-frame', 'Data' => $v->{lframe} });
	       }

	   } else {
	       $self->warn( "unable to parse FASTA score line: $_");
	   }
       } elsif( /\d+\s*residues\s*in\s*\d+\s*query\s*sequences/ ) {
	   if( $self->in_element('hsp') ) {
	       $self->end_element({'Name' => 'Hsp'});
	   } 
	   if( $self->in_element('hit') ) {
	       $self->end_element({'Name' => 'Hit'});
	   }
	   
#	   $_ = $self->_readline();
#	   my ( $liblen,$libsize) = /(\d+)\s+residues\s*in(\d+)\s*library/;
	   # fast forward to the end of the file as there is 
	   # nothing else left to do with this file and want to be sure and
	   # reset it
	   while(defined($_ = $self->_readline() ) ) { 
	       last if( /^Function used was/);
	       if( /(\S+)\s+searches\s+a\s+(protein\s+or\s+DNA\s+sequence)|(sequence\s+database)/ ) { 
		   $self->_pushback($_);
	       }
	   }

           if (@hit_signifs) {
	       # process remaining best hits
	       for my $h (@hit_signifs) {
		   #  Hsp_score Hsp_evalue Hsp_bit-score
		   # Hsp_sw-score Hsp_gaps Hsp_identity Hsp_positive
		   # Hsp_align-len Hsp_query-from Hsp_query-to
		   # Hsp_hit-from Hsp_hit-to Hsp_qseq Hsp_midline

		   $self->start_element({'Name' => 'Hit'});
		   $self->element({ 'Name' => 'Hit_len',
				    'Data' => $h->{hit_len}
				  }) if exists $h->{hit_len};
		   $self->element({ 'Name' => 'Hit_id',
				    'Data' => $h->{id}
				  }) if exists $h->{id};
		   $self->element({ 'Name' =>  'Hit_accession',
				    'Data'  => $h->{acc}
				  }) if exists $h->{acc};
		   $self->element({ 'Name' => 'Hit_def',
				    'Data' => $h->{desc}
				  }) if exists $h->{desc};
		   $self->element({'Name' => 'Hit_signif',
				   'Data' => $h->{evalue}
				  }) if exists $h->{evalue};
		   $self->element({'Name' => 'Hit_score',
				   'Data' => $h->{bits}
				  }) if exists $h->{bits};

		   $self->start_element({'Name' => 'Hsp'});
		   $self->element({'Name' => 'Hsp_score', 'Data' => $h->{'z-sc'} }) if exists $h->{'z-sc'};
		   $self->element({'Name' => 'Hsp_evalue', 'Data' => $h->{evalue} }) if exists $h->{evalue};
		   $self->element({'Name' => 'Hsp_bit-score', 'Data' => $h->{bits} }) if exists $h->{bits};
		   $self->element({'Name' => 'Hsp_sw-score', 'Data' => $h->{sw} }) if exists $h->{sw};
		   $self->element({'Name' => 'Hsp_gaps', 'Data' => $h->{'%_gid'} }) if exists $h->{'%_gid'};
		   $self->element({'Name' => 'Hsp_identity', 'Data' => POSIX::ceil($h->{'%_id'} * $h->{alen}) })
		       if (exists $h->{'%_id'} && exists $h->{alen});
		   $self->element({'Name' => 'Hsp_positive', 'Data' => 100 * $h->{'%_id'} }) if exists $h->{'%_id'};
		   $self->element({'Name' => 'Hsp_align-len', 'Data' => $h->{alen} }) if exists $h->{alen};
		   $self->element({'Name' => 'Hsp_query-from', 'Data' => $h->{an0} }) if exists $h->{an0};
		   $self->element({'Name' => 'Hsp_query-to', 'Data' => $h->{ax0} }) if exists $h->{ax0};
		   $self->element({'Name' => 'Hsp_hit-from', 'Data' => $h->{an1} }) if exists $h->{an1};
		   $self->element({'Name' => 'Hsp_hit-to', 'Data' => $h->{ax1} }) if exists $h->{ax1};

		   $self->element({'Name' => 'Hsp_querygaps', 'Data' => $h->{qgaps} }) if exists $h->{qgaps};
		   $self->element({'Name' => 'Hsp_hitgaps', 'Data' => $h->{lgaps} }) if exists $h->{lgaps};

		   if ($self->{'_reporttype'} =~ m/^FAST[NXY]$/o) {
		       if( 8 == scalar grep { exists $h->{$_} } qw(an0 ax0 pn0 px0 an1 ax1 pn1 px1) ) {
			   if ($h->{ax0} < $h->{an0}) {
			       $self->element({'Name' => 'Hsp_query-frame', 'Data' => "-@{[(($h->{px0} - $h->{ax0}) % 3) + 1]}" });
			   } else {
			       $self->element({'Name' => 'Hsp_query-frame', 'Data' => "+@{[(($h->{an0} - $h->{pn0}) % 3) + 1]}" });
			   }
			   if ($h->{ax1} < $h->{an1}) {
			       $self->element({'Name' => 'Hsp_hit-frame', 'Data' => "-@{[(($h->{px1} - $h->{ax1}) % 3) + 1]}" });
			   } else {
			       $self->element({'Name' => 'Hsp_hit-frame', 'Data' => "+@{[(($h->{an1} - $h->{pn1}) % 3) + 1]}" });
			   }
		       } else {
			   $self->element({'Name' => 'Hsp_query-frame', 'Data' => $h->{lframe} });
			   $self->element({'Name' => 'Hsp_hit-frame', 'Data' => 0 });
		       }
		   } else {
		       $self->element({'Name' => 'Hsp_query-frame', 'Data' => 0 });
		       $self->element({'Name' => 'Hsp_hit-frame', 'Data' => $h->{lframe} });
		   }

		   $self->end_element({'Name' => 'Hsp'});
		   $self->end_element({'Name' => 'Hit'});
	       }
	   }

	   $self->end_element({ 'Name' => 'FastaOutput'});
	   return $self->end_document();
       } elsif( /^\s*\d+\s*>>>/) {
	   if ($self->within_element('FastaOutput')) {
	       if( $self->in_element('hsp') ) {
		   $self->end_element({'Name' => 'Hsp'});
	       } 
	       if( $self->in_element('hit') ) {
		   $self->end_element({'Name' => 'Hit'});
	       }

	       if (@hit_signifs) {
		   # process remaining best hits
		   for my $h (@hit_signifs) {
		       $self->start_element({'Name' => 'Hit'});
		       $self->element({ 'Name' => 'Hit_len',
					'Data' => $h->{hit_len}
				      }) if exists $h->{hit_len};
		       $self->element({ 'Name' => 'Hit_id',
					'Data' => $h->{id}
				      }) if exists $h->{id};
		       $self->element({ 'Name' =>  'Hit_accession',
					'Data'  => $h->{acc}
				      }) if exists $h->{acc};
		       $self->element({ 'Name' => 'Hit_def',
					'Data' => $h->{desc}
				      }) if exists $h->{desc};
		       $self->element({'Name' => 'Hit_signif',
				       'Data' => $h->{evalue}
				      }) if exists $h->{evalue};
		       $self->element({'Name' => 'Hit_score',
				       'Data' => $h->{bits}
				      }) if exists $h->{bits};

		       $self->start_element({'Name' => 'Hsp'});
		       $self->element({'Name' => 'Hsp_score', 'Data' => $h->{'z-sc'} }) if exists $h->{'z-sc'};
		       $self->element({'Name' => 'Hsp_evalue', 'Data' => $h->{evalue} }) if exists $h->{evalue};
		       $self->element({'Name' => 'Hsp_bit-score', 'Data' => $h->{bits} }) if exists $h->{bits};
		       $self->element({'Name' => 'Hsp_sw-score', 'Data' => $h->{sw} }) if exists $h->{sw};
		       $self->element({'Name' => 'Hsp_gaps', 'Data' => $h->{'%_gid'} }) if exists $h->{'%_gid'};
		       $self->element({'Name' => 'Hsp_identity', 'Data' => POSIX::ceil($h->{'%_id'} * $h->{alen}) })
			   if (exists $h->{'%_id'} && exists $h->{alen});
		       $self->element({'Name' => 'Hsp_positive', 'Data' => $h->{'%_id'} }) if exists $h->{'%_id'};
		       $self->element({'Name' => 'Hsp_align-len', 'Data' => $h->{alen} }) if exists $h->{alen};
		       $self->element({'Name' => 'Hsp_query-from', 'Data' => $h->{an0} }) if exists $h->{an0};
		       $self->element({'Name' => 'Hsp_query-to', 'Data' => $h->{ax0} }) if exists $h->{ax0};
		       $self->element({'Name' => 'Hsp_hit-from', 'Data' => $h->{an1} }) if exists $h->{an1};
		       $self->element({'Name' => 'Hsp_hit-to', 'Data' => $h->{ax1} }) if exists $h->{ax1};

		       $self->element({'Name' => 'Hsp_querygaps', 'Data' => $h->{qgaps} }) if exists $h->{qgaps};
		       $self->element({'Name' => 'Hsp_hitgaps', 'Data' => $h->{lgaps} }) if exists $h->{lgaps};
		       
		       if ($self->{'_reporttype'} =~ m/^FAST[NXY]$/o) {
			   if( 8 == scalar grep { exists $h->{$_} } qw(an0 ax0 pn0 px0 an1 ax1 pn1 px1) ) {
			       if ($h->{ax0} < $h->{an0}) {
				   $self->element({'Name' => 'Hsp_query-frame', 'Data' => "-@{[(($h->{px0} - $h->{ax0}) % 3) + 1]}" });
			       } else {
				   $self->element({'Name' => 'Hsp_query-frame', 'Data' => "+@{[(($h->{an0} - $h->{pn0}) % 3) + 1]}" });
			       }
			       if ($h->{ax1} < $h->{an1}) {
				   $self->element({'Name' => 'Hsp_hit-frame', 'Data' => "-@{[(($h->{px1} - $h->{ax1}) % 3) + 1]}" });
			       } else {
				   $self->element({'Name' => 'Hsp_hit-frame', 'Data' => "+@{[(($h->{an1} - $h->{pn1}) % 3) + 1]}" });
			       }
			   } else {
			       $self->element({'Name' => 'Hsp_query-frame', 'Data' => $h->{lframe} });
			       $self->element({'Name' => 'Hsp_hit-frame', 'Data' => 0 });
			   }
		       } else {
			   $self->element({'Name' => 'Hsp_query-frame', 'Data' => 0 });
			   $self->element({'Name' => 'Hsp_hit-frame', 'Data' => $h->{lframe} });
		       }

		       $self->end_element({'Name' => 'Hsp'});
		       $self->end_element({'Name' => 'Hit'});
		   }
	       }
	       $self->end_element({ 'Name' => 'FastaOutput' });
	       $self->_pushback($_);
	       return $self->end_document();
	   } else {
	       $self->start_element({ 'Name' => 'FastaOutput' });
	       $self->{'_result_count'}++;
	       $seentop = 1;
	       $self->element({ 'Name' => 'FastaOutput_program',
				'Data' => $self->{'_reporttype'} });
	       $self->element({ 'Name' => 'FastaOutput_version',
				'Data' => $self->{'_version'} });

	       my ($type, $querylen, $querytype, $querydef);

	       if( /^\s*\d+\s*>>>(.*)/ ) {
		   $querydef = $1;
		   if($querydef =~ /^(.*?)\s+(?:\-\s+)?(\d+)\s+(aa|nt)\s*$/o ) {
		       ($querydef, $querylen, $querytype) = ($1, $2, $3);
		   }
	       }

	       if( $self->{'_reporttype'} &&
		   $self->{'_reporttype'} eq 'FASTA' 
		   ) {
		   if( $querytype eq 'nt') {
		       $self->{'_reporttype'} = 'FASTN' ;
		   } elsif( $querytype eq 'aa' ) {
		       $self->{'_reporttype'} = 'FASTP' ;
		   }
	       }
	       my ($name,$descr) = ($querydef =~ m/^(\S+)(?:\s+(.*))?\s*$/o);
	       $self->element({'Name' => 'FastaOutput_query-def',
			       'Data' => $name});
	       $self->element({'Name' => 'FastaOutput_querydesc',
			       'Data' => $descr});
	       if ($querylen) {
		   $self->element({'Name' => 'FastaOutput_query-len',
				   'Data' => $querylen});
	       } else {
		   $self->warn("unable to find and set query length");
	       }


	       if( defined ($_ = $self->_readline()) && /^\s*vs\s+(\S+)/ ) {
		   $self->element({'Name' => 'FastaOutput_db',
				   'Data' => $1});
	       }
	   }
       } elsif( $self->in_element('hsp' ) ) {
	   
	   my @data = ( '','','');
	   my $count = 0;
	   my $len = $self->idlength + 1;
	   my ($seq1_id);
	   while( defined($_ ) ) {
	       chomp;
	       $self->debug( "$count $_\n");

	       if( /residues in \d+\s+query\s+sequences/) {
		   $self->_pushback($_);
		   last;
	       } elsif( /^>>/ ) {
		   $self->_pushback($_);
		   last;
	       } elsif (/^\s*\d+\s*>>>/) {
		   $self->_pushback($_);
		   last;
	       }
	       if( $count == 0 ) { 
		   unless( /^\s+\d+/ || /^\s+$/) {
		       $self->_pushback($_);
		       $count = 2;
		   }
	       } elsif( $count == 1 || $count == 3 ) {
		   if( /^(\S+)\s+/ ) {
		       $len = CORE::length($1) if $len < CORE::length($1);
		       s/\s+$//; # trim trailing spaces,we don't want them 
		       $data[$count-1] = substr($_,$len);
		   } elsif( /^\s+(\d+)/ ) {
		       $count = -1;
		       $self->_pushback($_);
		   } elsif( /^\s+$/ || length($_) == 0) {
		       $count = 5;  
		       # going to skip these
		   } else {
		       $self->warn("Unrecognized alignment line ($count) '$_'");
		   }
	       } elsif( $count == 2 ) {
		   if( /^\s+\d+\s+/ ) {
		       $self->warn("$_\n");
		       $count = 4;
		   } else {
		       # toss the first IDLENGTH characters of the line
		       if( length($_) >= $len ) {
			   $data[$count-1] = substr($_,$len);
		       }
		   }
	       } 
	       last if( $count++ >= 5);
	       $_ = $self->_readline();	       
	   }
	   if( length($data[0]) > 0 || length($data[2]) > 0 ) {
	       $self->characters({'Name' => 'Hsp_qseq',
				  'Data' => $data[0] });
	       $self->characters({'Name' => 'Hsp_midline',
				  'Data' => $data[1]});
	       $self->characters({'Name' => 'Hsp_hseq',
				  'Data' => $data[2]});
	   }
       } else {
	   if( ! $seentop ) {
	       $self->debug($_);
	       $self->warn("unrecognized FASTA Family report file!");
	       return undef;
	   }
       }
   }
}


#line 804

sub start_element{
   my ($self,$data) = @_;
    # we currently don't care about attributes
    my $nm = $data->{'Name'};    
    if( my $type = $MODEMAP{$nm} ) {
	$self->_mode($type);
	if( $self->_eventHandler->will_handle($type) ) {
	    my $func = sprintf("start_%s",lc $type);
	    $self->_eventHandler->$func($data->{'Attributes'});
	}						 
	unshift @{$self->{'_elements'}}, $type;
    }
    if($nm eq 'FastaOutput') {
	$self->{'_values'} = {};
	$self->{'_result'}= undef;
	$self->{'_mode'} = '';
    }

}

#line 835

sub end_element {
    my ($self,$data) = @_;
    my $nm = $data->{'Name'};
    my $rc;
    # Hsp are sort of weird, in that they end when another
    # object begins so have to detect this in end_element for now
    if( $nm eq 'Hsp' ) {
	foreach ( qw(Hsp_qseq Hsp_midline Hsp_hseq) ) {
	    $self->element({'Name' => $_,
			    'Data' => $self->{'_last_hspdata'}->{$_}});
	}
	$self->{'_last_hspdata'} = {}
    }

    if( my $type = $MODEMAP{$nm} ) {
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
	$self->warn( "unknown nm $nm, ignoring\n");
    }
    $self->{'_last_data'} = ''; # remove read data if we are at 
				# end of an element
    $self->{'_result'} = $rc if( $nm eq 'FastaOutput' );
    return $rc;

}

#line 885

sub element{
   my ($self,$data) = @_;
   $self->start_element($data);
   $self->characters($data);
   $self->end_element($data);
}


#line 904

sub characters{
   my ($self,$data) = @_;   

   return unless ( defined $data->{'Data'} );
   if( $data->{'Data'} =~ /^\s+$/ ) {
       return unless $data->{'Name'} =~ /Hsp\_(midline|qseq|hseq)/;
   }

   if( $self->in_element('hsp') && 
       $data->{'Name'} =~ /Hsp\_(qseq|hseq|midline)/ ) {
       
       $self->{'_last_hspdata'}->{$data->{'Name'}} .= $data->{'Data'};
   }  
   
   $self->{'_last_data'} = $data->{'Data'}; 
}

#line 933

sub _mode{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_mode'} = $value;
    }
    return $self->{'_mode'};
}

#line 954

sub within_element{
   my ($self,$name) = @_;  
   return 0 if ( ! defined $name &&
		 ! defined  $self->{'_elements'} ||
		 scalar @{$self->{'_elements'}} == 0) ;
   foreach (  @{$self->{'_elements'}} ) {
       if( $_ eq $name || $_ eq $MODEMAP{$name} ) {
	   return 1;
       } 
   }
   return 0;
}

#line 980

sub in_element{
   my ($self,$name) = @_;  
   return 0 if ! defined $self->{'_elements'}->[0];
   return ( $self->{'_elements'}->[0] eq $name ||
	    (exists $MODEMAP{$name} && $self->{'_elements'}->[0] eq $MODEMAP{$name})
	  );
}


#line 1000

sub start_document{
    my ($self) = @_;
    $self->{'_lasttype'} = '';
    $self->{'_values'} = {};
    $self->{'_result'}= undef;
    $self->{'_mode'} = '';
    $self->{'_elements'} = [];
}


#line 1021

sub end_document{
   my ($self,@args) = @_;
   return $self->{'_result'};
}

#line 1039

sub idlength{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'_idlength'} = $value;
    }
    return $self->{'_idlength'} || $IDLENGTH;
}


#line 1059

sub result_count {
    my $self = shift;
    return $self->{'_result_count'};
}

1;

