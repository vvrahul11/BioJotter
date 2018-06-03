#line 1 "Bio/SearchIO/waba.pm"
# $Id: waba.pm,v 1.8 2002/12/11 22:12:32 jason Exp $
#
# BioPerl module for Bio::SearchIO::waba
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 73


# Let the code begin...


package Bio::SearchIO::waba;
use vars qw(@ISA  %MODEMAP %MAPPING @STATES);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::SearchIO;

use POSIX;

BEGIN { 
    # mapping of NCBI Blast terms to Bioperl hash keys
    %MODEMAP = ('WABAOutput' => 'result',
		'Hit'         => 'hit',
		'Hsp'         => 'hsp'
		);
    @STATES = qw(Hsp_qseq Hsp_hseq Hsp_stateseq);
    %MAPPING = 
	( 
	  'Hsp_query-from'=>  'HSP-query_start',
	  'Hsp_query-to'  =>  'HSP-query_end',
	  'Hsp_hit-from'  =>  'HSP-hit_start',
	  'Hsp_hit-to'    =>  'HSP-hit_end',
	  'Hsp_qseq'      =>  'HSP-query_seq',
	  'Hsp_hseq'      =>  'HSP-hit_seq',
	  'Hsp_midline'   =>  'HSP-homology_seq',
	  'Hsp_stateseq'  =>  'HSP-hmmstate_seq',
	  'Hsp_align-len' =>  'HSP-hsp_length',
	  
	  'Hit_id'        => 'HIT-name',
	  'Hit_accession' => 'HIT-accession',

	  'WABAOutput_program'  => 'RESULT-algorithm_name',
	  'WABAOutput_version'  => 'RESULT-algorithm_version',
	  'WABAOutput_query-def'=> 'RESULT-query_name',
	  'WABAOutput_query-db' => 'RESULT-query_database',
 	  'WABAOutput_db'       => 'RESULT-database_name',
	  );
}


@ISA = qw(Bio::SearchIO );

#line 130

sub _initialize {
    my ($self,@args) = @_;
    $self->SUPER::_initialize(@args);
    $self->_eventHandler->register_factory('result', Bio::Search::Result::ResultFactory->new(-type => 'Bio::Search::Result::WABAResult'));

    $self->_eventHandler->register_factory('hsp', Bio::Search::HSP::HSPFactory->new(-type => 'Bio::Search::HSP::WABAHSP'));
}


#line 149

