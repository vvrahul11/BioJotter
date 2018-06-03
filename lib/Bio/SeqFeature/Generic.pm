#line 1 "Bio/SeqFeature/Generic.pm"
# $Id: Generic.pm,v 1.74.2.1 2003/09/09 20:12:37 lstein Exp $
#
# BioPerl module for Bio::SeqFeature::Generic
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 125


# Let the code begin...


package Bio::SeqFeature::Generic;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::SeqFeatureI;
use Bio::AnnotatableI;
use Bio::FeatureHolderI;
use Bio::Annotation::Collection;
use Bio::Location::Simple;
use Bio::Tools::GFF;
#use Tie::IxHash;

@ISA = qw(Bio::Root::Root Bio::SeqFeatureI 
          Bio::AnnotatableI Bio::FeatureHolderI);

sub new {
    my ( $caller, @args) = @_;   
    my ($self) = $caller->SUPER::new(@args); 

    $self->{'_parse_h'}       = {};
    $self->{'_gsf_tag_hash'}  = {};
#    tie %{$self->{'_gsf_tag_hash'}}, "Tie::IxHash";

    # bulk-set attributes
    $self->set_attributes(@args);

    # done - we hope
    return $self;
}


#line 187

sub set_attributes {
    my ($self,@args) = @_;
    my ($start, $end, $strand, $primary_tag, $source_tag, $primary, $source, $frame, 
	$score, $tag, $gff_string, $gff1_string,
	$seqname, $seqid, $annot, $location,$display_name) =
	    $self->_rearrange([qw(START
				  END
				  STRAND
				  PRIMARY_TAG
				  SOURCE_TAG
				  PRIMARY
				  SOURCE
				  FRAME
				  SCORE
				  TAG
				  GFF_STRING
				  GFF1_STRING
				  SEQNAME
				  SEQ_ID
				  ANNOTATION
				  LOCATION
				  DISPLAY_NAME
				  )], @args);
    $location    && $self->location($location);
    $gff_string  && $self->_from_gff_string($gff_string);
    $gff1_string  && do {
	$self->gff_format(Bio::Tools::GFF->new('-gff_version' => 1));
	$self->_from_gff_stream($gff1_string);
    };
    $primary_tag           && $self->primary_tag($primary_tag);
    $source_tag            && $self->source_tag($source_tag);
    $primary               && $self->primary_tag($primary);
    $source                && $self->source_tag($source);
    defined $start         && $self->start($start);
    defined $end           && $self->end($end);
    defined $strand        && $self->strand($strand);
    defined $frame         && $self->frame($frame);
    $score                 && $self->score($score);
    $annot                 && $self->annotation($annot);
    defined $display_name  && $self->display_name($display_name);
    if($seqname) {
	$self->warn("-seqname is deprecated. Please use -seq_id instead.");
	$seqid = $seqname unless $seqid;
    }
    $seqid          && $self->seq_id($seqid);
    $tag            && do {
	foreach my $t ( keys %$tag ) {
	    $self->add_tag_value($t,$tag->{$t});
	}
    };
}


#line 252

sub direct_new {
    my ( $class) = @_;   
    my ($self) = {};

    bless $self,$class;

    return $self;
}

#line 273

sub location {
    my($self, $value ) = @_;  

    if (defined($value)) {
        unless (ref($value) and $value->isa('Bio::LocationI')) {
	    $self->throw("object $value pretends to be a location but ".
			 "does not implement Bio::LocationI");
        }
        $self->{'_location'} = $value;
    }
    elsif (! $self->{'_location'}) {
        # guarantees a real location object is returned every time
        $self->{'_location'} = Bio::Location::Simple->new();
    }
    return $self->{'_location'};
}


#line 303

sub start {
   my ($self,$value) = @_;
   return $self->location->start($value);
}

#line 320

sub end {
   my ($self,$value) = @_;
   return $self->location->end($value);
}

#line 337

sub length {
   my ($self) = @_;
   return $self->end - $self->start() + 1;
}

#line 354

sub strand {
   my ($self,$value) = @_;
   return $self->location->strand($value);
}

#line 371

sub score {
  my ($self,$value) = @_;

  if (defined($value)) {
       if ( $value !~ /^[+-]?\d+\.?\d*(e-\d+)?/ ) {
	   $self->throw("'$value' is not a valid score");
       }
       $self->{'_gsf_score'} = $value;
  }

  return $self->{'_gsf_score'};
}

#line 396

