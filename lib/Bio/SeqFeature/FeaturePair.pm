#line 1 "Bio/SeqFeature/FeaturePair.pm"
# $Id: FeaturePair.pm,v 1.17 2002/10/08 08:38:31 lapp Exp $
#
# BioPerl module for Bio::SeqFeature::FeaturePair
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 84


# Let the code begin...


package Bio::SeqFeature::FeaturePair;
use vars qw(@ISA);
use strict;

use Bio::SeqFeatureI;
use Bio::SeqFeature::Generic;

@ISA = qw(Bio::SeqFeature::Generic);

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    
    my ($feature1,$feature2) = 
	$self->_rearrange([qw(FEATURE1
			      FEATURE2
			      )],@args);
    
    # Store the features in the object
    $feature1 && $self->feature1($feature1);
    $feature2 && $self->feature2($feature2);
    return $self;
}

#line 124

sub feature1 {
    my ($self,$arg) = @_;    
    if ( defined($arg) || !defined $self->{'feature1'} ) {
	$arg = new Bio::SeqFeature::Generic() unless( defined $arg);
	$self->throw("Argument [$arg] must be a Bio::SeqFeatureI") 
	    unless (ref($arg) && $arg->isa("Bio::SeqFeatureI"));
	$self->{'feature1'} = $arg;
    }
    return $self->{'feature1'};
}

#line 147

sub feature2 {
    my ($self,$arg) = @_;

    if ( defined($arg) || ! defined $self->{'feature2'}) {
	$arg = new Bio::SeqFeature::Generic unless( defined $arg);
	$self->throw("Argument [$arg] must be a Bio::SeqFeatureI") 
	    unless (ref($arg) && $arg->isa("Bio::SeqFeatureI"));
	$self->{'feature2'} = $arg;
    }
    return $self->{'feature2'};
}

#line 170

sub start {
    my ($self,$value) = @_;    
    return $self->feature1->start($value);
}

#line 187

sub end{
    my ($self,$value) = @_;    
    return $self->feature1->end($value);    
}

#line 204

sub strand{
    my ($self,$arg) = @_;
    return $self->feature1->strand($arg);    
}

#line 220

sub location {
    my ($self,$value) = @_;    
    return $self->feature1->location($value);
}

#line 237

sub score {
    my ($self,$arg) = @_;
    return $self->feature1->score($arg);    
}

#line 254

sub frame {
    my ($self,$arg) = @_;
    return $self->feature1->frame($arg);    
}

#line 270

sub primary_tag{
    my ($self,$arg) = @_;
    return $self->feature1->primary_tag($arg);    
}

#line 288

sub source_tag{
    my ($self,$arg) = @_;
    return $self->feature1->source_tag($arg);    
}

#line 311

sub seqname{
    my ($self,$arg) = @_;
    return $self->feature1->seq_id($arg);    
}

#line 328

sub hseqname {
    my ($self,$arg) = @_;
    return $self->feature2->seq_id($arg);
}


#line 345

sub hstart {
    my ($self,$value) = @_;
    return $self->feature2->start($value);    
}

#line 362

sub hend{
    my ($self,$value) = @_;
    return $self->feature2->end($value);    
}


#line 380

sub hstrand{
    my ($self,$arg) = @_;
    return $self->feature2->strand($arg);
}

#line 397

sub hscore {
    my ($self,$arg) = @_;
    return $self->feature2->score($arg);    
}

#line 414

sub hframe {
    my ($self,$arg) = @_;
    return $self->feature2->frame($arg);    
}

#line 430

sub hprimary_tag{
    my ($self,$arg) = @_;
    return $self->feature2->primary_tag($arg);    
}

#line 448

sub hsource_tag{
    my ($self,$arg) = @_;
    return $self->feature2->source_tag($arg);
}

#line 464

sub invert {
    my ($self) = @_;

    my $tmp = $self->feature1;
    
    $self->feature1($self->feature2);
    $self->feature2($tmp);
    return undef;
}

1;
