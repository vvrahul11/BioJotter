#line 1 "Bio/Seq.pm"
# $Id: Seq.pm,v 1.76.2.2 2003/07/03 20:01:32 jason Exp $
#
# BioPerl module for Bio::Seq
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 442

#'
# Let the code begin...


package Bio::Seq;
use vars qw(@ISA $VERSION);
use strict;


# Object preamble - inherits from Bio::Root::Object

use Bio::Root::Root;
use Bio::SeqI;
use Bio::Annotation::Collection;
use Bio::PrimarySeq;
use Bio::IdentifiableI;
use Bio::DescribableI;
use Bio::AnnotatableI;
use Bio::FeatureHolderI;

$VERSION = '1.1';
@ISA = qw(Bio::Root::Root Bio::SeqI
	  Bio::IdentifiableI Bio::DescribableI
	  Bio::AnnotatableI Bio::FeatureHolderI);

#line 482

sub new {
    my($caller,@args) = @_;

    if( $caller ne 'Bio::Seq') {
	$caller = ref($caller) if ref($caller);
    }

    # we know our inherietance heirarchy
    my $self = Bio::Root::Root->new(@args);
    bless $self,$caller;

    # this is way too sneaky probably. We delegate the construction of
    # the Seq object onto PrimarySeq and then pop primary_seq into
    # our primary_seq slot

    my $pseq = Bio::PrimarySeq->new(@args);

    # as we have just made this, we know it is ok to set hash directly
    # rather than going through the method

    $self->{'primary_seq'} = $pseq;

    # setting this array is now delayed until the final
    # moment, again speed ups for non feature containing things
    # $self->{'_as_feat'} = [];


    my ($ann, $pid,$feat,$species) = &Bio::Root::RootI::_rearrange($self,[qw(ANNOTATION PRIMARY_ID FEATURES SPECIES)], @args);

    # for a number of cases - reading fasta files - these are never set. This
    # gives a quick optimisation around testing things later on

    if( defined $ann || defined $pid || defined $feat || defined $species ) {
	$pid && $self->primary_id($pid);
	$species && $self->species($species);
	$ann && $self->annotation($ann);
	
	if( defined $feat ) {
	    if( ref($feat) !~ /ARRAY/i ) {
		if( ref($feat) && $feat->isa('Bio::SeqFeatureI') ) {
		    $self->add_SeqFeature($feat);
		} else {
		    $self->warn("Must specify a valid Bio::SeqFeatureI or ArrayRef of Bio::SeqFeatureI's with the -features init parameter for ".ref($self));
		}
	    } else {
		foreach my $feature ( @$feat ) {
		    $self->add_SeqFeature($feature);
		}	
	    }
	}
    }

    return $self;
}

#line 550

#line 568

sub seq {
    return shift->primary_seq()->seq(@_);
}

#line 594

sub validate_seq {
    return shift->primary_seq()->validate_seq(@_);
}

#line 609

sub length {
    return shift->primary_seq()->length(@_);
}

#line 617

#line 633

sub subseq {
    return shift->primary_seq()->subseq(@_);
}

#line 663

sub display_id {
   return shift->primary_seq->display_id(@_);
}



#line 691

sub accession_number {
   return shift->primary_seq->accession_number(@_);
}

#line 707

sub desc {
   return shift->primary_seq->desc(@_);
}

#line 737

sub primary_id {
   my ($obj,$value) = @_;

   if( defined $value) {
      $obj->{'primary_id'} = $value;
    }
   if( ! exists $obj->{'primary_id'} ) {
       return "$obj";
   }
   return $obj->{'primary_id'};
}

#line 773

sub can_call_new {
    return 1;
}

#line 795

sub alphabet {
   my $self = shift;
   return $self->primary_seq->alphabet(@_) if @_ && defined $_[0];
   return $self->primary_seq->alphabet();
}

sub is_circular { shift->primary_seq->is_circular }

#line 807

#line 821

sub object_id {
    return shift->accession_number(@_);
}