sub frame {
  my ($self,$value) = @_;

  if ( defined $value ) {
       if ( $value !~ /^[0-2.]$/ ) {
	   $self->throw("'$value' is not a valid frame");
       }
       if( $value eq '.' ) { $value = '.'; } 
       $self->{'_gsf_frame'} = $value;
  }
  return $self->{'_gsf_frame'};
}

#line 422

sub primary_tag {
   my ($self,$value) = @_;
   if ( defined $value ) {
       $self->{'_primary_tag'} = $value;
   }
   return $self->{'_primary_tag'};
}

#line 443

sub source_tag {
   my ($self,$value) = @_;

   if( defined $value ) {
       $self->{'_source_tag'} = $value;
   }
   return $self->{'_source_tag'};
}

#line 464

sub has_tag {
    my ($self, $tag) = @_;
    return exists $self->{'_gsf_tag_hash'}->{$tag};
}

#line 479

sub add_tag_value {
    my ($self, $tag, $value) = @_;    
    $self->{'_gsf_tag_hash'}->{$tag} ||= [];
    push(@{$self->{'_gsf_tag_hash'}->{$tag}},$value);
}


#line 498

sub get_tag_values {
   my ($self, $tag) = @_;

   if( ! defined $tag ) { return (); }
   if ( ! exists $self->{'_gsf_tag_hash'}->{$tag} ) {
       $self->throw("asking for tag value that does not exist $tag");
   }
   return @{$self->{'_gsf_tag_hash'}->{$tag}};
}


#line 520

sub get_all_tags {
   my ($self, @args) = @_;   
   return keys %{ $self->{'_gsf_tag_hash'}};
}

#line 536

sub remove_tag {
   my ($self, $tag) = @_;

   if ( ! exists $self->{'_gsf_tag_hash'}->{$tag} ) {
       $self->throw("trying to remove a tag that does not exist: $tag");
   }
   my @vals = @{$self->{'_gsf_tag_hash'}->{$tag}};
   delete $self->{'_gsf_tag_hash'}->{$tag};
   return @vals;
}

#line 561

sub attach_seq {
   my ($self, $seq) = @_;

   if ( ! ($seq && ref($seq) && $seq->isa("Bio::PrimarySeqI")) ) {
       $self->throw("Must attach Bio::PrimarySeqI objects to SeqFeatures");
   }

   $self->{'_gsf_seq'} = $seq;

   # attach to sub features if they want it
   foreach ( $self->sub_SeqFeature() ) {
       $_->attach_seq($seq);
   }

   return 1;
}

#line 591

sub seq {
   my ($self, $arg) = @_;

   if ( defined $arg ) {
       $self->throw("Calling SeqFeature::Generic->seq with an argument. You probably want attach_seq");
   }

   if ( ! exists $self->{'_gsf_seq'} ) {
       return undef;
   }

   # assumming our seq object is sensible, it should not have to yank
   # the entire sequence out here.

   my $seq = $self->{'_gsf_seq'}->trunc($self->start(), $self->end());


   if ( $self->strand == -1 ) {

       # ok. this does not work well (?)
       #print STDERR "Before revcom", $seq->str, "\n";
       $seq = $seq->revcom;
       #print STDERR "After  revcom", $seq->str, "\n";
   }

   return $seq;
}

#line 632

sub entire_seq {
   my ($self) = @_;

   return $self->{'_gsf_seq'};
}


#line 657

sub seq_id {
    my ($obj,$value) = @_;
    if ( defined $value ) {
	$obj->{'_gsf_seq_id'} = $value;
    }
    return $obj->{'_gsf_seq_id'};
}

#line 676

sub display_name{
    my $self = shift;

    return $self->{'display_name'} = shift if @_;
    return $self->{'display_name'};
}

#line 687

#line 701

sub annotation {
    my ($obj,$value) = @_;

    # we are smart if someone references the object and there hasn't been
    # one set yet
    if(defined $value || ! defined $obj->{'annotation'} ) {
        $value = new Bio::Annotation::Collection unless ( defined $value );
        $obj->{'annotation'} = $value;
    }
    return $obj->{'annotation'};
}

#line 721

#line 732

sub get_SeqFeatures {
    my ($self) = @_;

    if ($self->{'_gsf_sub_array'}) {
        return @{$self->{'_gsf_sub_array'}};
    } else {
        return;
    }
}

#line 761

