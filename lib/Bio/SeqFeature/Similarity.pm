#line 1 "Bio/SeqFeature/Similarity.pm"
# $Id: Similarity.pm,v 1.10 2002/11/01 21:39:05 jason Exp $
#
# BioPerl module for Bio::SeqFeature::Similarity
#
# Cared for by Hilmar Lapp <hlapp@gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 64


# Let the code begin...


package Bio::SeqFeature::Similarity;
use vars qw(@ISA);
use strict;

use Bio::SeqFeature::Generic;

@ISA = qw(Bio::SeqFeature::Generic);

sub new {
    my ( $caller, @args) = @_;   
    my ($self) = $caller->SUPER::new(@args); 

    my ($primary,$evalue, $bits, $frac,$seqlen,$seqdesc) =
	$self->_rearrange([qw(PRIMARY
			      EXPECT
			      BITS
			      FRAC
			      SEQDESC
			      SEQLENGTH				      
			      )],@args);

    defined $evalue && $self->significance($evalue);
    defined $bits   && $self->bits($bits);
    defined $frac   && $self->frac_identical($frac);
    defined $seqlen && $self->seqlength($seqlen);
    defined $seqdesc && $self->seqdesc($seqdesc);
    $primary  = 'similarity' unless defined $primary;
    $self->primary_tag($primary) unless( defined $self->primary_tag() );
    $self->strand(0) unless( defined $self->strand() );

    return $self;
}

#line 113

sub significance {
    my ($self, $value) = @_;

    return $self->_tag_value('signif', $value);
}

#line 131

sub bits {
    my ($self, $value) = @_;

    return $self->_tag_value('Bits', $value);
}

#line 149

sub frac_identical {
    my ($self, $value) = @_;

    return $self->_tag_value('FracId', $value);
}

#line 167

sub seqlength {
    my ($self, $value) = @_;

    return $self->_tag_value('SeqLength', $value);
}

#line 189

sub seqdesc {
    my ($self, $value) = @_;

    if( defined $value ) { 
	my $v = Bio::Annotation::SimpleValue->new();
	$v->value($value);
	$self->annotation->add_Annotation('description',$v);
    }
    my ($v) = $self->annotation()->get_Annotations('description');
    return $v ? $v->value : undef;
}

#
# Everything else is just inherited from SeqFeature::Generic.
#

1;
