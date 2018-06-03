#line 1 "Bio/PrimarySeq.pm"
# $Id: PrimarySeq.pm,v 1.73.2.1 2003/06/29 00:25:27 jason Exp $
#
# bioperl module for Bio::PrimarySeq
#
# Cared for by Ewan Birney <birney@sanger.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 110


# Let the code begin...


package Bio::PrimarySeq;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::PrimarySeqI;
use Bio::IdentifiableI;
use Bio::DescribableI;

@ISA = qw(Bio::Root::Root Bio::PrimarySeqI
	  Bio::IdentifiableI Bio::DescribableI);

#
# setup the allowed values for alphabet()
#

my %valid_type = map {$_, 1} qw( dna rna protein );

#line 162


sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    my($seq,$id,$acc,$pid,$ns,$auth,$v,$oid,
       $desc,$alphabet,$given_id,$is_circular,$direct,$ref_to_seq,$len) =
	$self->_rearrange([qw(SEQ
			      DISPLAY_ID
			      ACCESSION_NUMBER
			      PRIMARY_ID
			      NAMESPACE
			      AUTHORITY
			      VERSION
			      OBJECT_ID
			      DESC
			      ALPHABET
			      ID
			      IS_CIRCULAR
			      DIRECT
			      REF_TO_SEQ
			      LENGTH
			      )],
			  @args);
    if( defined $id && defined $given_id ) {
	if( $id ne $given_id ) {
	    $self->throw("Provided both id and display_id constructor ".
			 "functions. [$id] [$given_id]");	
	}
    }
    if( defined $given_id ) { $id = $given_id; }

    # let's set the length before the seq -- if there is one, this length is
    # going to be invalidated
    defined $len && $self->length($len);

    # if alphabet is provided we set it first, so that it won't be guessed
    # when the sequence is set
    $alphabet && $self->alphabet($alphabet);
    
    # if there is an alphabet, and direct is passed in, assumme the alphabet
    # and sequence is ok 

    if( $direct && $ref_to_seq) {
	$self->{'seq'} = $$ref_to_seq;
	if( ! $alphabet ) {
	    $self->_guess_alphabet();
	} # else it has been set already above
    } else {
#	print STDERR "DEBUG: setting sequence to [$seq]\n";
	# note: the sequence string may be empty
	$self->seq($seq) if defined($seq);
    }

    $id          && $self->display_id($id);
    $acc         && $self->accession_number($acc);
    defined $pid && $self->primary_id($pid);
    $desc        && $self->desc($desc);
    $is_circular && $self->is_circular($is_circular);
    $ns          && $self->namespace($ns);
    $auth        && $self->authority($auth);
    defined($v)  && $self->version($v);
    defined($oid) && $self->object_id($oid);

    return $self;
}

sub direct_seq_set {
    my $obj = shift;
    return $obj->{'seq'} = shift if @_;
    return undef;
}


#line 252

sub seq {
   my ($obj,@args) = @_;

   if( scalar(@args) == 0 ) {
       return $obj->{'seq'};
   }

   my ($value,$alphabet) = @args;


   if(@args) {
       if(defined($value) && (! $obj->validate_seq($value))) {
	   $obj->throw("Attempting to set the sequence to [$value] ".
		       "which does not look healthy");
       }
       # if a sequence was already set we make sure that we re-adjust the
       # mol.type, otherwise we skip guessing if mol.type is already set
       # note: if the new seq is empty or undef, we don't consider that a
       # change (we wouldn't have anything to guess on anyway)
       my $is_changed_seq =
	   exists($obj->{'seq'}) && (CORE::length($value || '') > 0);
       $obj->{'seq'} = $value;
       # new alphabet overridden by arguments?
       if($alphabet) {
	   # yes, set it no matter what
	   $obj->alphabet($alphabet);
       } elsif( # if we changed a previous sequence to a new one
		$is_changed_seq ||
		# or if there is no alphabet yet at all
		(! defined($obj->alphabet()))) {
	   # we need to guess the (possibly new) alphabet
	   $obj->_guess_alphabet();
       } # else (seq not changed and alphabet was defined) do nothing
       # if the seq is changed, make sure we unset a possibly set length
       $obj->length(undef) if $is_changed_seq;
   }
   return $obj->{'seq'};
}

#line 313

sub validate_seq {
    my ($self,$seqstr) = @_;
    if( ! defined $seqstr ){ $seqstr = $self->seq(); }
    return 0 unless( defined $seqstr); 
    if((CORE::length($seqstr) > 0) && ($seqstr !~ /^([A-Za-z\-\.\*\?]+)$/)) {
	$self->warn("seq doesn't validate, mismatch is " .
		   ($seqstr =~ /([^A-Za-z\-\.\*\?]+)/g));
	return 0;
    }
    return 1;
}

#line 340

