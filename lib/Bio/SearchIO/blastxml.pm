#line 1 "Bio/SearchIO/blastxml.pm"
# $Id: blastxml.pm,v 1.24 2002/10/26 09:32:16 sac Exp $
#
# BioPerl module for Bio::SearchIO::blastxml
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 84

# Let the code begin...

package Bio::SearchIO::blastxml;
use vars qw(@ISA $DTD %MAPPING %MODEMAP $DEBUG);
use strict;

$DTD = 'ftp://ftp.ncbi.nlm.nih.gov/blast/documents/NCBI_BlastOutput.dtd';
# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;
use Bio::SearchIO;
use XML::Parser::PerlSAX;
use XML::Handler::Subs;
use HTML::Entities;
use IO::File;


BEGIN { 
    # mapping of NCBI Blast terms to Bioperl hash keys
    %MODEMAP = ('BlastOutput' => 'result',
		'Hit'         => 'hit',
		'Hsp'         => 'hsp'
		);

    %MAPPING = ( 
		 # HSP specific fields
		 'Hsp_bit-score'  => 'HSP-bits',
		 'Hsp_score'      => 'HSP-score',
		 'Hsp_evalue'     => 'HSP-evalue',
		 'Hsp_query-from' => 'HSP-query_start',
		 'Hsp_query-to'   => 'HSP-query_end',
		 'Hsp_hit-from'   => 'HSP-hit_start',
		 'Hsp_hit-to'     => 'HSP-hit_end',
		 'Hsp_positive'   => 'HSP-conserved',
		 'Hsp_identity'   => 'HSP-identical',
		 'Hsp_gaps'       => 'HSP-gaps',
		 'Hsp_hitgaps'    => 'HSP-hit_gaps',
		 'Hsp_querygaps'  => 'HSP-query_gaps',
		 'Hsp_qseq'       => 'HSP-query_seq',
		 'Hsp_hseq'       => 'HSP-hit_seq',
		 'Hsp_midline'    => 'HSP-homology_seq',
		 'Hsp_align-len'  => 'HSP-hsp_length',
		 'Hsp_query-frame'=> 'HSP-query_frame',
		 'Hsp_hit-frame'  => 'HSP-hit_frame',

		 # these are ignored for now
		 'Hsp_num'          => 'HSP-order',
		 'Hsp_pattern-from' => 'patternend',
		 'Hsp_pattern-to'   => 'patternstart',
		 'Hsp_density'      => 'hspdensity',

		 # Hit specific fields
		 'Hit_id'               => 'HIT-name',
		 'Hit_len'              => 'HIT-length',
		 'Hit_accession'        => 'HIT-accession',
		 'Hit_def'              => 'HIT-description',
		 'Hit_num'              => 'HIT-order',
		 'Iteration_iter-num'   => 'HIT-iteration',
		 'Iteration_stat'       => 'HIT-iteration_statistic',
		 
		 'BlastOutput_program'   => 'RESULT-algorithm_name',
		 'BlastOutput_version'   => 'RESULT-algorithm_version',
		 'BlastOutput_query-def' => 'RESULT-query_description',
		 'BlastOutput_query-len' => 'RESULT-query_length',
		 'BlastOutput_db'        => 'RESULT-database_name',
		 'BlastOutput_reference' => 'RESULT-program_reference',
		 'BlastOutput_query-ID'  => 'runid',
		 
		 'Parameters_matrix'    => { 'RESULT-parameters' => 'matrix'},
		 'Parameters_expect'    => { 'RESULT-parameters' => 'expect'},
		 'Parameters_include'   => { 'RESULT-parameters' => 'include'},
		 'Parameters_sc-match'  => { 'RESULT-parameters' => 'match'},
		 'Parameters_sc-mismatch' => { 'RESULT-parameters' => 'mismatch'},
		 'Parameters_gap-open'  => { 'RESULT-parameters' => 'gapopen'},
		 'Parameters_gap-extend'=> { 'RESULT-parameters' => 'gapext'},
		 'Parameters_filter'    => {'RESULT-parameters' => 'filter'},
		 'Statistics_db-num'    => 'RESULT-database_entries',
		 'Statistics_db-len'    => 'RESULT-database_letters',
		 'Statistics_hsp-len'   => { 'RESULT-statistics' => 'hsplength'},
		 'Statistics_eff-space' => { 'RESULT-statistics' => 'effectivespace'},
		 'Statistics_kappa'     => { 'RESULT-statistics' => 'kappa' },
		 'Statistics_lambda'    => { 'RESULT-statistics' => 'lambda' },
		 'Statistics_entropy'   => { 'RESULT-statistics' => 'entropy'},
		 );
    eval {  require Time::HiRes };	
    if( $@ ) { $DEBUG = 0; }
}


@ISA = qw(Bio::SearchIO );

#line 189

#line 197

