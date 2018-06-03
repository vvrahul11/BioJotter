#line 1 "Bio/Tools/BPlite/Sbjct.pm"
# $Id: Sbjct.pm,v 1.23.2.1 2003/02/20 00:39:03 jason Exp $
###############################################################################
# Bio::Tools::BPlite::Sbjct
###############################################################################
#
# The original BPlite.pm module has been written by Ian Korf !
# see http://sapiens.wustl.edu/~ikorf
#
# You may distribute this module under the same terms as perl itself
#
# BioPerl module for Bio::Tools::BPlite::Sbjct
#
# Cared for by Peter Schattner <schattner@alum.mit.edu>
#
# Copyright Peter Schattner
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 88

# Let the code begin...

package Bio::Tools::BPlite::Sbjct;

use strict;

use Bio::Root::Root;        # root object to inherit from
use Bio::Tools::BPlite::HSP; # we want to use HSP
#use overload '""' => 'name';
use vars qw(@ISA);

@ISA = qw(Bio::Root::Root);

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    
    ($self->{'NAME'},$self->{'LENGTH'},
     $self->{'PARENT'}) =
	 $self->_rearrange([qw(NAME
			       LENGTH
			       PARENT
			       )],@args);
    $self->report_type($self->{'PARENT'}->{'BLAST_TYPE'} || 'UNKNOWN');
    $self->{'HSP_ALL_PARSED'} = 0;
    
  return $self;
}

#line 128

sub name {shift->{'NAME'}}

#line 145

sub report_type {
    my ($self, $rpt) = @_;
    if($rpt) {
	$self->{'_report_type'} = $rpt;
    }
    return $self->{'_report_type'};
}

#line 164

sub nextFeaturePair {shift->nextHSP}; # just another name

#line 177

