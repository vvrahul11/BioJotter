#line 1 "Bio/SeqIO/MultiFile.pm"
# $Id: MultiFile.pm,v 1.8 2002/10/22 07:38:42 lapp Exp $
#
# BioPerl module for Bio::SeqIO::MultiFile
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 62


# Let the code begin...


package Bio::SeqIO::MultiFile;
use strict;
use vars qw(@ISA);
use Bio::SeqIO;

@ISA = qw(Bio::SeqIO);


# _initialize is where the heavy stuff will happen when new is called

sub _initialize {
  my($self,@args) = @_;

  $self->SUPER::_initialize(@args);

  my ($file_array,$format) = $self->_rearrange([qw(
					 FILES
					 FORMAT
					)],
				     @args,
				     );
  if( !defined $file_array || ! ref $file_array ) {
      $self->throw("Must have an array files for MultiFile");
  }

  if( !defined $format ) {
      $self->throw("Must have a format for MultiFile");
  }

  $self->{'_file_array'} = [];

  $self->_set_file(@$file_array);
  $self->_format($format);
  if( $self->_load_file() == 0 ) {
     $self->throw("Unable even to initialise the first file");
  }
}

#line 116

sub next_seq{
   my ($self,@args) = @_;

   my $seq = $self->_current_seqio->next_seq();
   if( !defined $seq ) {
       if( $self->_load_file() == 0) {
	   return undef;
       } else {
	   return $self->next_seq();
       }
   } else {
       return $seq;
   }
   
}

#line 144

sub next_primary_seq{
   my ($self,@args) = @_;

   my $seq = $self->_current_seqio->next_primary_seq();
   if( !defined $seq ) {
       if( $self->_load_file() == 0) {
	   return undef;
       } else {
	   return $self->next_primary_seq();
       }
   } else {
       return $seq;
   }

}

#line 172

sub _load_file{
   my ($self,@args) = @_;

   my $file = shift(@{$self->{'_file_array'}});
   if( !defined $file ) {
       return 0;
   }
   my $seqio = Bio::SeqIO->new( '-format' => $self->_format(), -file => $file);
   # should throw an exception - but if not...
   if( !defined $seqio) {
       $self->throw("no seqio built for $file!");
   }

   $self->_current_seqio($seqio);
   return 1;
}

#line 201

sub _set_file{
   my ($self,@files) = @_;

   push(@{$self->{'_file_array'}},@files);
   
}

#line 220

sub _current_seqio{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_current_seqio'} = $value;
    }
    return $obj->{'_current_seqio'};

}

#line 241

sub _format{
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'_format'} = $value;
    }
    return $obj->{'_format'};

}

1;
