#line 1 "Bio/SeqIO/alf.pm"
# $Id: alf.pm,v 1.7 2002/10/22 07:38:42 lapp Exp $
# BioPerl module for Bio::SeqIO::alf
#
# Cared for by Aaron Mackey <amackey@virginia.edu>
#
# Copyright Aaron Mackey
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 55

# Let the code begin...

package Bio::SeqIO::alf;
use vars qw(@ISA $READ_AVAIL);
use strict;
# Object preamble - inherits from Bio::Root::Object

use Bio::SeqIO;
use Bio::Seq::SeqFactory;

push @ISA, qw( Bio::SeqIO );

sub BEGIN {
    eval { require Bio::SeqIO::staden::read; };
    if ($@) {
	$READ_AVAIL = 0;
    } else {
	push @ISA, "Bio::SeqIO::staden::read";
	$READ_AVAIL = 1;
    }
}

sub _initialize {
  my($self,@args) = @_;
  $self->SUPER::_initialize(@args);  
  if( ! defined $self->sequence_factory ) {
      $self->sequence_factory(new Bio::Seq::SeqFactory(-verbose => $self->verbose(), -type => 'Bio::Seq'));      
  }
  unless ($READ_AVAIL) {
      Bio::Root::Root->throw( -class => 'Bio::Root::SystemException',
			      -text  => "Bio::SeqIO::staden::read is not available; make sure the bioperl-ext package has been installed successfully!"
			    );
  }
}

#line 100

sub next_seq {

    my ($self) = @_;

    my ($seq, $id, $desc, $qual) = $self->read_trace($self->_fh, 'alf');

    # create the seq object
    $seq = $self->sequence_factory->create(-seq        => $seq,
					   -id         => $id,
					   -primary_id => $id,
					   -desc       => $desc,
					   -alphabet   => 'DNA',
					   -qual       => $qual
					   );
    return $seq;
}

#line 128

sub write_seq {
    my ($self,@seq) = @_;

    my $fh = $self->_fh;
    foreach my $seq (@seq) {
	$self->write_trace($fh, $seq, 'alf');
    }

    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

1;
