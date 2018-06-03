#line 1 "Bio/SeqIO.pm"

# $Id: SeqIO.pm,v 1.59.2.4 2003/09/14 19:16:53 jason Exp $
#
# BioPerl module for Bio::SeqIO
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#       and Lincoln Stein  <lstein@cshl.org>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself
#
# _history
# October 18, 1999  Largely rewritten by Lincoln Stein

# POD documentation - main docs before the code

#line 300

#' Let the code begin...

package Bio::SeqIO;

use strict;
use vars qw(@ISA);

use Bio::Root::Root;
use Bio::Root::IO;
use Bio::Factory::SequenceStreamI;
use Bio::Factory::FTLocationFactory;
use Bio::Seq::SeqBuilder;
use Symbol();

@ISA = qw(Bio::Root::Root Bio::Root::IO Bio::Factory::SequenceStreamI);

sub BEGIN {
    eval { require Bio::SeqIO::staden::read; };
}

my %valid_alphabet_cache;

#line 344

my $entry = 0;

sub new {
    my ($caller,@args) = @_;
    my $class = ref($caller) || $caller;
    
    # or do we want to call SUPER on an object if $caller is an
    # object?
    if( $class =~ /Bio::SeqIO::(\S+)/ ) {
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
	return "Bio::SeqIO::$format"->new(@args);
    }
}

#line 386

sub newFh {
  my $class = shift;
  return unless my $self = $class->new(@_);
  return $self->fh;
}

#line 405


sub fh {
  my $self = shift;
  my $class = ref($self) || $self;
  my $s = Symbol::gensym;
  tie $$s,$class,$self;
  return $s;
}

# _initialize is chained for all SeqIO classes

sub _initialize {
    my($self, @args) = @_;

    # flush is initialized by the Root::IO init

    my ($seqfact,$locfact,$objbuilder) =
	$self->_rearrange([qw(SEQFACTORY
			      LOCFACTORY
			      OBJBUILDER)
			   ], @args);

    $locfact = Bio::Factory::FTLocationFactory->new(-verbose => $self->verbose) if ! $locfact;
    $objbuilder = Bio::Seq::SeqBuilder->new(-verbose => $self->verbose) unless $objbuilder;
    $self->sequence_builder($objbuilder);
    $self->location_factory($locfact);
    # note that this should come last because it propagates the sequence
    # factory to the sequence builder
    $seqfact && $self->sequence_factory($seqfact);

    # initialize the IO part
    $self->_initialize_io(@args);
}

#line 461

sub next_seq {
   my ($self, $seq) = @_;
   $self->throw("Sorry, you cannot read from a generic Bio::SeqIO object.");
}

#line 476

sub write_seq {
    my ($self, $seq) = @_;
    $self->throw("Sorry, you cannot write to a generic Bio::SeqIO object.");
}


#line 494

sub alphabet {
   my ($self, $value) = @_;

   if ( defined $value) {
       $value = lc $value;
       unless ($valid_alphabet_cache{$value}) {
	   # instead of hard-coding the allowed values once more, we check by
	   # creating a dummy sequence object
	   eval {
	       require Bio::PrimarySeq;
	       my $seq = Bio::PrimarySeq->new('-verbose' => $self->verbose,
					      '-alphabet' => $value);
		
	   };
	   if ($@) {
	       $self->throw("Invalid alphabet: $value\n. See Bio::PrimarySeq for allowed values.");
	   }
	   $valid_alphabet_cache{$value} = 1;
       }
       $self->{'alphabet'} = $value;
   }
   return $self->{'alphabet'};
}

#line 529

sub _load_format_module {
    my ($self, $format) = @_;
    my $module = "Bio::SeqIO::" . $format;
    my $ok;

    eval {
	$ok = $self->_load_module($module);
    };
    if ( $@ ) {
    print STDERR <<END;
$self: $format cannot be found
Exception $@
For more information about the SeqIO system please see the SeqIO docs.
This includes ways of checking for formats at compile time, not run time
END
  ;
  }
  return $ok;
}

