#line 1 "Bio/Location/Fuzzy.pm"
# $Id: Fuzzy.pm,v 1.24 2002/12/01 00:05:20 jason Exp $
#
# BioPerl module for Bio::Location::Fuzzy
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

#line 65

# Let the code begin...

package Bio::Location::Fuzzy;
use vars qw(@ISA );
use strict;

use Bio::Location::FuzzyLocationI;
use Bio::Location::Atomic;

@ISA = qw(Bio::Location::Atomic Bio::Location::FuzzyLocationI );

BEGIN {
    use vars qw( %FUZZYCODES %FUZZYPOINTENCODE %FUZZYRANGEENCODE 
		 @LOCATIONCODESBSANE );

    @LOCATIONCODESBSANE = (undef, 'EXACT', 'WITHIN', 'BETWEEN',
			'BEFORE', 'AFTER');

    %FUZZYCODES = ( 'EXACT' => '..', # Position is 'exact
   # Exact position is unknown, but is within the range specified, ((1.2)..100)
		    'WITHIN' => '.', 
		    # 1^2
		    'BETWEEN' => '^',
		    # <100
		    'BEFORE'  => '<',
		    # >10
		    'AFTER'   => '>');   
   
    # The following regular expressions map to fuzzy location types. Every
    # expression must match the complete encoded point string, and must
    # contain two groups identifying min and max. Empty matches are automatic.
    # converted to undef, except for 'EXACT', for which max is set to equal
    # min.
    %FUZZYPOINTENCODE = ( 
			  '\>(\d+)(.{0})' => 'AFTER',
			  '\<(.{0})(\d+)' => 'BEFORE',
			  '(\d+)'  => 'EXACT',
			  '(\d+)(.{0})\>' => 'AFTER',
			  '(.{0})(\d+)\<' => 'BEFORE',
			  '(\d+)\.(\d+)' => 'WITHIN',
			  '(\d+)\^(\d+)' => 'BETWEEN',
		     );
    
    %FUZZYRANGEENCODE  = ( '\.' => 'WITHIN',
			   '\.\.' => 'EXACT',
			   '\^' => 'BETWEEN' );

}

#line 136

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    my ($location_type, $start_ext, $start_fuz, $end_ext, $end_fuz) = 
	$self->_rearrange([ qw(LOCATION_TYPE START_EXT START_FUZ 
			       END_EXT END_FUZ )
			    ], @args);

    $location_type  && $self->location_type($location_type);
    $start_ext && $self->max_start($self->min_start + $start_ext);
    $end_ext   && $self->max_end($self->min_end + $end_ext);
    $start_fuz && $self->start_pos_type($start_fuz);
    $end_fuz   && $self->end_pos_type($end_fuz);

    return $self;
}

#line 163

sub location_type {
    my ($self,$value) = @_;
    if( defined $value || ! defined $self->{'_location_type'} ) {
	$value = 'EXACT' unless defined $value;
	if(! defined $FUZZYCODES{$value})  {
	    $value = uc($value);
	    if( $value =~ /\.\./ ) {
		$value = 'EXACT';
	    } elsif( $value =~ /^\.$/ ) {
		$value = 'WITHIN';
	    } elsif( $value =~ /\^/ ) {
		$value = 'BETWEEN';


		$self->throw("Use Bio::Location::Simple for IN-BETWEEN locations [". $self->start. "] and [". $self->end. "]")
		    if defined $self->start && defined $self->end && ($self->end - 1 == $self->start);


	    } elsif( $value ne 'EXACT' && $value ne 'WITHIN' && 
		     $value ne 'BETWEEN' ) {
		$self->throw("Did not specify a valid location type");
	    }
	}
	$self->{'_location_type'} = $value;
    }
    return $self->{'_location_type'};
}

#line 208

#sub length {
#    my($self) = @_;
#    return $self->SUPER::length() if( !$self->start || !$self->end);
#    $self->warn('Length is not valid for a FuzzyLocation'); 
#    return 0;
#}

#line 225

sub start {
    my($self,$value) = @_;
    if( defined $value ) {
	my ($encode,$min,$max) = $self->_fuzzypointdecode($value);
	$self->start_pos_type($encode);
	$self->min_start($min);
	$self->max_start($max);
    }

    $self->throw("Use Bio::Location::Simple for IN-BETWEEN locations [". $self->SUPER::start. "] and [". $self->SUPER::end. "]")
	if $self->location_type eq 'BETWEEN'  && defined $self->SUPER::end && ($self->SUPER::end - 1 == $self->SUPER::start);

    return $self->SUPER::start();
}

#line 250

sub end {
    my($self,$value) = @_;
    if( defined $value ) {
	my ($encode,$min,$max) = $self->_fuzzypointdecode($value);
	$self->end_pos_type($encode);
	$self->min_end($min);
	$self->max_end($max);
    }

    $self->throw("Use Bio::Location::Simple for IN-BETWEEN locations [". $self->SUPER::start. "] and [". $self->SUPER::end. "]")
	if $self->location_type eq 'BETWEEN' && defined $self->SUPER::start && ($self->SUPER::end - 1 == $self->SUPER::start);

    return $self->SUPER::end();
}

#line 275

sub min_start {
    my ($self,@args) = @_;

    if(@args) {
	$self->{'_min_start'} = $args[0]; # the value may be undef!
    }
    return $self->{'_min_start'};
}

#line 294

