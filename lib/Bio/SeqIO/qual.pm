#line 1 "Bio/SeqIO/qual.pm"
# $Id: qual.pm,v 1.22 2002/12/27 19:42:32 birney Exp $
#
# Copyright (c) 1997-9 bioperl, Chad Matsalla. All Rights Reserved.
#           This module is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
#
# Copyright Chad Matsalla
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 63

# Let the code begin...

package Bio::SeqIO::qual;
use vars qw(@ISA);
use strict;
use Bio::SeqIO;
use Bio::Seq::SeqFactory;
require 'dumpvar.pl';

@ISA = qw(Bio::SeqIO);


sub _initialize {
  my($self,@args) = @_;
  $self->SUPER::_initialize(@args);    
  if( ! defined $self->sequence_factory ) {
      $self->sequence_factory(new Bio::Seq::SeqFactory
			      (-verbose => $self->verbose(), 
			       -type => 'Bio::Seq::PrimaryQual'));      
  }
}

#line 95

sub next_seq {
    my ($self,@args) = @_;
    my ($qual,$seq);
    my $alphabet;
    local $/ = "\n>";

    return unless my $entry = $self->_readline;

    if ($entry eq '>')  {	# very first one
	return unless $entry = $self->_readline;
    }

    # original: my ($top,$sequence) = $entry =~ /^(.+?)\n([^>]*)/s
    my ($top,$sequence) = $entry =~ /^(.+?)\n([^>]*)/s
	or $self->throw("Can't parse entry [$entry]");
    my ($id,$fulldesc) = $top =~ /^\s*(\S+)\s*(.*)/
	or $self->throw("Can't parse fasta header");
    $id =~ s/^>//;
    # create the seq object
    $sequence =~ s/\n+/ /g;
    return $self->sequence_factory->create
	(-qual        => $sequence,
	 -id         => $id,
	 -primary_id => $id,
	 -display_id => $id,
	 -desc       => $fulldesc
	 );
}

#line 137

sub _next_qual {
	my $qual = next_primary_qual( $_[0], 1 );
	return $qual;    
}

#line 152

sub next_primary_qual {
	# print("CSM next_primary_qual!\n");
  my( $self, $as_next_qual ) = @_;
  my ($qual,$seq);
  local $/ = "\n>";

  return unless my $entry = $self->_readline;

  if ($entry eq '>')  {  # very first one
    return unless $entry = $self->_readline;
  }
  
  my ($top,$sequence) = $entry =~ /^(.+?)\n([^>]*)/s
      or $self->throw("Can't parse entry [$entry]");
  my ($id,$fulldesc) = $top =~ /^\s*(\S+)\s*(.*)/
      or $self->throw("Can't parse fasta header");
  $id =~ s/^>//;
  # create the seq object
  $sequence =~ s/\n+/ /g;
  if ($as_next_qual) {
      $qual = Bio::Seq::PrimaryQual->new(-qual        => $sequence,
					 -id         => $id,
					 -primary_id => $id,
					 -display_id => $id,
					 -desc       => $fulldesc
					 );
  }
  return $qual;
}

#line 201

sub write_seq {
    my ($self,@args) = @_;
    my ($source)  = $self->_rearrange([qw(SOURCE)], @args);

    if (!$source || ( !$source->isa('Bio::Seq::SeqWithQuality') && 
		      !$source->isa('Bio::Seq::PrimaryQual')   )) {
	$self->throw("You must pass a Bio::Seq::SeqWithQuality or a Bio::Seq::PrimaryQual object to write_seq as a parameter named \"source\"");
    }
    my $header = $source->id();
    if (!$header) { $header = "unknown"; }
    my @quals = $source->qual();
    # ::dumpValue(\@quals);
    $self->_print (">$header \n");
    my (@slice,$max,$length);
    $length = $source->length();
    if ($length eq "DIFFERENT") {
	$self->warn("You passed a SeqWithQuality object that contains a sequence and quality of differing lengths. Using the length of the PrimaryQual component of the SeqWithQuality object.");
	$length = $source->qual_obj()->length();
    }
    # print("Printing $header to a file.\n");
    for (my $count = 1; $count<=$length; $count+= 50) {
	if ($count+50 > $length) { $max = $length; }
	else { $max = $count+49; }
	my @slice = @{$source->subqual($count,$max)};
	$self->_print (join(' ',@slice), "\n");
    }

    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}


1;
__END__