sub nextHSP {
  my ($self) = @_;  
  return undef if $self->{'HSP_ALL_PARSED'};
  
  ############################
  # get and parse scorelines #
  ############################
  my ($qframe, $sframe);
  my $scoreline = $self->_readline();
  my $nextline = $self->_readline();
  return undef if not defined $nextline;
  $scoreline .= $nextline;
  my ($score, $bits);
  if ($scoreline =~ /\d bits\)/) {
    ($score, $bits) = $scoreline =~
      /Score = (\d+) \((\S+) bits\)/; # WU-BLAST
  }
  else {
    ($bits, $score) = $scoreline =~
      /Score =\s+(\S+) bits \((\d+)/; # NCBI-BLAST
  }
  
  my ($match, $hsplength) = ($scoreline =~ /Identities = (\d+)\/(\d+)/);
  my ($positive) = ($scoreline =~ /Positives = (\d+)/);
  my ($gaps) = ($scoreline =~ /Gaps = (\d+)/);
  if($self->report_type() eq 'TBLASTX') {
      ($qframe, $sframe) = $scoreline =~ /Frame =\s+([+-]\d)\s+\/\s+([+-]\d)/;
  } elsif ($self->report_type() eq 'TBLASTN')  {
      ($sframe) = $scoreline =~ /Frame =\s+([+-]\d)/;
  } else {
      ($qframe) = $scoreline =~ /Frame =\s+([+-]\d)/;
  }
  $positive = $match if not defined $positive;
  $gaps = '0' if not defined $gaps;
  my ($p)        = ($scoreline =~ /[Sum ]*P[\(\d+\)]* = (\S+)/);
  unless (defined $p) {(undef, $p) = $scoreline =~ /Expect(\(\d+\))? =\s+(\S+)/}
  my ($exp) = ($scoreline =~ /Expect(?:\(\d+\))? =\s+([^\s,]+)/);
  $exp = -1 unless( defined $exp );

  $self->throw("Unable to parse '$scoreline'") unless defined $score;
  
  #######################
  # get alignment lines #
  #######################
  my (@hspline);
  while( defined($_ = $self->_readline()) ) {
      if ($_ =~ /^WARNING:|^NOTE:/) {
	  while(defined($_ = $self->_readline())) {last if $_ !~ /\S/}
      }
      elsif ($_ !~ /\S/)            {next}
      elsif ($_ =~ /Strand HSP/)    {next} # WU-BLAST non-data
      elsif ($_ =~ /^\s*Strand/)    {next} # NCBI-BLAST non-data
      elsif ($_ =~ /^\s*Score/)     {$self->_pushback($_); last}

      elsif ($_ =~ /^>|^Histogram|^Searching|^Parameters|^\s+Database:|^CPU\stime|^\s*Lambda/)   
      {    
	  #ps 5/28/01	
	  # elsif ($_ =~ /^>|^Parameters|^\s+Database:|^CPU\stime/)   {
	  $self->_pushback($_);

	  $self->{'HSP_ALL_PARSED'} = 1;
	  last;
      }
      elsif( $_ =~ /^\s*Frame/ ) {
	  if ($self->report_type() eq 'TBLASTX') {
	      ($qframe, $sframe) = $_ =~ /Frame = ([\+-]\d)\s+\/\s+([\+-]\d)/;
	  } elsif ($self->report_type() eq 'TBLASTN') {
	      ($sframe) = $_ =~ /Frame = ([\+-]\d)/;
	  } else {
	      ($qframe) = $_ =~ /Frame = ([\+-]\d)/;
	  }
      }
      else {
	  push @hspline, $_;	#      store the query line
	  $nextline = $self->_readline();
	  # Skip "pattern" line when parsing PHIBLAST reports, otherwise store the alignment line
	  my $l1 = ($nextline =~ /^\s*pattern/) ? $self->_readline() : $nextline;
	  push @hspline, $l1;	# store the alignment line
	  my $l2 = $self->_readline(); push @hspline, $l2; # grab/store the sbjct line
      }
  }
  
  #########################
  # parse alignment lines #
  #########################
  my ($ql, $sl, $as) = ("", "", "");
  my ($qb, $qe, $sb, $se) = (0,0,0,0);
  my (@QL, @SL, @AS); # for better memory management
  
  for(my $i=0;$i<@hspline;$i+=3) {
    # warn $hspline[$i], $hspline[$i+2];
    $hspline[$i]   =~ /^(?:Query|Trans):\s+(\d+)\s*([\D\S]+)\s+(\d+)/;
    $ql = $2; $qb = $1 unless $qb; $qe = $3;
    
    my $offset = index($hspline[$i], $ql);
    $as = substr($hspline[$i+1], $offset, CORE::length($ql));
    
    $hspline[$i+2] =~ /^Sbjct:\s+(\d+)\s*([\D\S]+)\s+(\d+)/;
    $sl = $2; $sb = $1 unless $sb; $se = $3;

    push @QL, $ql; push @SL, $sl; push @AS, $as;
  }

  ##################
  # the HSP object #
  ##################
  $ql = join("", @QL);
  $sl = join("", @SL);
  $as = join("", @AS);
# Query name and length are not in the report for a bl2seq report so {'PARENT'}->query and
# {'PARENT'}->qlength will not be available.
  my ($qname, $qlength) = ('unknown','unknown');
  if ($self->{'PARENT'}->can('query')) {
	$qname = $self->{'PARENT'}->query;
	$qlength = $self->{'PARENT'}->qlength;
  }	
  
  my $hsp = new Bio::Tools::BPlite::HSP
      ('-score'      => $score, 
       '-bits'       => $bits, 
       '-match'      => $match,
       '-positive'   => $positive, 
       '-gaps'       => $gaps,
       '-hsplength'  => $hsplength,
       '-p'          => $p,
       '-exp'        => $exp,
       '-queryBegin' => $qb, 
       '-queryEnd'   => $qe, 
       '-sbjctBegin' => $sb,
       '-sbjctEnd'   => $se, 
       '-querySeq'   => $ql, 
       '-sbjctSeq'   => $sl,
       '-homologySeq'=> $as, 
       '-queryName'  => $qname,
#					'-queryName'=>$self->{'PARENT'}->query,
       '-sbjctName'  => $self->{'NAME'},
       '-queryLength'=> $qlength,
#					'-queryLength'=>$self->{'PARENT'}->qlength,
       '-sbjctLength'=> $self->{'LENGTH'},
       '-queryFrame' => $qframe,
       '-sbjctFrame' => $sframe,
       '-blastType'  => $self->report_type());
  return $hsp;
}

#line 339

sub _readline{
   my ($self) = @_;
   return $self->{'PARENT'}->_readline();
}

#line 355

sub _pushback {
   my ($self, $arg) = @_;   
   return $self->{'PARENT'}->_pushback($arg);    
}

1;