sub max_start {
    my ($self,@args) = @_;

    if(@args) {
	$self->{'_max_start'} = $args[0]; # the value may be undef!
    }
    return $self->{'_max_start'};
}

#line 314

sub start_pos_type {
    my ($self,$value) = @_;
    if(defined $value &&  $value =~ /^\d+$/ ) {
	if( $value == 0 ) { $value = 'EXACT'; }
	else { 
	    my $v = $LOCATIONCODESBSANE[$value];
	    if( ! defined $v ) {
		$self->warn("Provided value $value which I don't understand, reverting to 'EXACT'");
		$v = 'EXACT';
	    }
	    $value = $v;
	}
    }
    if(defined($value)) {
	$self->{'_start_pos_type'} = $value;
    }
    return $self->{'_start_pos_type'};
}

#line 343

sub min_end {
    my ($self,@args) = @_;

    if(@args) {
	$self->{'_min_end'} = $args[0]; # the value may be undef!
    }
    return $self->{'_min_end'};
}

#line 362

sub max_end {
    my ($self,@args) = @_;

    if(@args) {
	$self->{'_max_end'} = $args[0]; # the value may be undef!
    }
    return $self->{'_max_end'};
}

#line 382

sub end_pos_type {
    my ($self,$value) = @_;
    if( defined $value && $value =~ /^\d+$/ ) {
	if( $value == 0 ) { $value = 'EXACT'; }
	else { 
	    my $v = $LOCATIONCODESBSANE[$value];
	    if( ! defined $v ) {
		$self->warn("Provided value $value which I don't understand, reverting to 'EXACT'");
		$v = 'EXACT';
	    }
	    $value = $v;
	}
    }

    if(defined($value)) {
	$self->{'_end_pos_type'} = $value;
    }
    return $self->{'_end_pos_type'};
}

#line 412

#line 439

#line 449

sub to_FTstring {
    my ($self) = @_;
    my (%vals) = ( 'start' => $self->start,
		   'min_start' => $self->min_start,
		   'max_start' => $self->max_start,
		   'start_code' => $self->start_pos_type,
		   'end' => $self->end,
		   'min_end' => $self->min_end,
		   'max_end' => $self->max_end,
		   'end_code' => $self->end_pos_type );
    
    my (%strs) = ( 'start' => '',
		   'end'   => '');
    my ($delimiter) = $FUZZYCODES{$self->location_type};
    # I'm lazy, lets do this in a loop since behaviour will be the same for 
    # start and end
    foreach my $point ( qw(start end) ) {
	if( $vals{$point."_code"} ne 'EXACT' ) {
	    
	    if( (!defined $vals{"min_$point"} ||
		 !defined $vals{"max_$point"})
		&& ( $vals{$point."_code"} eq 'WITHIN' || 
		     $vals{$point."_code"} eq 'BETWEEN')
		     ) {
		$vals{"min_$point"} = '' unless defined $vals{"min_$point"};
		$vals{"max_$point"} = '' unless defined $vals{"max_$point"};
		
		$self->warn("Fuzzy codes for start are in a strange state, (".
			    join(",", ($vals{"min_$point"}, 
				       $vals{"max_$point"},
				       $vals{$point."_code"})). ")");
		return '';
	    }
	    if( defined $vals{$point."_code"} && 
		($vals{$point."_code"} eq 'BEFORE' ||
		 $vals{$point."_code"} eq 'AFTER')
		) {
		$strs{$point} .= $FUZZYCODES{$vals{$point."_code"}};
	    } 
	    if( defined $vals{"min_$point"} ) {
		$strs{$point} .= $vals{"min_$point"};
	    }
	    if( defined $vals{$point."_code"} && 
		($vals{$point."_code"} eq 'WITHIN' ||
		 $vals{$point."_code"} eq 'BETWEEN')
		) {
		$strs{$point} .= $FUZZYCODES{$vals{$point."_code"}};
	    }
	    if( defined $vals{"max_$point"} ) {
		$strs{$point} .= $vals{"max_$point"};
	    }
	    if(($vals{$point."_code"} eq 'WITHIN') || 
	       ($vals{$point."_code"} eq 'BETWEEN')) {
		$strs{$point} = "(".$strs{$point}.")";
	    }
	} else { 
	    $strs{$point} = $vals{$point};
	}
	
    }
    my $str = $strs{'start'} . $delimiter . $strs{'end'};
    if($self->is_remote() && $self->seq_id()) {
	$str = $self->seq_id() . ":" . $str;
    }
    if( $self->strand == -1 ) {
	$str = "complement(" . $str . ")";
    } elsif($self->location_type() eq "WITHIN") {
	$str = "(".$str.")";
    }
    return $str;
}

#line 535

sub _fuzzypointdecode {
    my ($self, $string) = @_;
    return () if( !defined $string);
    # strip off leading and trailing space
    $string =~ s/^\s*(\S+)\s*/$1/;
    foreach my $pattern ( keys %FUZZYPOINTENCODE ) {
	if( $string =~ /^$pattern$/ ) {
	    my ($min,$max) = ($1,$2);
	    if($FUZZYPOINTENCODE{$pattern} eq 'EXACT') {
		$max = $min;
	    } else {
		$max = undef if(length($max) == 0);
		$min = undef if(length($min) == 0);
	    }
	    return ($FUZZYPOINTENCODE{$pattern},$min,$max);
	}
    }
    if( $self->verbose >= 1 ) {
	$self->warn("could not find a valid fuzzy encoding for $string");
    }
    return ();
}

1;