sub next_result{
    my ($self) = @_;
    
    my ($curquery,$curhit);
    my $state = -1;
    $self->start_document();
    my @hit_signifs;
    while( defined ($_ = $self->_readline )) { 
	
	if( $state == -1 ) {
	    my ($qid, $qhspid,$qpercent, $junk,
		$alnlen,$qdb,$qacc,$qstart,$qend,$qstrand,
		$hitdb,$hacc,$hstart,$hend,
		$hstrand) =
		    ( /^(\S+)\.(\S+)\s+align\s+ # get the queryid
		      (\d+(\.\d+)?)\%\s+     # get the percentage
		      of\s+(\d+)\s+  # get the length of the alignment
		      (\S+)\s+           # this is the query database
		      (\S+):(\d+)\-(\d+) # The accession:start-end for query
		      \s+([\-\+])        # query strand
		      \s+(\S+)\.         # hit db
		      (\S+):(\d+)\-(\d+) # The accession:start-end for hit
		      \s+([\-\+])\s*$    # hit strand
		      /ox );
	    
	    # Curses.  Jim's code is 0 based, the following is to readjust
	    $hstart++; $hend++; $qstart++; $qend++;
	    
	    if( ! defined $alnlen ) {
		$self->warn("Unable to parse the rest of the WABA alignment info for: $_");
		last;
	    }
	    $self->{'_reporttype'} = 'WABA'; # hardcoded - only 
	                                     # one type of WABA AFAIK	    
	    if( defined $curquery && 
		$curquery ne $qid ) { 
		$self->end_element({'Name' => 'Hit'});
		$self->_pushback($_);
		$self->end_element({'Name' => 'WABAOutput'});
		return $self->end_document();
	    } 
	    
	    if( defined $curhit &&
		$curhit ne $hacc) {
		# slight duplication here -- keep these in SYNC
		$self->end_element({'Name' => 'Hit'});
		$self->start_element({'Name' => 'Hit'});
		$self->element({'Name' => 'Hit_id',
				'Data' => $hacc});
		$self->element({'Name' => 'Hit_accession',
				'Data' => $hacc});

	    } elsif ( ! defined $curquery ) {
		$self->start_element({'Name' => 'WABAOutput'});
		$self->{'_result_count'}++;
		$self->element({'Name' => 'WABAOutput_query-def',
				'Data' => $qid });
		$self->element({'Name' => 'WABAOutput_program',
				'Data' => 'WABA'});
		$self->element({'Name' => 'WABAOutput_query-db',
				'Data' => $qdb});
		$self->element({'Name' => 'WABAOutput_db',
				'Data' => $hitdb});
		
		# slight duplication here -- keep these N'SYNC ;-)
		$self->start_element({'Name' => 'Hit'});
		$self->element({'Name' => 'Hit_id',
				'Data' => $hacc});
		$self->element({'Name' => 'Hit_accession',
				'Data' => $hacc});
	    }

	    
	    # strand is inferred by start,end values
	    # in the Result Builder
	    if( $qstrand eq '-' ) {
		($qstart,$qend) = ($qend,$qstart);
	    }
	    if( $hstrand eq '-' ) {
		($hstart,$hend) = ($hend,$hstart);
	    }

	    $self->start_element({'Name' => 'Hsp'});
	    $self->element({'Name' => 'Hsp_query-from',
			    'Data' => $qstart});
	    $self->element({'Name' => 'Hsp_query-to',
			    'Data' => $qend});
	    $self->element({'Name' => 'Hsp_hit-from',
			    'Data' => $hstart});
	    $self->element({'Name' => 'Hsp_hit-to',
			    'Data' => $hend});
	    $self->element({'Name' => 'Hsp_align-len',
			    'Data' => $alnlen});
	    
	    $curquery = $qid;
	    $curhit   = $hacc;
	    $state = 0;
	} elsif( ! defined $curquery ) {
	    $self->warn("skipping because no Hit begin line was recognized\n$_") if( $_ !~ /^\s+$/ );
	    next;
	} else { 
	    chomp;
	    $self->element({'Name' => $STATES[$state++],
			    'Data' => $_});
	    if( $state >= scalar @STATES ) {
		$state = -1;
		$self->end_element({'Name' => 'Hsp'});
	    }
	}
    }
    if( defined $curquery  ) {
	$self->end_element({'Name' => 'Hit'});
	$self->end_element({'Name' => 'WABAOutput'});
	return $self->end_document();
    }
    return undef;
}

#line 278

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
    if($nm eq 'WABAOutput') {
	$self->{'_values'} = {};
	$self->{'_result'}= undef;
	$self->{'_mode'} = '';
    }

}

#line 309

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
	$self->warn( "unknown nm $nm ignoring\n");
    }
    $self->{'_last_data'} = ''; # remove read data if we are at 
				# end of an element
    $self->{'_result'} = $rc if( $nm eq 'WABAOutput' );
    return $rc;

}

#line 359

sub element{
   my ($self,$data) = @_;
   $self->start_element($data);
   $self->characters($data);
   $self->end_element($data);
}


#line 378

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

#line 407

sub _mode{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_mode'} = $value;
    }
    return $self->{'_mode'};
}

#line 428

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

#line 454

sub in_element{
   my ($self,$name) = @_;  
   return 0 if ! defined $self->{'_elements'}->[0];
   return ( $self->{'_elements'}->[0] eq $name)
}


#line 472

sub start_document{
    my ($self) = @_;
    $self->{'_lasttype'} = '';
    $self->{'_values'} = {};
    $self->{'_result'}= undef;
    $self->{'_mode'} = '';
    $self->{'_elements'} = [];
}


#line 493

sub end_document{
   my ($self,@args) = @_;
   return $self->{'_result'};
}

#line 509

sub result_count {
    my $self = shift;
    return $self->{'_result_count'};
}

sub report_count { shift->result_count }

1;
