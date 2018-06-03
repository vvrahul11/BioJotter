#line 1 "Bio/SeqIO/FTHelper.pm"
# $Id: FTHelper.pm,v 1.55 2002/11/05 02:55:12 lapp Exp $
#
# BioPerl module for Bio::SeqIO::FTHelper
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 65


# Let the code begin...


package Bio::SeqIO::FTHelper;
use vars qw(@ISA);
use strict;

use Bio::SeqFeature::Generic;
use Bio::Location::Simple;
use Bio::Location::Fuzzy;
use Bio::Location::Split;


use Bio::Root::Root;

@ISA = qw(Bio::Root::Root);

sub new {
    my ($class, @args) = @_;

    # no chained new because we make lots and lots of these. 
    my $self = {};
    bless $self,$class;
    $self->{'_field'} = {};
    return $self; 
}

#line 107

sub _generic_seqfeature {
    my ($fth, $locfac, $seqid, $source) = @_;
    my ($sf);

    # set a default if not specified
    if(! defined($source)) {
	$source = "EMBL/GenBank/SwissProt";
    }

    # initialize feature object
    $sf = Bio::SeqFeature::Generic->direct_new();

    # parse location; this may cause an exception, in which case we gently
    # recover and ignore this feature
    my $loc;
    eval {
	$loc = $locfac->from_string($fth->loc);
    };
    if(! $loc) {
	  $fth->warn("exception while parsing location line [" . $fth->loc .
		      "] in reading $source, ignoring feature " .
		      $fth->key() . " (seqid=" . $seqid . "): " . $@);
	  return;
    }
    
    # set additional location attributes
    if($seqid && (! $loc->is_remote())) {
	$loc->seq_id($seqid); # propagates if it is a split location
    }

    # set attributes of feature
    $sf->location($loc);
    $sf->primary_tag($fth->key);
    $sf->source_tag($source);
    foreach my $key ( keys %{$fth->field} ){
	foreach my $value ( @{$fth->field->{$key}} ) {
	    $sf->add_tag_value($key,$value);
	}
    }
    return $sf;
}


#line 166

sub from_SeqFeature {
    my ($sf, $context_annseq) = @_;
    my @ret;

    #
    # If this object knows how to make FThelpers, then let it
    # - this allows us to store *really* weird objects that can write
    # themselves to the EMBL/GenBank...
    #

    if ( $sf->can("to_FTHelper") ) {
	return $sf->to_FTHelper($context_annseq);
    }

    my $fth = Bio::SeqIO::FTHelper->new();
    my $key = $sf->primary_tag();
    my $locstr = $sf->location->to_FTstring;
    
    # ES 25/06/01 Commented out this code, Jason to double check
    #The location FT string for all simple subseqfeatures is already 
    #in the Split location FT string

    # going into sub features
    #foreach my $sub ( $sf->sub_SeqFeature() ) {
	#my @subfth = &Bio::SeqIO::FTHelper::from_SeqFeature($sub);
	#push(@ret, @subfth);    
    #}

    $fth->loc($locstr);
    $fth->key($key);
    $fth->field->{'note'} = [];
    #$sf->source_tag && do { push(@{$fth->field->{'note'}},"source=" . $sf->source_tag ); };
    
    ($sf->can('score') && $sf->score) && do { push(@{$fth->field->{'note'}},
						   "score=" . $sf->score ); };
    ($sf->can('frame') && $sf->frame) && do { push(@{$fth->field->{'note'}},
						   "frame=" . $sf->frame ); };
    #$sf->strand && do { push(@{$fth->field->{'note'}},"strand=" . $sf->strand ); };

    foreach my $tag ( $sf->all_tags ) {
        # Tags which begin with underscores are considered
        # private, and are therefore not printed
        next if $tag =~ /^_/;
	if ( !defined $fth->field->{$tag} ) {
	    $fth->field->{$tag} = [];
	}
	foreach my $val ( $sf->each_tag_value($tag) ) {
	    push(@{$fth->field->{$tag}},$val);
	}
    }
    push(@ret, $fth);

    unless (@ret) {
	$context_annseq->throw("Problem in processing seqfeature $sf - no fthelpers. Error!");
    }
    foreach my $ft (@ret) {
	if ( !$ft->isa('Bio::SeqIO::FTHelper') ) {
	    $sf->throw("Problem in processing seqfeature $sf - made a $fth!");
	}
    }

    return @ret;

}


#line 244

sub key {
   my ($obj, $value) = @_;
   if ( defined $value ) {
      $obj->{'key'} = $value;
    }
    return $obj->{'key'};

}

#line 265

sub loc {
   my ($obj, $value) = @_;
   if ( defined $value ) {
      $obj->{'loc'} = $value;
    }
    return $obj->{'loc'};
}


#line 286

sub field {
   my ($self) = @_;

   return $self->{'_field'};
}

#line 304

sub add_field {
   my ($self, $key, $val) = @_;

   if ( !exists $self->field->{$key} ) {
       $self->field->{$key} = [];
   }
   push( @{$self->field->{$key}} , $val);

}

1;
