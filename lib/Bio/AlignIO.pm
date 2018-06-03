#line 1 "Bio/AlignIO.pm"
# $Id: AlignIO.pm,v 1.28 2002/10/22 07:38:23 lapp Exp $
#
# BioPerl module for Bio::AlignIO
#
#	based on the Bio::SeqIO module
#       by Ewan Birney <birney@sanger.ac.uk>
#       and Lincoln Stein  <lstein@cshl.org>
#
# Copyright Peter Schattner
#
# You may distribute this module under the same terms as perl itself
#
# _history
# October 18, 1999  SeqIO largely rewritten by Lincoln Stein
# September, 2000 AlignIO written by Peter Schattner

# POD documentation - main docs before the code

#line 288

# 'Let the code begin...

package Bio::AlignIO;

use strict;
use vars qw(@ISA);

use Bio::Root::Root;
use Bio::Seq;
use Bio::LocatableSeq;
use Bio::SimpleAlign;
use Bio::Root::IO;
@ISA = qw(Bio::Root::Root Bio::Root::IO);

#line 316

sub new {
    my ($caller,@args) = @_;
    my $class = ref($caller) || $caller;
    
    # or do we want to call SUPER on an object if $caller is an
    # object?
    if( $class =~ /Bio::AlignIO::(\S+)/ ) {
	my ($self) = $class->SUPER::new(@args);	
	$self->_initialize(@args);
	return $self;
    } else { 

	my %param = @args;
	@param{ map { lc $_ } keys %param } = values %param; # lowercase keys
	my $format = $param{'-format'} || 
	    $class->_guess_format( $param{-file} || $ARGV[0] ) ||
		'fasta';
	$format = "\L$format";	# normalize capitalization to lower case

	# normalize capitalization
	return undef unless( $class->_load_format_module($format) );
	return "Bio::AlignIO::$format"->new(@args);
    }
}


#line 355

sub newFh {
  my $class = shift;
  return unless my $self = $class->new(@_);
  return $self->fh;
}

#line 374


sub fh {
  my $self = shift;
  my $class = ref($self) || $self;
  my $s = Symbol::gensym;
  tie $$s,$class,$self;
  return $s;
}

# _initialize is where the heavy stuff will happen when new is called

sub _initialize {
  my($self,@args) = @_;

  $self->_initialize_io(@args);
  1;
}

#line 403

sub _load_format_module {
  my ($self,$format) = @_;
  my $module = "Bio::AlignIO::" . $format;
  my $ok;
  
  eval {
      $ok = $self->_load_module($module);
  };
  if ( $@ ) {
    print STDERR <<END;
$self: $format cannot be found
Exception $@
For more information about the AlignIO system please see the AlignIO docs.
This includes ways of checking for formats at compile time, not run time
END
  ;
    return;
  }
  return 1;
}

#line 434

sub next_aln {
   my ($self,$aln) = @_;
   $self->throw("Sorry, you cannot read from a generic Bio::AlignIO object.");
}

#line 449

sub write_aln {
    my ($self,$aln) = @_;
    $self->throw("Sorry, you cannot write to a generic Bio::AlignIO object.");
}

#line 465

sub _guess_format {
   my $class = shift;
   return unless $_ = shift;
   return 'fasta'   if /\.(fasta|fast|seq|fa|fsa|nt|aa)$/i;
   return 'msf'     if /\.(msf|pileup|gcg)$/i;
   return 'pfam'    if /\.(pfam|pfm)$/i;
   return 'selex'   if /\.(selex|slx|selx|slex|sx)$/i;
   return 'phylip'  if /\.(phylip|phlp|phyl|phy|phy|ph)$/i;
   return 'nexus'   if /\.(nexus|nex)$/i;
   return 'mega'     if( /\.(meg|mega)$/i );
   return 'clustalw' if( /\.aln$/i );
   return 'meme'     if( /\.meme$/i );
   return 'emboss'   if( /\.(water|needle)$/i );
   return 'psi'      if( /\.psi$/i );
}

sub DESTROY {
    my $self = shift;
    $self->close();
}

sub TIEHANDLE {
  my $class = shift;
  return bless {'alignio' => shift},$class;
}

sub READLINE {
  my $self = shift;
  return $self->{'alignio'}->next_aln() unless wantarray;
  my (@list,$obj);
  push @list,$obj  while $obj = $self->{'alignio'}->next_aln();
  return @list;
}

sub PRINT {
  my $self = shift;
  $self->{'alignio'}->write_aln(@_);
}

1;
