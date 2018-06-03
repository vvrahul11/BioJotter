#line 1 "Bio/SeqFeature/SimilarityPair.pm"
# $Id: SimilarityPair.pm,v 1.21 2002/12/24 15:15:32 jason Exp $
#
# BioPerl module for Bio::SeqFeature::SimilarityPair
#
# Cared for by Hilmar Lapp <hlapp@gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 72


# Let the code begin...


package Bio::SeqFeature::SimilarityPair;
use vars qw(@ISA);
use strict;

use Bio::SeqFeature::FeaturePair;
use Bio::SeqFeature::Similarity;
use Bio::SearchIO;

@ISA = qw(Bio::SeqFeature::FeaturePair);

#line 101

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    # Hack to deal with the fact that SimilarityPair calls strand()
    # which will lead to an error in Bio::Search::HSP::BlastHSP 
    # because parsing hasn't yet occurred.
    # TODO: Remove this when BlastHSP doesn't do lazy parsing.
    $self->{'_initializing'} = 1;

    my ($primary, $hit, $query, $fea1, $source,$sbjct) =
	$self->_rearrange([qw(PRIMARY
			      HIT
			      QUERY
			      FEATURE1
                              SOURCE
			      SUBJECT
			      )],@args);
    
    if( $sbjct ) { 
	# undeprecated by Jason before 1.1 release 
        # $self->deprecated("use of -subject deprecated: SimilarityPair now uses 'hit'");
	if(! $hit) { $hit = $sbjct } 
	else { 
	    $self->warn("-hit and -subject were specified, using -hit and ignoring -subject");
	}
    }

    # make sure at least the query feature exists -- this refers to feature1
    if($query && ! $fea1) { $self->query( $query);  } 
    else { $self->query('null'); } # call with no args sets a default value for query
    
    $hit && $self->hit($hit);
    # the following refer to feature1, which has been ensured to exist
    if( defined $primary || ! defined $self->primary_tag) { 
	$primary = 'similarity' unless defined $primary;
	$self->primary_tag($primary);
    } 

    $source && $self->source_tag($source);
    $self->strand(0) unless( defined $self->strand() );

    $self->{'_initializing'} = 0;  # See "Hack" note above
    return $self;
}

#
# Everything else is just inherited from SeqFeature::FeaturePair.
#

#line 165

sub query {
    my ($self, @args) = @_;
    my $f = $self->feature1();
    if( ! @args || ( !ref($args[0]) && $args[0] eq 'null') ) {
	if( ! defined( $f) ) {
	    @args = Bio::SeqFeature::Similarity->new();
	} elsif( ! $f->isa('Bio::SeqFeature::Similarity') && 
		 $f->isa('Bio::SeqFeatureI') ) {
	    # a Bio::SeqFeature::Generic was placeholder for feature1	    
	    my $newf = new 
	      Bio::SeqFeature::Similarity( -start   => $f->start(),
					   -end     => $f->end(),
					   -strand  => $f->strand(),
					   -primary => $f->primary_tag(),
					   -source  => $f->source_tag(),
					   -seq_id  => $f->seq_id(),
					   -score   => $f->score(),
					   -frame   => $f->frame(),
					   );
	    foreach my $tag ( $newf->all_tags ) {
		$tag->add_tag($tag, $newf->each_tag($tag));
	    }
	    @args = $newf;	   
	} else {
	    @args = ();
	}
    }
    return $self->feature1(@args);
}




#line 210

sub subject { 
    my $self = shift;
#    $self->deprecated("Method subject deprecated: use hit() instead");
    $self->hit(@_); 
}

*sbjct = \&subject;

#line 230

sub hit {
    my ($self, @args) = @_;
    my $f = $self->feature2();
    if(! @args || (!ref($args[0]) && $args[0] eq 'null') ) {
	if( ! defined( $f) ) {
	    @args = Bio::SeqFeature::Similarity->new();
	} elsif( ! $f->isa('Bio::SeqFeature::Similarity') && 
		 $f->isa('Bio::SeqFeatureI')) {
	    # a Bio::SeqFeature::Generic was placeholder for feature2	    
	    my $newf = new 
	      Bio::SeqFeature::Similarity( -start   => $f->start(),
					   -end     => $f->end(),
					   -strand  => $f->strand(),
					   -primary => $f->primary_tag(),
					   -source  => $f->source_tag(),
					   -seq_id  => $f->seq_id(),
					   -score   => $f->score(),
					   -frame   => $f->frame(),
					   );
	    foreach my $tag ( $newf->all_tags ) {
		$tag->add_tag($tag, $newf->each_tag($tag));
	    }
	    @args = $newf;
	}
    }
    return $self->feature2(@args);
}

#line 270

sub source_tag {
    my ($self, @args) = @_;

    if(@args) {
	$self->hit()->source_tag(@args);
    }
    return $self->query()->source_tag(@args);
}

#line 291

sub significance {
    my ($self, @args) = @_;

    if(@args) {
	$self->hit()->significance(@args);
    }
    return $self->query()->significance(@args);
}

#line 312

sub score {
    my ($self, @args) = @_;

    if(@args) {
	$self->hit()->score(@args);
    }
    return $self->query()->score(@args);
}

#line 333

sub bits {
    my ($self, @args) = @_;

    if(@args) {
	$self->hit()->bits(@args);
    }
    return $self->query()->bits(@args);
}

1;