#'
sub add_SeqFeature{
    my ($self,$feat,$expand) = @_;

    if ( !$feat->isa('Bio::SeqFeatureI') ) {
        $self->warn("$feat does not implement Bio::SeqFeatureI. Will add it anyway, but beware...");
    }

    if($expand && ($expand eq 'EXPAND')) {
        $self->_expand_region($feat);
    } else {
        if ( !$self->contains($feat) ) {
	    $self->throw("$feat is not contained within parent feature, and expansion is not valid");
        }
    }

    $self->{'_gsf_sub_array'} = [] unless exists($self->{'_gsf_sub_array'});
    push(@{$self->{'_gsf_sub_array'}},$feat);

}

#line 799

sub remove_SeqFeatures {
   my ($self) = @_;

   my @subfeats = @{$self->{'_gsf_sub_array'}};
   $self->{'_gsf_sub_array'} = []; # zap the array implicitly.
   return @subfeats;
}

#line 811

#line 831

sub gff_format {
    my ($self, $gffio) = @_;

    if(defined($gffio)) {
	if(ref($self)) {
	    $self->{'_gffio'} = $gffio;
	} else {
	    $Bio::SeqFeatureI::static_gff_formatter = $gffio;
	}
    }
    return (ref($self) && exists($self->{'_gffio'}) ?
	    $self->{'_gffio'} : $self->_static_gff_formatter);
}

#line 861

sub gff_string{
   my ($self,$formatter) = @_;

   $formatter = $self->gff_format() unless $formatter;
   return $formatter->gff_string($self);
}

#  =head2 slurp_gff_file
#
#   Title   : slurp_file
#   Usage   : @features = Bio::SeqFeature::Generic::slurp_gff_file(\*FILE);
#   Function: Sneaky function to load an entire file as in memory objects.
#             Beware of big files.
#
#             This method is deprecated. Use Bio::Tools::GFF instead, which can
#             also handle large files.
#
#   Example :
#   Returns :
#   Args    :
#
#  =cut

sub slurp_gff_file {
   my ($f) = @_;
   my @out;
   if ( !defined $f ) {
       die "Must have a filehandle";
   }

   Bio::Root::Root->warn("deprecated method slurp_gff_file() called in Bio::SeqFeature::Generic. Use Bio::Tools::GFF instead.");
  
   while(<$f>) {

       my $sf = Bio::SeqFeature::Generic->new('-gff_string' => $_);
       push(@out, $sf);
   }

   return @out;

}

#line 920

sub _from_gff_string {
   my ($self, $string) = @_;

   $self->gff_format()->from_gff_string($self, $string);
}


#line 942

sub _expand_region {
    my ($self, $feat) = @_;
    if(! $feat->isa('Bio::SeqFeatureI')) {
	$self->warn("$feat does not implement Bio::SeqFeatureI");
    }
    # if this doesn't have start/end set - forget it!
    if((! defined($self->start())) && (! defined $self->end())) {
	$self->start($feat->start());
	$self->end($feat->end());
	$self->strand($feat->strand) unless defined($self->strand());
    } else {
	my $range = $self->union($feat);
	$self->start($range->start);
	$self->end($range->end);
	$self->strand($range->strand);
    }
}

#line 972

sub _parse {
   my ($self) = @_;

   return $self->{'_parse_h'};
}

#line 990

sub _tag_value {
    my ($self, $tag, $value) = @_;

    if(defined($value) || (! $self->has_tag($tag))) {
	$self->remove_tag($tag) if($self->has_tag($tag));
	$self->add_tag_value($tag, $value);
    }
    return ($self->each_tag_value($tag))[0];
}

#######################################################################
# aliases for methods that changed their names in an attempt to make  #
# bioperl names more consistent                                       #
#######################################################################

sub seqname {
    my $self = shift;
    $self->warn("SeqFeatureI::seqname() is deprecated. Please use seq_id() instead.");
    return $self->seq_id(@_);
}

sub display_id {
    my $self = shift;
    $self->warn("SeqFeatureI::display_id() is deprecated. Please use display_name() instead.");
    return $self->display_name(@_);
}

# this is towards consistent naming
sub each_tag_value { return shift->get_tag_values(@_); }
sub all_tags { return shift->get_all_tags(@_); }

# we revamped the feature containing property to implementing
# Bio::FeatureHolderI
*sub_SeqFeature = \&get_SeqFeatures;
*add_sub_SeqFeature = \&add_SeqFeature;
*flush_sub_SeqFeatures = \&remove_SeqFeatures;
# this one is because of inconsistent naming ...
*flush_sub_SeqFeature = \&remove_SeqFeatures;


1;
