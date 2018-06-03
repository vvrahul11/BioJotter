#line 1 "Bio/SeqIO/largefasta.pm"
# $Id: largefasta.pm,v 1.18 2002/12/27 19:42:32 birney Exp $
# BioPerl module for Bio::SeqIO::largefasta
#
# Cared for by Jason Stajich
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself
# _history
# 
# POD documentation - main docs before the code

#line 71

# Let the code begin...

package Bio::SeqIO::largefasta;
use vars qw(@ISA $FASTALINELEN);
use strict;
# Object preamble - inherits from Bio::Root::Object

use Bio::SeqIO;
use Bio::Seq::SeqFactory;

$FASTALINELEN = 60;
@ISA = qw(Bio::SeqIO);

sub _initialize {
  my($self,@args) = @_;
  $self->SUPER::_initialize(@args);    
  if( ! defined $self->sequence_factory ) {
      $self->sequence_factory(new Bio::Seq::SeqFactory
			      (-verbose => $self->verbose(), 
			       -type => 'Bio::Seq::LargePrimarySeq'));      
  }
}

#line 104

sub next_seq {
    my ($self) = @_;
#  local $/ = "\n";
    my $largeseq = $self->sequence_factory->create();
    my ($id,$fulldesc,$entry);
    my $count = 0;
    my $seen = 0;
    while( defined ($entry = $self->_readline) ) {
	if( $seen == 1 && $entry =~ /^\s*>/ ) {
	    $self->_pushback($entry);
	    return $largeseq;
	}
#	if ( ($entry eq '>') || eof($self->_fh) ) { $seen = 1; next; }      
	if ( ($entry eq '>')  ) { $seen = 1; next; }      
	elsif( $entry =~ /\s*>(.+?)$/ ) {
	    $seen = 1;
	    ($id,$fulldesc) = ($1 =~ /^\s*(\S+)\s*(.*)$/)
		or $self->warn("Can't parse fasta header");
	    $largeseq->display_id($id);
	    $largeseq->primary_id($id);	  
	    $largeseq->desc($fulldesc);
	} else {
	    $entry =~ s/\s+//g;
	    $largeseq->add_sequence_as_string($entry);
	}
	(++$count % 1000 == 0 && $self->verbose() > 0) && print "line $count\n";
    }
    if( ! $seen ) { return undef; } 
    return $largeseq;
}

#line 146

sub write_seq {
   my ($self,@seq) = @_;
   foreach my $seq (@seq) {       
     my $top = $seq->id();
     if ($seq->can('desc') and my $desc = $seq->desc()) {
	 $desc =~ s/\n//g;
	 $top .= " $desc";
     }
     $self->_print (">",$top,"\n");
     my $end = $seq->length();
     my $start = 1;
     while( $start < $end ) {
	 my $stop = $start + $FASTALINELEN - 1;
	 $stop = $end if( $stop > $end );
	 $self->_print($seq->subseq($start,$stop), "\n");
	 $start += $FASTALINELEN;
     }
   }

   $self->flush if $self->_flush_on_write && defined $self->_fh;
   return 1;
}

1;
