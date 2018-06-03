#line 1 "Bio/SeqIO/ztr.pm"
# $Id: ztr.pm,v 1.8 2002/10/22 07:38:42 lapp Exp $
# BioPerl module for Bio::SeqIO::ztr
#
# Cared for by Aaron Mackey <amackey@virginia.edu>
#
# Copyright Aaron Mackey
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 55

# Let the code begin...

package Bio::SeqIO::ztr;
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
      $self->sequence_factory(new Bio::Seq::SeqFactory(-verbose => $self->verbose(), -type => 'Bio::Seq::SeqWithQuality'));      
  }

  my ($compression) = $self->_rearrange([qw[COMPRESSION]], @args);
  $compression = 2 unless defined $compression;
  $self->compression($compression);

  unless ($READ_AVAIL) {
      Bio::Root::Root->throw( -class => 'Bio::Root::SystemException',
			      -text  => "Bio::SeqIO::staden::read is not available; make sure the bioperl-ext package has been installed successfully!"
			    );
  }
}

#line 105

sub next_seq {

    my ($self) = @_;

    my ($seq, $id, $desc, $qual) = $self->read_trace($self->_fh, 'ztr');

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

#line 133

sub write_seq {
    my ($self,@seq) = @_;

    my $fh = $self->_fh;
    foreach my $seq (@seq) {
	$self->write_trace($fh, $seq, 'ztr' . $self->compression);
    }

    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

#line 157

sub compression {

    my ($self, $val) = @_;

    if (defined $val) {
	if ($val =~ m/^1|2|3$/o) {
	    $self->{_compression} = $val;
	} else {
	    $self->{_compression} = 2;
	}
    }

    return $self->{_compression};
}

1;