sub _initialize{
   my ($self,@args) = @_;   
   $self->SUPER::_initialize(@args);
   my ($usetempfile) = $self->_rearrange([qw(TEMPFILE)],@args);
   defined $usetempfile && $self->use_tempfile($usetempfile);
   $self->{'_xmlparser'} = new XML::Parser::PerlSAX();
   $DEBUG = 1 if( ! defined $DEBUG && $self->verbose > 0);
}

#line 216

sub next_result {
    my ($self) = @_;
 
    my $data = '';
    my $firstline = 1;
    my ($tfh);
    if( $self->use_tempfile ) {
	$tfh = IO::File->new_tmpfile or $self->throw("Unable to open temp file: $!");	
	$tfh->autoflush(1);
    }
    my $okaytoprocess;
    while( defined( $_ = $self->_readline) ) {
	if( /^RPS-BLAST/i ) {
	    $self->{'_type'} = 'RPSBLAST';
	    next;
	}
	if( /^<\?xml version/ && ! $firstline) { 
	    $self->_pushback($_);
	    last;
	}
	$_ = decode_entities($_);
#	s/\&apos;/\`/g;	
#	s/\&gt;/\>/g;
#	s/\&lt;/\</g;
	$okaytoprocess = 1;
	if( defined $tfh ) {
	    print $tfh $_;
	} else {
	    $data .= $_;
	}
	$firstline = 0;
    }

    return undef unless( $okaytoprocess);
    
    my %parser_args;
    if( defined $tfh ) {
	seek($tfh,0,0);
	%parser_args = ('Source' => { 'ByteStream' => $tfh },
			'Handler' => $self);
    } else {
	%parser_args = ('Source' => { 'String' => $data },
			'Handler' => $self);
    }
    my $result;
    my $starttime;
    if(  $DEBUG ) {  $starttime = [ Time::HiRes::gettimeofday() ]; }

    eval { 
	$result = $self->{'_xmlparser'}->parse(%parser_args);
        $self->{'_result_count'}++;
    };
    if( $@ ) {
	$self->warn("error in parsing a report:\n $@");
	$result = undef;
    }    
    if( $DEBUG ) {
	$self->debug( sprintf("parsing took %f seconds\n", Time::HiRes::tv_interval($starttime)));
    }
    # parsing magic here - but we call event handlers rather than 
    # instantiating things 
    return $result;
}

#line 284

#line 295

sub start_document{
    my ($self) = @_;
    $self->{'_lasttype'} = '';
    $self->{'_values'} = {};
    $self->{'_result'}= undef;
}

#line 312

sub end_document{
   my ($self,@args) = @_;
   return $self->{'_result'};
}

#line 327

sub start_element{
    my ($self,$data) = @_;
    # we currently don't care about attributes
    my $nm = $data->{'Name'};    

    if( my $type = $MODEMAP{$nm} ) {
	if( $self->_eventHandler->will_handle($type) ) {
	    my $func = sprintf("start_%s",lc $type);
	    $self->_eventHandler->$func($data->{'Attributes'});
	}						     
    }

    if($nm eq 'BlastOutput') {
	$self->{'_values'} = {};
	$self->{'_result'}= undef;
    }
}

#line 355

sub end_element{
    my ($self,$data) = @_;

    my $nm = $data->{'Name'};
    my $rc;
    if($nm eq 'BlastOutput_program' &&
       $self->{'_last_data'} =~ /(t?blast[npx])/i ) {
	$self->{'_type'} = uc $1; 
    }

    if( my $type = $MODEMAP{$nm} ) {
	if( $self->_eventHandler->will_handle($type) ) {
	    my $func = sprintf("end_%s",lc $type);
	    $rc = $self->_eventHandler->$func($self->{'_type'},
					      $self->{'_values'});
	}
    } elsif( $MAPPING{$nm} ) { 
	if ( ref($MAPPING{$nm}) =~ /hash/i ) {
	    my $key = (keys %{$MAPPING{$nm}})[0];
	    $self->{'_values'}->{$key}->{$MAPPING{$nm}->{$key}} = $self->{'_last_data'};
	} else {
	    $self->{'_values'}->{$MAPPING{$nm}} = $self->{'_last_data'};
	}
    } elsif( $nm eq 'Iteration' || $nm eq 'Hit_hsps' || $nm eq 'Parameters' ||
	     $nm eq 'BlastOutput_param' || $nm eq 'Iteration_hits' || 
	     $nm eq 'Statistics' || $nm eq 'BlastOutput_iterations' ){
    
    } else { 	
	
	$self->debug("ignoring unrecognized element type $nm\n");
    }
    $self->{'_last_data'} = ''; # remove read data if we are at 
				# end of an element
    $self->{'_result'} = $rc if( $nm eq 'BlastOutput' );
    return $rc;
}

#line 403

sub characters{
   my ($self,$data) = @_;   
   return unless ( defined $data->{'Data'} && $data->{'Data'} !~ /^\s+$/ );
   
   $self->{'_last_data'} = $data->{'Data'}; 
}

#line 422

sub use_tempfile{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'_use_tempfile'} = $value;
    }
    return $self->{'_use_tempfile'};
}

sub result_count {
    my $self = shift;
    return $self->{'_result_count'};
}

1;
