#line 1 "Bio/Tools/BPlite.pm"
# $Id: BPlite.pm,v 1.36.2.2 2003/02/20 00:39:03 jason Exp $
##############################################################################
# Bioperl module Bio::Tools::BPlite
##############################################################################
#
# The original BPlite.pm module has been written by Ian Korf !
# see http://sapiens.wustl.edu/~ikorf
#
# You may distribute this module under the same terms as perl itself

#line 172

package Bio::Tools::BPlite;

use strict;
use vars qw(@ISA);

use Bio::Root::Root;
use Bio::Root::IO;
use Bio::Tools::BPlite::Sbjct; # we want to use Sbjct
use Bio::SeqAnalysisParserI;
use Symbol;

@ISA = qw(Bio::Root::Root Bio::SeqAnalysisParserI Bio::Root::IO);

# new comes from a RootI now

#line 197

sub new {
  my ($class, @args) = @_; 
  my $self = $class->SUPER::new(@args);

  # initialize IO
  $self->_initialize_io(@args);

  $self->{'QPATLOCATION'} = [];  # Anonymous array of query pattern locations for PHIBLAST

  if ($self->_parseHeader) {$self->{'REPORT_DONE'} = 0} # there are alignments
  else                     {$self->{'REPORT_DONE'} = 1} # empty report
  
  return $self; # success - we hope!
}

# for SeqAnalysisParserI compliance

#line 229

sub next_feature{
   my ($self) = @_;
   my ($sbjct, $hsp);
   $sbjct = $self->{'_current_sbjct'};
   unless( defined $sbjct ) {
       $sbjct = $self->{'_current_sbjct'} = $self->nextSbjct;
       return undef unless defined $sbjct;
   }   
   $hsp = $sbjct->nextHSP;
   unless( defined $hsp ) {
       $self->{'_current_sbjct'} = undef;
       return $self->next_feature;
   }
   return $hsp || undef;
}

#line 256

sub query    {shift->{'QUERY'}}

#line 269

sub qlength  {shift->{'LENGTH'}}

#line 279

sub pattern {shift->{'PATTERN'}}

#line 290

sub query_pattern_location {shift->{'QPATLOCATION'}}

#line 303

sub database {shift->{'DATABASE'}}

#line 317

sub nextSbjct {
  my ($self) = @_;
  
  $self->_fastForward or return undef;
  
  #######################
  # get all sbjct lines #
  #######################
  my $def = $self->_readline();  
  while(defined ($_ = $self->_readline() ) ) {
    if    ($_ !~ /\w/)            {next}
    elsif ($_ =~ /Strand HSP/)    {next} # WU-BLAST non-data
    elsif ($_ =~ /^\s{0,2}Score/) {$self->_pushback($_); last}
    elsif ($_ =~ /^Histogram|^Searching|^Parameters|^\s+Database:|^\s+Posted date:/) {
	$self->_pushback($_); 
	last;
    }
    else                          {$def .= $_}
  }
  $def =~ s/\s+/ /g;
  $def =~ s/\s+$//g;
  $def =~ s/Length = ([\d,]+)$//g;
  my $length = $1;
  return undef unless $def =~ /^>/;
  $def =~ s/^>//;

  ####################
  # the Sbjct object #
  ####################
  my $sbjct = new Bio::Tools::BPlite::Sbjct('-name'=>$def,
					    '-length'=>$length,
                                            '-parent'=>$self);
  return $sbjct;
}

# begin private routines

sub _parseHeader {
  my ($self) = @_;

  # normally, _parseHeader will break out of the parse as soon as it
  # reaches a new Subject (i.e. the first one after the header) if you
  # call _parseHeader twice in a row, with nothing in between, all you
  # accomplish is a ->nextSubject call..  so we need a flag to
  # indicate that we have *entered* a header, before we are allowed to
  # leave it!

  my $header_flag = 0; # here is the flag/ It is "false" at first, and
                       # is set to "true" when any valid header element
                       # is encountered

  $self->{'REPORT_DONE'} = 0;  # reset this bit for a new report
  while(defined($_ = $self->_readline() ) ) {
      s/\(\s*\)//;
      if ($_ =~ /^Query=(?:\s+([^\(]+))?/) {
	  $header_flag = 1;	# valid header element found
	  my $query = $1;
	  while( defined($_ = $self->_readline() ) ) {
	      # Continue reading query name until encountering either
	      # a line that starts with "Database" or a blank line.
	      # The latter condition is needed in order to be able to
	      # parse megablast output correctly, since Database comes
	      # before (not after) the query.
	      if( ($_ =~ /^Database/) || ($_ =~ /^$/) ) {
		  $self->_pushback($_); last;
	      }	      
	      $query .= $_;
	  }
	  $query =~ s/\s+/ /g;
	  $query =~ s/^>//;

	  my $length = 0;
	  if( $query =~ /\(([\d,]+)\s+\S+\)\s*$/ ) {      
	      $length = $1;
	      $length =~ s/,//g;
	  } else { 
	      $self->debug("length is 0 for '$query'\n");
	  }
	  $self->{'QUERY'} = $query;
	  $self->{'LENGTH'} = $length;
      }
      elsif ($_ =~ /^(<b>)?(T?BLAST[NPX])\s+([\w\.-]+)\s+(\[[\w-]*\])/) { 
	  $self->{'BLAST_TYPE'} = $2; 
	  $self->{'BLAST_VERSION'} = $3;
      }				# BLAST report type - not a valid header element # JB949
      
      # Support Paracel BTK output
      elsif ( $_ =~ /(^[A-Z0-9_]+)\s+BTK\s+/ ) { 
	  $self->{'BLAST_TYPE'} = $1;
	  $self->{'BTK'} = 1;
     } 
      elsif ($_ =~ /^Database:\s+(.+)/) {$header_flag = 1;$self->{'DATABASE'} = $1} # valid header element found
      elsif ($_ =~ /^\s*pattern\s+(\S+).*position\s+(\d+)\D/) {   
	  # For PHIBLAST reports
	  $header_flag = 1;	# valid header element found
	  $self->{'PATTERN'} = $1;
	  push (@{$self->{'QPATLOCATION'}}, $2);
      } 
      elsif (($_ =~ /^>/) && ($header_flag==1)) {$self->_pushback($_); return 1} # only leave if we have actually parsed a valid header!
      elsif (($_ =~ /^Parameters|^\s+Database:/) && ($header_flag==1)) { # if we entered a header, and saw nothing before the stats at the end, then it was empty
	  $self->_pushback($_);
	  return 0;		# there's nothing in the report
      }
      # bug fix suggested by MI Sadowski via Martin Lomas
      # see bug report #1118
      if( ref($self->_fh()) !~ /GLOB/ && $self->_fh()->can('EOF') && eof($self->_fh()) ) {
	  $self->warn("unexpected EOF in file\n");
	  return -1;
      }
  }
  return -1; # EOF
}

sub _fastForward {
    my ($self) = @_;
    return 0 if $self->{'REPORT_DONE'}; # empty report
    while(defined( $_ = $self->_readline() ) ) {
	if ($_ =~ /^Histogram|^Searching|^Parameters|^\s+Database:|^\s+Posted date:/) {
	    return 0;
	} elsif( $_ =~ /^>/ ) {
	    $self->_pushback($_);	
	    return 1;
	}
    }
    unless( $self->{'BTK'} ) { # Paracel BTK reports have no footer
	$self->warn("Possible error (1) while parsing BLAST report!");
    }
}

1;
__END__
