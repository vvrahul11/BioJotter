#line 1 "Bio/SeqIO/phd.pm"
# $Id: phd.pm,v 1.17 2002/12/09 23:50:23 matsallac Exp $
#
# Copyright (c) 1997-2001 bioperl, Chad Matsalla. All Rights Reserved.
#           This module is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
#
# Copyright Chad Matsalla
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 61

# 'Let the code begin...

package Bio::SeqIO::phd;
use vars qw(@ISA);
use strict;
use Bio::SeqIO;
use Bio::Seq::SeqFactory;

@ISA = qw(Bio::SeqIO);

sub _initialize {
  my($self,@args) = @_;
  $self->SUPER::_initialize(@args);    
  if( ! defined $self->sequence_factory ) {
      $self->sequence_factory(new Bio::Seq::SeqFactory
			      (-verbose => $self->verbose(), 
			       -type => 'Bio::Seq::SeqWithQuality'));      
  }
}

#line 94

sub next_seq {
    my ($self,@args) = @_;
    my ($entry,$done,$qual,$seq);
    my ($id,@lines, @bases, @qualities) = ('');
    if (!($entry = $self->_readline)) { return; }
	if ($entry =~ /^BEGIN_SEQUENCE\s+(\S+)/) {
          $id = $1;
     }
    my $in_dna = 0;
    my $base_number = 0;
    while ($entry = $self->_readline) {
	return if (!$entry);
	chomp($entry);
	if ($entry =~ /^BEGIN_CHROMAT:\s+(\S+)/) {
	     # this is where I used to grab the ID
          if (!$id) {
               $id = $1; 
          }
          $entry = $self->_readline();
	}
	if ($entry =~ /^BEGIN_DNA/) {
	    $entry =~ /^BEGIN_DNA/;
	    $in_dna = 1;
	    $entry = $self->_readline();
	}
	if ($entry =~ /^END_DNA/) {
	    $in_dna = 0;
	}
	if ($entry =~ /^END_SEQUENCE/) {
	}
	if (!$in_dna) { next;  }
	$entry =~ /(\S+)\s+(\S+)/;
	push @bases,$1;
	push @qualities,$2;
	push(@lines,$entry);
    }
     # $self->debug("csmCreating objects with id = $id\n");
    my $swq = $self->sequence_factory->create
	(-seq        => join('',@bases),
	 -qual       => \@qualities,
	 -id         => $id,
	 -primary_id => $id,
	 -display_id => $id,
	 );
    return $swq;
}

#line 170

sub write_seq {
    my ($self,@args) = @_;
    my @phredstack;
    my ($label,$arg);

    my ($swq, $chromatfile, $abithumb, 
	$phredversion, $callmethod,
	$qualitylevels,$time,
	$trace_min_index,
	$trace_max_index,
	$chem, $dye
	) = $self->_rearrange([qw(SEQWITHQUALITY
				  CHROMAT_FILE
				  ABI_THUMBPRINT
				  PHRED_VERSION
				  CALL_METHOD
				  QUALITY_LEVELS
				  TIME
				  TRACE_ARRAY_MIN_INDEX
				  TRACE_ARRAY_MAX_INDEX
				  CHEM
				  DYE
				  )], @args);

    unless (ref($swq) eq "Bio::Seq::SeqWithQuality") {
	$self->throw("You must pass a Bio::Seq::SeqWithQuality object to write_scf as a parameter named \"SeqWithQuality\"");
    }
    my $id = $swq->id();
    if (!$id) { $id = "UNDEFINED in SeqWithQuality Object"; }
    push @phredstack,("BEGIN_SEQUENCE $id","","BEGIN_COMMENT","");

    $chromatfile = 'undefined in write_phd' unless defined $chromatfile;
    push @phredstack,"CHROMAT_FILE: $chromatfile"; 

    $abithumb = 0 unless defined $abithumb;
    push @phredstack,"ABI_THUMBPRINT: $abithumb"; 

    $phredversion = "0.980904.e" unless defined $phredversion;
    push @phredstack,"PHRED_VERSION: $phredversion"; 

    $callmethod = 'phred' unless defined $callmethod;
    push @phredstack,"CALL_METHOD: $callmethod"; 

    $qualitylevels = 99 unless defined $qualitylevels;
    push @phredstack,"QUALITY_LEVELS: $qualitylevels"; 

    $time = localtime() unless defined $time;
    push @phredstack,"TIME: $time"; 

    $trace_min_index = 0 unless defined $trace_min_index;
    push @phredstack,"TRACE_ARRAY_MIN_INDEX: $trace_min_index";

    $trace_max_index = '10000'  unless defined $trace_max_index;
    push @phredstack,"TRACE_ARRAY_MAX_INDEX: $trace_max_index";

    $chem = 'unknown' unless defined $chem;
    push @phredstack,"CHEM: $chem";

    $dye = 'unknown' unless defined $dye;
    push @phredstack, "DYE: $dye";

    push @phredstack,("END_COMMENT","","BEGIN_DNA");

    foreach (@phredstack) {  $self->_print($_."\n"); }

    my $length = $swq->length();
    if ($length eq "DIFFERENT") {
	$self->throw("Can't create the phd because the sequence and the quality in the SeqWithQuality object are of different lengths.");
    }
    for (my $curr = 1; $curr<=$length; $curr++) {
	$self->_print (uc($swq->baseat($curr))." ".
		       $swq->qualat($curr)." 10".
               "\n");
    }
    $self->_print ("END_DNA\n\nEND_SEQUENCE\n");

    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

1;
__END__