#line 564

sub _concatenate_lines {
    my ($self, $s1, $s2) = @_;

    $s1 .= " " if($s1 && ($s1 !~ /-$/) && $s2);
    return ($s1 ? $s1 : "") . ($s2 ? $s2 : "");
}

#line 583

sub _filehandle {
    my ($self,@args) = @_;
    return $self->_fh(@args);
}

#line 602

sub _guess_format {
   my $class = shift;
   return unless $_ = shift;
   return 'fasta'   if /\.(fasta|fast|seq|fa|fsa|nt|aa)$/i;
   return 'genbank' if /\.(gb|gbank|genbank|gbk|gbs)$/i;
   return 'scf'     if /\.scf$/i;
   return 'scf'     if /\.scf$/i;
   return 'abi'     if /\.abi$/i;
   return 'alf'     if /\.alf$/i;
   return 'ctf'     if /\.ctf$/i;
   return 'ztr'     if /\.ztr$/i;
   return 'pln'     if /\.pln$/i;
   return 'exp'     if /\.exp$/i;
   return 'pir'     if /\.pir$/i;
   return 'embl'    if /\.(embl|ebl|emb|dat)$/i;
   return 'raw'     if /\.(txt)$/i;
   return 'gcg'     if /\.gcg$/i;
   return 'ace'     if /\.ace$/i;
   return 'bsml'    if /\.(bsm|bsml)$/i;
   return 'swiss'   if /\.(swiss|sp)$/i;
   return 'phd'     if /\.(phd|phred)$/i;
   return 'fastq'   if /\.fastq$/i;
}

sub DESTROY {
    my $self = shift;

    $self->close();
}

sub TIEHANDLE {
    my ($class,$val) = @_;
    return bless {'seqio' => $val}, $class;
}

sub READLINE {
  my $self = shift;
  return $self->{'seqio'}->next_seq() unless wantarray;
  my (@list, $obj);
  push @list, $obj while $obj = $self->{'seqio'}->next_seq();
  return @list;
}

sub PRINT {
  my $self = shift;
  $self->{'seqio'}->write_seq(@_);
}

#line 661

sub sequence_factory{
   my ($self,$obj) = @_;   
   if( defined $obj ) {
       if( ! ref($obj) || ! $obj->isa('Bio::Factory::SequenceFactoryI') ) {
	   $self->throw("Must provide a valid Bio::Factory::SequenceFactoryI object to ".ref($self)."::sequence_factory()");
       }
       $self->{'_seqio_seqfactory'} = $obj;
       my $builder = $self->sequence_builder();
       if($builder && $builder->can('sequence_factory') &&
	  (! $builder->sequence_factory())) {
	   $builder->sequence_factory($obj);
       }
   }
   $self->{'_seqio_seqfactory'};
}

#line 689

sub object_factory{
    return shift->sequence_factory(@_);
}

#line 710

sub sequence_builder{
    my ($self,$obj) = @_;
    if( defined $obj ) {
	if( ! ref($obj) || ! $obj->isa('Bio::Factory::ObjectBuilderI') ) {
	    $self->throw("Must provide a valid Bio::Factory::ObjectBuilderI object to ".ref($self)."::sequence_builder()");
	}
	$self->{'_object_builder'} = $obj;
    }
    $self->{'_object_builder'};
}

#line 734

sub location_factory{
    my ($self,$obj) = @_;   
    if( defined $obj ) {
	if( ! ref($obj) || ! $obj->isa('Bio::Factory::LocationFactoryI') ) {
	    $self->throw("Must provide a valid Bio::Factory::LocationFactoryI".
			 " object to ".ref($self)."->location_factory()");
	}
	$self->{'_seqio_locfactory'} = $obj;
    }
    $self->{'_seqio_locfactory'};
}

1;

