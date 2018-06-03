#line 1 "Bio/Tools/BPbl2seq.pm"
# $Id: BPbl2seq.pm,v 1.21.2.2 2003/06/03 14:38:18 jason Exp $
#
# Bioperl module Bio::Tools::BPbl2seq
#	based closely on the Bio::Tools::BPlite modules
#	Ian Korf (ikorf@sapiens.wustl.edu, http://sapiens.wustl.edu/~ikorf),
#	Lorenz Pollak (lorenz@ist.org, bioperl port)
#
#
# Copyright Peter Schattner
#
# You may distribute this module under the same terms as perl itself
# _history
# October 20, 2000
# May 29, 2001
#	Fixed bug which prevented reading of more than one HSP / hit.
#	This fix required changing calling syntax as described below. (PS)
# POD documentation - main docs before the code

#line 119

#'
package Bio::Tools::BPbl2seq;

use strict;
use vars qw(@ISA);
use Bio::Tools::BPlite;
use Bio::Root::Root;
use Bio::Root::IO;
use Bio::Tools::BPlite::Sbjct; # we want to use Sbjct
use Bio::SeqAnalysisParserI;
use Symbol;

@ISA = qw(Bio::Root::Root Bio::SeqAnalysisParserI Bio::Root::IO);

#@ISA = qw(Bio::Tools::BPlite);

#line 146

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    # initialize IO
    $self->_initialize_io(@args);

     my ($queryname,$rt) = $self->_rearrange([qw(QUERYNAME 
						 REPORT_TYPE)], @args);
    $queryname = 'unknown' if( ! defined $queryname );
    if( $rt && $rt =~ /BLAST/i ) {
	$self->{'BLAST_TYPE'} = uc($rt);
    } else { 
	$self->warn("Must provide which type of BLAST was run (blastp,blastn, tblastn, tblastx, blastx) if you want strand information to get set properly for DNA query or subjects");
    }
    my $sbjct = $self->getSbjct();
    $self->{'_current_sbjct'} = $sbjct;

    $self->{'_query'}->{'NAME'} = $queryname;
    return $self;
}


#line 179

sub getSbjct {
  my ($self) = @_;
#  $self->_fastForward or return undef;

  #######################
  # get bl2seq "sbjct" name and length #
  #######################
  my $length;
  my $def;
 READLOOP: while(defined ($_ = $self->_readline) ) {
     if ($_ =~ /^>(.+)$/) {
	$def = $1;
	next READLOOP;
     }
    elsif ($_ =~ /^\s*Length\s.+\D(\d+)/i) {
	$length = $1;	
	next READLOOP;
     }
    elsif ($_ =~ /^\s{0,2}Score/) {
	$self->_pushback($_); 	
	last READLOOP;
     }
  }
  return undef if ! defined $def;
  $def =~ s/\s+/ /g;
  $def =~ s/\s+$//g;
  

  ####################
  # the Sbjct object #
  ####################
  my $sbjct = new Bio::Tools::BPlite::Sbjct('-name'=>$def,
					    '-length'=>$length,
					    '-parent'=>$self);
  return $sbjct;
}




#line 232

sub next_feature{
   my ($self) = @_;
   my ($sbjct, $hsp);
   $sbjct = $self->{'_current_sbjct'};
   unless( defined $sbjct ) {
       $self->debug(" No hit object found for bl2seq report \n ") ;
       return undef;
   }
   $hsp = $sbjct->nextHSP;
   return $hsp || undef;
}

#line 255

sub  queryName {
    my ($self, $queryname) = @_;
    if( $queryname ) {
	$self->{'_query'}->{'NAME'} = $queryname;
    }
    $self->{'_query'}->{'NAME'};
}

#line 274

sub  sbjctName {
	my $self = shift;
#	unless( defined  $self->{'_current_sbjct'} ) {
#       		my $sbjct = $self->{'_current_sbjct'} = $self->nextSbjct;
#       		return undef unless defined $sbjct;
#   	}
	$self->{'_current_sbjct'}->{'NAME'} || '';
}

#line 294

sub sbjctLength {
	my $self = shift;
#	unless( defined  $self->{'_current_sbjct'} ) {
#       		my $sbjct = $self->{'_current_sbjct'} = $self->nextSbjct;
#       		return undef unless defined $sbjct;
#   	}
	$self->{'_current_sbjct'}->{'LENGTH'};
}

#line 311

sub P     {
	my $self = shift;
	$self->throw("Syntax used is no longer supported.\n  See BPbl2seq.pm documentation for current syntax.\n ");
}

#line 324

sub percent  {
	my $self = shift;
	$self->throw("Syntax used is no longer supported.\n  See BPbl2seq.pm documentation for current syntax.\n ");
}

#line 337

sub match  {
	my $self = shift;
	$self->throw("Syntax used is no longer supported.\n  See BPbl2seq.pm documentation for current syntax.\n ");
}

#line 350

sub positive  {
	my $self = shift;
	$self->throw("Syntax used is no longer supported.\n  See BPbl2seq.pm documentation for current syntax.\n ") ;
}

#line 363

sub querySeq  {
	my $self = shift;
	$self->throw("Syntax used is no longer supported.\n  See BPbl2seq.pm documentation for current syntax.\n ") ;
}

#line 376

sub sbjctSeq  {
	my $self = shift;
	$self->throw("Syntax used is no longer supported.\n  See BPbl2seq.pm documentation for current syntax.\n ") ;
}

#line 389

sub homologySeq  {
	my $self = shift;
	$self->throw("Syntax used is no longer supported.\n  See BPbl2seq.pm documentation for current syntax.\n ") ;
}

#line 402

sub qs        {
	my $self = shift;
	$self->throw("Syntax used is no longer supported.\n  See BPbl2seq.pm documentation for current syntax.\n ") ;
}

#line 415

sub ss     {
	my $self = shift;
	$self->throw("Syntax used is no longer supported.\n  See BPbl2seq.pm documentation for current syntax.\n ") ;
}

#line 428

sub hs   {
	my $self = shift;
	$self->throw("Syntax used is no longer supported.\n  See BPbl2seq.pm documentation for current syntax.\n ") ;
}

sub _fastForward {
    my ($self) = @_;
    return 0 if $self->{'REPORT_DONE'}; # empty report
    while(defined( $_ = $self->_readline() ) ) {
	if ($_ =~ /^>|^Parameters|^\s+Database:|^\s+Posted date:|^\s*Lambda/) {
	    $self->_pushback($_);	
	    return 1;
	}
    }
    $self->warn("Possible error (1) while parsing BLAST report!");
}

1;
__END__
