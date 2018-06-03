#line 1 "Bio/SeqI.pm"
# $Id: SeqI.pm,v 1.25 2002/12/05 13:46:30 heikki Exp $
#
# BioPerl module for Bio::SeqI
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 97

#'
# Let the code begin...


package Bio::SeqI;
use strict;

use vars qw(@ISA);
use Bio::PrimarySeqI;
use Bio::AnnotatableI;
use Bio::FeatureHolderI;

# Object preamble - inheriets from Bio::PrimarySeqI

@ISA = qw(Bio::PrimarySeqI Bio::AnnotatableI Bio::FeatureHolderI);

#line 126

#line 139

#line 152

#line 163

sub seq{
   my ($self) = @_;
   $self->throw_not_implemented();
}

#line 180

sub write_GFF{
   my ($self,$fh) = @_;

   $fh || do { $fh = \*STDOUT; };

   foreach my $sf ( $self->get_all_SeqFeatures() ) {
       print $fh $sf->gff_string, "\n";
   }

}

#line 204

#line 217

sub species {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 237

sub primary_seq {
    my ($self) = @_;
    $self->throw_not_implemented;
}

1;
