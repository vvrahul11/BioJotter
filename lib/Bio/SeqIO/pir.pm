#line 1 "Bio/SeqIO/pir.pm"
# $Id: pir.pm,v 1.18 2002/10/25 16:23:16 jason Exp $
#
# BioPerl module for Bio::SeqIO::PIR
#
# Cared for by Aaron Mackey <amackey@virginia.edu>
#
# Copyright Aaron Mackey
#
# You may distribute this module under the same terms as perl itself
#
# _history
# October 18, 1999  Largely rewritten by Lincoln Stein

# POD documentation - main docs before the code

#line 66

# Let the code begin...

package Bio::SeqIO::pir;
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
			       -type => 'Bio::Seq'));      
  }
}

#line 97

sub next_seq {
    my ($self) = @_;
    local $/ = "\n>";
    return unless my $line = $self->_readline;
    if( $line eq '>' ) {	# handle the very first one having no comment
	return unless $line = $self->_readline;
    }
    my ($top, $desc,$seq) = ( $line =~ /^(.+?)\n(.+?)\n([^>]*)/s )  or
	$self->throw("Cannot parse entry PIR entry [$line]");


    my ( $type,$id ) = ( $top =~ /^>?([PF])1;(\S+)\s*$/ ) or
	$self->throw("PIR stream read attempted without leading '>P1;' [ $line ]");

    # P - indicates complete protein
    # F - indicates protein fragment
    # not sure how to stuff these into a Bio object 
    # suitable for writing out.
    $seq =~ s/\*//g;
    $seq =~ s/[\(\)\.\/\=\,]//g;
    $seq =~ s/\s+//g;		# get rid of whitespace

    my ($alphabet) = ('protein');
    # TODO - not processing SFS data
    return $self->sequence_factory->create
	(-seq        => $seq,
	 -primary_id => $id,
	 -id         => $type. '1;' . $id,
	 -desc       => $desc,
	 -alphabet    => $alphabet
	 );
}

#line 141

sub write_seq {
    my ($self, @seq) = @_;
    for my $seq (@seq) {
	$self->throw("Did not provide a valid Bio::PrimarySeqI object") 
	    unless defined $seq && ref($seq) && $seq->isa('Bio::PrimarySeqI');
	my $str = $seq->seq();
	return unless $self->_print(">".$seq->id(), 
				    "\n", $seq->desc(), "\n", 
				    $str, "*\n");
    }

    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

1;
