#line 1 "Bio/SeqFeatureI.pm"
# $Id: SeqFeatureI.pm,v 1.43.2.5 2003/08/28 19:29:34 jason Exp $
#
# BioPerl module for Bio::SeqFeatureI
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 74


# Let the code begin...


package Bio::SeqFeatureI;
use vars qw(@ISA $HasInMemory);
use strict;

BEGIN {
    eval { require Bio::DB::InMemoryCache };
    if( $@ ) { $HasInMemory = 0 }
    else { $HasInMemory = 1 }
}

use Bio::RangeI;
use Bio::Seq;

use Carp;

@ISA = qw(Bio::RangeI);

#line 101

#line 112

sub get_SeqFeatures{
   my ($self,@args) = @_;

   $self->throw_not_implemented();
}

#line 128

sub display_name { 
    shift->throw_not_implemented();
}

#line 144

sub primary_tag{
   my ($self,@args) = @_;

   $self->throw_not_implemented();

}

#line 163

sub source_tag{
   my ($self,@args) = @_;

   $self->throw_not_implemented();
}

#line 180

sub has_tag{
   my ($self,@args) = @_;

   $self->throw_not_implemented();

}

#line 198

sub get_tag_values {
    shift->throw_not_implemented();
}

#line 213

sub get_all_tags{
    shift->throw_not_implemented();
}

#line 247

sub attach_seq {
    shift->throw_not_implemented();
}

#line 265

sub seq {
    shift->throw_not_implemented();
}

#line 282

sub entire_seq {
    shift->throw_not_implemented();
}


#line 305

sub seq_id {
    shift->throw_not_implemented();
}

#line 330

sub gff_string{
   my ($self,$formatter) = @_;

   $formatter = $self->_static_gff_formatter unless $formatter;
   return $formatter->gff_string($self);
}

my $static_gff_formatter = undef;

#line 351

sub _static_gff_formatter{
   my ($self,@args) = @_;

   if( !defined $static_gff_formatter ) {
       $static_gff_formatter = Bio::Tools::GFF->new('-gff_version' => 2);
   }
   return $static_gff_formatter;
}

#line 367

#line 395

#line 435

sub spliced_seq {
    my $self = shift;
    my $db = shift;

    if( ! $self->location->isa("Bio::Location::SplitLocationI") ) {
	return $self->seq(); # nice and easy!
    }

    # redundant test, but the above ISA is probably not ideal.
    if( ! $self->location->isa("Bio::Location::SplitLocationI") ) {
	$self->throw("not atomic, not split, yikes, in trouble!");
    }

    my $seqstr;
    my $seqid = $self->entire_seq->display_id;
    # This is to deal with reverse strand features
    # so we are really sorting features 5' -> 3' on their strand
    # i.e. rev strand features will be sorted largest to smallest
    # as this how revcom CDSes seem to be annotated in genbank.
    # Might need to eventually allow this to be programable?
    # (can I mention how much fun this is NOT! --jason)

    my ($mixed,$mixedloc,$fstrand) = (0);

    if( defined $db && 
	ref($db) &&  !$db->isa('Bio::DB::RandomAccessI') ) {
	$self->warn("Must pass in a valid Bio::DB::RandomAccessI object for access to remote locations for spliced_seq");
	$db = undef;
    } elsif( defined $db && 
	     $HasInMemory && ! $db->isa('Bio::DB::InMemoryCache') ) {
	$db = new Bio::DB::InMemoryCache(-seqdb => $db);
    }
    
    if( $self->isa('Bio::Das::SegmentI') &&
	! $self->absolute ) { 
	$self->warn("Calling spliced_seq with a Bio::Das::SegmentI ".
                    "which does have absolute set to 1 -- be warned ".
                    "you may not be getting things on the correct strand");
    }

    my @locs = map { $_->[0] }
    # sort so that most negative is first basically to order
    # the features on the opposite strand 5'->3' on their strand
    # rather than they way most are input which is on the fwd strand

    sort { $a->[1] <=> $b->[1] } # Yes Tim, Schwartzian transformation
    map { 
	$fstrand = $_->strand unless defined $fstrand;
	$mixed = 1 if defined $_->strand && $fstrand != $_->strand;
	if( defined $_->seq_id ) {
	    $mixedloc = 1 if( $_->seq_id ne $seqid );
	}
	[ $_, $_->start* ($_->strand || 1)];
    } $self->location->each_Location; 

    if ( $mixed ) { 
	$self->warn("Mixed strand locations, spliced seq using the input ".
                    "order rather than trying to sort");
	@locs = $self->location->each_Location; 
    } elsif( $mixedloc ) {
	# we'll use the prescribed location order
	@locs = $self->location->each_Location; 
    }


    foreach my $loc ( @locs  ) {
	if( ! $loc->isa("Bio::Location::Atomic") ) {
	    $self->throw("Can only deal with one level deep locations");
	}
	my $called_seq;
	if( $fstrand != $loc->strand ) {
	    $self->warn("feature strand is different from location strand!");
	}
	# deal with remote sequences
	if( defined $loc->seq_id && 
	    $loc->seq_id ne $seqid ) {
	    if( defined $db ) {
		my $sid = $loc->seq_id;
		$sid =~ s/\.\d+$//g;
		eval {
		    $called_seq = $db->get_Seq_by_acc($sid);
		};
		if( $@ ) {
		    $self->warn("In attempting to join a remote location, sequence $sid was not in database. Will provide padding N's. Full exception \n\n$@");
		    $called_seq = undef;
		}
	    } else {
		$self->warn( "cannot get remote location for ".$loc->seq_id ." without a valid Bio::DB::RandomAccessI database handle (like Bio::DB::GenBank)");
		$called_seq = undef;
	    }
	    if( !defined $called_seq ) {
		$seqstr .= 'N' x $self->length;
		next;
	    }
	} else {
	    $called_seq = $self->entire_seq;
	}
	
	if( $self->isa('Bio::Das::SegmentI') ) {
	    my ($s,$e) = ($loc->start,$loc->end);
	    $seqstr .= $called_seq->subseq($s,$e)->seq();
	} else { 
	    # This is dumb subseq should work on locations...
	    if( $loc->strand == 1 ) {
		$seqstr .= $called_seq->subseq($loc->start,$loc->end);
	    } else {
		$seqstr .= $called_seq->trunc($loc->start,$loc->end)->revcom->seq();
	    }
	}
    }
    my $out = Bio::Seq->new( -id => $self->entire_seq->display_id . "_spliced_feat",
				      -seq => $seqstr);

    return $out;
}

#line 610

#line 622

sub location {
   my ($self) = @_;

   $self->throw_not_implemented();
}


1;