#line 838

sub version{
    return shift->primary_seq->version(@_);
}


#line 855

sub authority {
    return shift->primary_seq()->authority(@_);
}

#line 872

sub namespace{
    return shift->primary_seq()->namespace(@_);
}

#line 880

#line 895

sub display_name {
    return shift->display_id(@_);
}

#line 915

sub description {
    return shift->desc(@_);
}

#line 923

#line 936

sub annotation {
    my ($obj,$value) = @_;
    if( defined $value ) {
	$obj->throw("object of class ".ref($value)." does not implement ".
		    "Bio::AnnotationCollectionI. Too bad.")
	    unless $value->isa("Bio::AnnotationCollectionI");
	$obj->{'_annotation'} = $value;
    } elsif( ! defined $obj->{'_annotation'}) {
	$obj->{'_annotation'} = new Bio::Annotation::Collection;
    }
    return $obj->{'_annotation'};
}

#line 955

#line 979

sub get_SeqFeatures{
   my $self = shift;

   if( !defined $self->{'_as_feat'} ) {
       $self->{'_as_feat'} = [];
   }

   return @{$self->{'_as_feat'}};
}

#line 1008

# this implementation is inherited from FeatureHolderI

#line 1021

sub feature_count {
    my ($self) = @_;

    if (defined($self->{'_as_feat'})) {
	return ($#{$self->{'_as_feat'}} + 1);
    } else {
	return 0;
    }
}

#line 1046

sub add_SeqFeature {
   my ($self,@feat) = @_;

   $self->{'_as_feat'} = [] unless $self->{'_as_feat'};

   foreach my $feat ( @feat ) {
       if( !$feat->isa("Bio::SeqFeatureI") ) {
	   $self->throw("$feat is not a SeqFeatureI and that's what we expect...");
       }

       # make sure we attach ourselves to the feature if the feature wants it
       my $aseq = $self->primary_seq;
       $feat->attach_seq($aseq) if $aseq;

       push(@{$self->{'_as_feat'}},$feat);
   }
   return 1;
}

#line 1080

sub remove_SeqFeatures {
    my $self = shift;

    return () unless $self->{'_as_feat'};
    my @feats = @{$self->{'_as_feat'}};
    $self->{'_as_feat'} = [];
    return @feats;
}

#line 1129

#line 1142

#line 1153

sub  id {
    return shift->display_id(@_);
}


#line 1176

sub primary_seq {
   my ($obj,$value) = @_;

   if( defined $value) {
       if( ! ref $value || ! $value->isa('Bio::PrimarySeqI') ) {
	   $obj->throw("$value is not a Bio::PrimarySeq compliant object");
       }

       $obj->{'primary_seq'} = $value;
       # descend down over all seqfeature objects, seeing whether they
       # want an attached seq.

       foreach my $sf ( $obj->get_SeqFeatures() ) {
	   $sf->attach_seq($value);
       }

   }
   return $obj->{'primary_seq'};

}

#line 1209

sub species {
    my ($self, $species) = @_;
    if ($species) {
        $self->{'species'} = $species;
    } else {
        return $self->{'species'};
    }
}

#line 1222

# keep AUTOLOAD happy
sub DESTROY { }

############################################################################
# aliases due to name changes or to compensate for our lack of consistency #
############################################################################

# in all other modules we use the object in the singular --
# lack of consistency sucks
*flush_SeqFeature = \&remove_SeqFeatures;
*flush_SeqFeatures = \&remove_SeqFeatures;

# this is now get_SeqFeatures() (from FeatureHolderI)
*top_SeqFeatures = \&get_SeqFeatures;

# this is now get_all_SeqFeatures() in FeatureHolderI
sub all_SeqFeatures{
    return shift->get_all_SeqFeatures(@_);
}

sub accession {
    my $self = shift;
    $self->warn(ref($self)."::accession is deprecated, ".
		"use accession_number() instead");
    return $self->accession_number(@_);
}

1;
