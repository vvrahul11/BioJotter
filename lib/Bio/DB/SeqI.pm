#line 1 "Bio/DB/SeqI.pm"

#
# $Id: SeqI.pm,v 1.7 2002/10/22 07:38:29 lapp Exp $
#
# BioPerl module for Bio::DB::SeqI.pm
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 68


# Let the code begin...


package Bio::DB::SeqI;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Object

use Bio::DB::RandomAccessI;
@ISA = qw(Bio::DB::RandomAccessI);

#line 95

#line 107

#line 120

sub get_PrimarySeq_stream{
   my ($self,@args) = @_;

   $self->throw("Object did not provide a PrimarySeq stream object");
}

#line 143

sub get_all_primary_ids{
   my ($self,@args) = @_;
   $self->throw("Object did not provide a get_all_ids method");
}


#line 168

sub get_Seq_by_primary_id {
   my ($self,@args) = @_;

   $self->throw("Abstract database call of get_Seq_by_primary_id. Your database has not implemented this method!");

}

1;