sub subseq {
   my ($self,$start,$end,$replace) = @_;

   if( ref($start) && $start->isa('Bio::LocationI') ) {
       my $loc = $start;
       $replace = $end; # do we really use this anywhere? scary. HL
       my $seq = "";
       foreach my $subloc ($loc->each_Location()) {
	   my $piece = $self->subseq($subloc->start(),
				     $subloc->end(), $replace);
	   if($subloc->strand() < 0) {
	       $piece = Bio::PrimarySeq->new('-seq' => $piece)->revcom()->seq();
	   }
	   $seq .= $piece;
       }
       return $seq;
   } elsif(  defined  $start && defined $end ) {
       if( $start > $end ){
	   $self->throw("in subseq, start [$start] has to be ".
			"greater than end [$end]");
       }
       if( $start <= 0 || $end > $self->length ) {
	   $self->throw("You have to have start positive\n\tand length less ".
			"than the total length of sequence [$start:$end] ".
			"Total ".$self->length."");
       }

       # remove one from start, and then length is end-start
       $start--;
       if( defined $replace ) {
	   return substr( $self->seq(), $start, ($end-$start), $replace);
       } else {
	   return substr( $self->seq(), $start, ($end-$start));
       }
   } else {
       $self->warn("Incorrect parameters to subseq - must be two integers ".
		   "or a Bio::LocationI object not ($start,$end)");
   }
}

#line 407

sub length {
    my $self = shift;
    my $len = CORE::length($self->seq() || '');
    
    if(@_) {
	my $val = shift;
	if(defined($val) && $len && ($len != $val)) {
	    $self->throw("You're trying to lie about the length: ".
			 "is $len but you say ".$val);
	}
	$self->{'_seq_length'} = $val;
    } elsif(defined($self->{'_seq_length'})) {
	return $self->{'_seq_length'};
    }
    return $len;
}

#line 450

sub display_id {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'display_id'} = $value;
    }
    return $obj->{'display_id'};

}

#line 483

sub accession_number {
    my( $obj, $acc ) = @_;

    if (defined $acc) {
        $obj->{'accession_number'} = $acc;
    } else {
        $acc = $obj->{'accession_number'};
        $acc = 'unknown' unless defined $acc;
    }
    return $acc;
}

#line 512

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


#line 543

sub alphabet {
    my ($obj,$value) = @_;
    if (defined $value) {
	$value = lc $value;
	unless ( $valid_type{$value} ) {
	    $obj->throw("Molecular type '$value' is not a valid type (".
			join(',', map "'$_'", sort keys %valid_type) .
			") lowercase");
	}
	$obj->{'alphabet'} = $value;
    }
    return $obj->{'alphabet'};
}

#line 573

sub desc{
    my $self = shift;

    return $self->{'desc'} = shift if @_;
    return $self->{'desc'};
}

#line 592

sub can_call_new {
   my ($self) = @_;

   return 1;

}

#line 611

sub  id {
   return shift->display_id(@_);
}

#line 625

sub is_circular{
    my $self = shift;
    return $self->{'is_circular'} = shift if @_;
    return $self->{'is_circular'};
}

#line 635

#line 649

sub object_id {
    return shift->accession_number(@_);
}

#line 666

sub version{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_version'} = $value;
    }
    return $self->{'_version'};
}


#line 687

sub authority {
    my ($obj,$value) = @_;
    if( defined $value) {
	$obj->{'authority'} = $value;
    }
    return $obj->{'authority'};
}

#line 708

sub namespace{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'namespace'} = $value;
    }
    return $self->{'namespace'} || "";
}

#line 722

#line 737

sub display_name {
    return shift->display_id(@_);
}

#line 757

sub description {
    return shift->desc(@_);
}

#line 793

#line 806

#line 812

#line 824

sub _guess_alphabet {
   my ($self) = @_;
   my ($str,$str2,$total,$atgc,$u,$type);

   $str = $self->seq();
   $str =~ s/\-\.\?//g;

   $total = CORE::length($str);
   if( $total == 0 ) {
       $self->throw("Got a sequence with no letters in - ".
		    "cannot guess alphabet [$str]");
   }
   
   $u = ($str =~ tr/Uu//);
   $atgc = ($str =~ tr/ATGCNatgcn//);
   
   if( ($atgc / $total) > 0.85 ) {
       $type = 'dna';
   } elsif( (($atgc + $u) / $total) > 0.85 ) {
       $type = 'rna';
   } else {
       $type = 'protein';
   }

   $self->alphabet($type);
   return $type;
}

############################################################################
# aliases due to name changes or to compensate for our lack of consistency #
############################################################################

sub accession {
    my $self = shift;

    $self->warn(ref($self)."::accession is deprecated, ".
		"use accession_number() instead");
    return $self->accession_number(@_);
}

1;

