#line 1 "Bio/Seq/PrimaryQual.pm"
# $Id: PrimaryQual.pm,v 1.17 2002/10/22 07:38:40 lapp Exp $
#
# bioperl module for Bio::PrimaryQual
#
# Cared for by Chad Matsalla <bioinformatics@dieselwurks.com>
#
# Copyright Chad Matsalla
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 86


# Let the code begin...

package Bio::Seq::PrimaryQual;
use vars qw(@ISA %valid_type);
use strict;

use Bio::Root::Root;
use Bio::Seq::QualI;

@ISA = qw(Bio::Root::Root Bio::Seq::QualI);


#line 116




sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    # default: turn ON the warnings (duh)
    my($qual,$id,$acc,$pid,$desc,$given_id) =
        $self->_rearrange([qw(QUAL
                              DISPLAY_ID
                              ACCESSION_NUMBER
                              PRIMARY_ID
                              DESC
                              ID
                              )],
                          @args);
    if( defined $id && defined $given_id ) {
        if( $id ne $given_id ) {
            $self->throw("Provided both id and display_id constructor functions. [$id] [$given_id]");   
        }
    }
    if( defined $given_id ) { $id = $given_id; }
    
    # note: the sequence string may be empty
    $self->qual($qual ? $qual : []);
    $id      && $self->display_id($id);
    $acc     && $self->accession_number($acc);
    $pid     && $self->primary_id($pid);
    $desc    && $self->desc($desc);

    return $self;
}

#line 161

sub qual {
    my ($self,$value) = @_;
    
    if( ! defined $value || length($value) == 0 ) { 
	$self->{'qual'} ||= [];
    } elsif( ref($value) =~ /ARRAY/i ) {
	# if the user passed in a reference to an array
	$self->{'qual'} = $value;
    } elsif(! $self->validate_qual($value)){
	$self->throw("Attempting to set the quality to [$value] which does not look healthy");	    
    } else {
	$self->{'qual'} = [split(/\s+/,$value)];
    }
    
    return $self->{'qual'};
}

#line 192

sub validate_qual {
    # how do I validate quality values?
    # \d+\s+\d+..., I suppose
    my ($self,$qualstr) = @_;
    # why the CORE?? -- (Because Bio::PrimarySeqI namespace has a 
    #                    length method, you have to qualify 
    #                    which length to use)
    return 0 if (!defined $qualstr || CORE::length($qualstr) <= 0);   
    return 1 if( $qualstr =~ /\d/);
    
    return 0;
}

#line 218


sub subqual {
   my ($self,$start,$end) = @_;

   if( $start > $end ){
       $self->throw("in subqual, start [$start] has to be greater than end [$end]");
   }

   if( $start <= 0 || $end > $self->length ) {
       $self->throw("You have to have start positive and length less than the total length of sequence [$start:$end] Total ".$self->length."");
   }

   # remove one from start, and then length is end-start

   $start--;
	$end--;
	my @sub_qual_array = @{$self->{qual}}[$start..$end];

 	#   return substr $self->seq(), $start, ($end-$start);
	return \@sub_qual_array;

}

#line 263

sub display_id {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'display_id'} = $value;
    }
    return $obj->{'display_id'};

}

#line 288

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

#line 314

sub primary_id {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'primary_id'} = $value;
    }
   return $obj->{'primary_id'};

}

#line 335

sub desc {
   my ($obj,$value) = @_;
   if( defined $value) {
      $obj->{'desc'} = $value;
    }
    return $obj->{'desc'};

}

#line 356

sub id {
   my ($self,$value) = @_;
   if( defined $value ) {
        return $self->display_id($value);
   }
   return $self->display_id();
}

#line 378

sub length {
    my $self = shift;
    if (ref($self->{qual}) ne "ARRAY") {
	$self->warn("{qual} is not an array here. Why? It appears to be ".ref($self->{qual})."(".$self->{qual}."). Good thing this can _never_ happen.");
    }
    return scalar(@{$self->{qual}});
}

#line 399

sub qualat {
    my ($self,$val) = @_;
    my @qualat = @{$self->subqual($val,$val)};
    if (scalar(@qualat) == 1) {
	return $qualat[0];
    }
    else {
	$self->throw("AAAH! qualat provided more then one quality.");
    }
} 

#line 428

sub to_string {
    my ($self,$out,$result) = shift;
    $out = "qual: ".join(',',@{$self->qual()});
    foreach (qw(display_id accession_number primary_id desc id)) {
	$result = $self->$_();
	if (!$result) { $result = "<unset>"; }
	$out .= "$_: $result\n";
    }
    return $out;
}


sub to_string_automatic {
    my ($self,$sub_result,$out) = shift;
    foreach (sort keys %$self) {
	print("Working on $_\n");
	eval { $self->$_(); };
	if ($@) { $sub_result = ref($_); }
	elsif (!($sub_result = $self->$_())) {
	    $sub_result = "<unset>";
	}
	if (ref($sub_result) eq "ARRAY") {
	    print("This thing ($_) is an array!\n");
	    $sub_result = join(',',@$sub_result);	
	}
	$out .= "$_: ".$sub_result."\n";
    }
    return $out;
} 

1;
