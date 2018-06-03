#line 1 "Bio/SeqIO/raw.pm"
#-----------------------------------------------------------------------------
# PACKAGE : Bio::SeqIO::raw
# AUTHOR  : Ewan Birney <birney@ebi.ac.uk>
# CREATED : Feb 16 1999
# REVISION: $Id: raw.pm,v 1.15.2.1 2003/02/05 21:55:21 jason Exp $
#            
# Copyright (c) 1997-9 bioperl, Ewan Birney. All Rights Reserved.
#           This module is free software; you can redistribute it and/or 
#           modify it under the same terms as Perl itself.
#
# _History_
#
# Ewan Birney <birney@ebi.ac.uk> developed the SeqIO 
# schema and the first prototype modules.
#
# This code is based on his Bio::SeqIO::Fasta module with
# the necessary minor tweaks necessary to get it to read
# and write raw formatted sequences made by
# chris dagdigian <dag@sonsorol.org>
#
# October 18, 1999  Largely rewritten by Lincoln Stein
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 79


# Let the code begin...

package Bio::SeqIO::raw;
use strict;
use vars qw(@ISA);

use Bio::SeqIO;
use Bio::Seq::SeqFactory;

@ISA = qw(Bio::SeqIO);

sub _initialize {
  my($self,@args) = @_;
  $self->SUPER::_initialize(@args);    
  if( ! defined $self->sequence_factory ) {
      $self->sequence_factory(new Bio::Seq::SeqFactory
			      (-verbose => $self->verbose(), 
			       -type => 'Bio::Seq'));      
  }
}

#line 112

sub next_seq{
   my ($self,@args) = @_;
   ## When its 1 sequence per line with no formatting at all,
   ## grabbing it should be easy :)

   my $nextline = $self->_readline();
   if( !defined $nextline ){ return undef; }

   my $sequence = uc($nextline);
   $sequence =~ s/\W//g;

   return  $self->sequence_factory->create(-seq => $sequence);
}

#line 137

sub write_seq {
   my ($self,@seq) = @_;
   foreach my $seq (@seq) {
       $self->throw("Must provide a valid Bio::PrimarySeqI object") 
	   unless defined $seq && ref($seq) && $seq->isa('Bio::PrimarySeqI');
     $self->_print($seq->seq, "\n") or return;
   }
   $self->flush if $self->_flush_on_write && defined $self->_fh;
   return 1;
}

#line 159

sub write_qual {
   my ($self,@seq) = @_;
   my @qual = ();
   foreach (@seq) {
     unless ($_->isa("Bio::Seq::SeqWithQuality")){
        warn("You cannot write raw qualities without supplying a Bio::Seq::SeqWithQuality object! You passed a ", ref($_), "\n");
        next;
     } 
     @qual = @{$_->qual};
     if(scalar(@qual) == 0) {
	    $qual[0] = "\n";
     }
     
     $self->_print (join " ", @qual,"\n") or return;

   }
   return 1;
}
1;
