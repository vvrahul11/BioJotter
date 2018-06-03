#line 1 "Bio/Search/Hit/BlastHit.pm"
#-----------------------------------------------------------------
# $Id: BlastHit.pm,v 1.13 2002/10/22 09:36:19 sac Exp $
#
# BioPerl module Bio::Search::Hit::BlastHit
#
# (This module was originally called Bio::Tools::Blast::Sbjct)
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

## POD Documentation:

#line 197


# Let the code begin...

package Bio::Search::Hit::BlastHit;

use strict;
use Bio::Search::Hit::HitI;
use Bio::Root::Root;
require Bio::Search::BlastUtils;
use vars qw( @ISA %SUMMARY_OFFSET $Revision);

use overload 
    '""' => \&to_string;

@ISA = qw( Bio::Root::Root Bio::Search::Hit::HitI );

$Revision = '$Id: BlastHit.pm,v 1.13 2002/10/22 09:36:19 sac Exp $';  #'


#line 253

#-------------------
sub new {
#-------------------
    my ($class, @args ) = @_;
    my $self = $class->SUPER::new( @args );

    my ($raw_data, $signif, $is_pval, $hold_raw);

    ($self->{'_blast_program'}, $self->{'_query_length'}, $raw_data, $hold_raw,
     $self->{'_overlap'}, $self->{'_iteration'}, $signif, $is_pval, 
     $self->{'_score'}, $self->{'_found_again'} ) = 
       $self->_rearrange( [qw(PROGRAM
			      QUERY_LEN
			      RAW_DATA
			      HOLD_RAW_DATA
			      OVERLAP
			      ITERATION
			      SIGNIF
			      IS_PVAL
			      SCORE
			      FOUND_AGAIN )], @args );

    # TODO: Handle this in parser. Just pass in name parameter.
    $self->_set_id( $raw_data->[0] );

    if($is_pval) {
        $self->{'_p'} = $signif;
    } else {
        $self->{'_expect'} = $signif;
    }

    if( $hold_raw ) {
        $self->{'_hit_data'} = $raw_data;
    }

    return $self;
}

sub DESTROY {
    my $self=shift; 
    #print STDERR "-->DESTROYING $self\n";
}


#=================================================
# Begin Bio::Search::Hit::HitI implementation
#=================================================

#line 315

#----------------
sub algorithm {
#----------------
    my ($self,@args) = @_;
    return $self->{'_blast_program'};
}

#line 337

#'

#----------------
sub name {
#----------------
    my $self = shift;
    if (@_) { 
        my $name = shift;
        $name =~ s/^\s+|(\s+|,)$//g;
        $self->{'_name'} = $name;
    }
    return $self->{'_name'};
}

#line 366

#'

#----------------
sub description {
#----------------
    my( $self, $len ) = @_; 
    $len = (defined $len) ? $len : (CORE::length $self->{'_description'});
    return substr( $self->{'_description'}, 0 ,$len ); 
}

#line 391

#--------------------
sub accession {
#--------------------
    my $self = shift;
    if(@_) { $self->{'_accession'} = shift; }
    $self->{'_accession'} || '';
}

#line 412

#----------
sub raw_score { 
#----------
    my $self = shift;  

    # The check for $self->{'_score'} is a remnant from the 'query' mode days
    # in which the sbjct object would collect data from the description line only.

    my ($score);
    if(not defined($self->{'_score'})) {
	$score = $self->hsp->score;
    } else {
	$score = $self->{'_score'}; 
    } 
    return $score;
}


#line 445

#-----------
sub length {
#-----------
    my $self = shift;
    return $self->{'_length'}; 
}

#line 458

#----------------
sub significance { shift->signif( @_ ); }
#----------------


#line 474

#----------------
sub next_hsp {
#----------------
    my $self = shift;

    unless($self->{'_hsp_queue_started'}) {
        $self->{'_hsp_queue'} = [$self->hsps()];
        $self->{'_hsp_queue_started'} = 1;
    }
    pop @{$self->{'_hsp_queue'}};
}

#=================================================
# End Bio::Search::Hit::HitI implementation
#=================================================


# Providing a more explicit method for getting name of hit
# (corresponds with column name in HitTableWriter)
#----------------
sub hit_name {
#----------------
    my $self = shift;
    $self->name( @_ );
}

# Older method Delegates to description()
#----------------
sub desc { 
#----------------
    my $self = shift;
    return $self->description( @_ );
}

# Providing a more explicit method for getting description of hit
# (corresponds with column name in HitTableWriter)
#----------------
sub hit_description { 
#----------------
    my $self = shift;
    return $self->description( @_ );
}

#line 523

#----------------
sub score { shift->raw_score( @_ ); }
#----------------


#line 534

# Providing a more explicit method for getting length of hit
#----------------
sub hit_length { shift->length( @_ ); }
#----------------


#line 580

#-------------
sub signif {
#-------------
# Some duplication of logic for p(), expect() and signif() for the sake of performance.
    my ($self, $fmt) = @_;

    my $val = defined($self->{'_p'}) ? $self->{'_p'} : $self->{'_expect'};

    # $val can be zero.
    defined($val) or $self->throw("Can't get P- or Expect value: HSPs may not have been set.");

    return $val if not $fmt or $fmt =~ /^raw/i;
    ## Special formats: exponent-only or as list.
    return &Bio::Search::BlastUtils::get_exponent($val) if $fmt =~ /^exp/i;
    return (split (/eE/, $val)) if $fmt =~ /^parts/i;

    ## Default: return the raw P/Expect-value.
    return $val;
}

#----------------
sub raw_hit_data {
#----------------
    my $self = shift;
    my $data = '>';
    # Need to add blank lines where we've removed them.
    foreach( @{$self->{'_hit_data'}} ) {
        if( $_ eq 'end') {
            $data .= "\n";
        }
        else {
            $data .= /^\s*(Score|Query)/ ? "\n$_" : $_;
        }
    }
    return $data;
}


#=head2 _set_length
#
# Usage     : $hit_object->_set_length( "233" );
# Purpose   : Set the total length of the hit sequence.
# Example   : $hit_object->_set_length( $len );
# Returns   : n/a
# Argument  : Integer (only when setting). Any commas will be stripped out.
# Throws    : n/a
#
#=cut

#-----------
sub _set_length {
#-----------
    my ($self, $len) = @_;
    $len =~ s/,//g; # get rid of commas
    $self->{'_length'} = $len;
}

#=head2 _set_description
#
# Usage     : Private method; called automatically during construction
# Purpose   : Sets the description of the hit sequence.
#	    : For sequence without descriptions, does not set any description.
# Argument  : Array containing description (multiple lines).
# Comments  : Processes the supplied description:
#                1. Join all lines into one string.
#                2. Remove sequence id at the beginning of description.
#                3. Removes junk charactes at begin and end of description.
#
#=cut

#--------------
sub _set_description {
#--------------
    my( $self, @desc ) = @_;
    my( $desc);
    
#    print STDERR "BlastHit: RAW DESC:\n@desc\n";
    
    $desc = join(" ", @desc);
    
    my $name = $self->name;

    if($desc) {
	$desc =~ s/^\s*\S+\s+//; # remove the sequence ID(s)
	                         # This won't work if there's no description.
	$desc =~ s/^\s*$name//;  # ...but this should.
	$desc =~ s/^[\s!]+//;
	$desc =~ s/ \d+$//;
	$desc =~ s/\.+$//;
	$self->{'_description'} = $desc;
    }

#    print STDERR "BlastHit: _set_description =  $desc\n";
}

#line 690

#----------------
sub to_string {
#----------------
    my $self = shift;
    return "[BlastHit] " . $self->name . " " . $self->description;
}


#=head2 _set_id
#
# Usage     : Private method; automatically called by new()
# Purpose   : Sets the name of the BlastHit sequence from the BLAST summary line.
#           : The identifier is assumed to be the first
#           : chunk of non-whitespace characters in the description line
#           : Does not assume any semantics in the structure of the identifier
#           : (Formerly, this method attempted to extract database name from
#           : the seq identifiers, but this was prone to break).
# Returns   : n/a
# Argument  : String containing description line of the hit from Blast report
#           : or first line of an alignment section (with or without the leading '>').
# Throws    : Warning if cannot locate sequence ID.
#
#See Also   : L<new()|new>, L<accession()|accession>
#
#=cut

#---------------
sub _set_id {
#---------------
    my( $self, $desc ) = @_;

    # New strategy: Assume only that the ID is the first white space
    # delimited chunk. Not attempting to extract accession & database name.
    # Clients will have to interpret it as necessary.
    if($desc =~ /^>?(\S+)\s*(.*)/) {
        my ($name, $desc) = ($1, $2);
        $self->name($name);
        $self->{'_description'} = $desc;
	# Note that this description comes from the summary section of the
	# BLAST report and so may be truncated. The full description will be
	# set from the alignment section. We're setting description here in case
	# the alignment section isn't being parsed.

        # Assuming accession is delimited with | symbols (NCBI-style)
        my @pieces = split(/\|/,$name);
        my $acc = pop @pieces;
        $self->accession( $acc );
    }
    else {
        $self->warn("Can't locate sequence identifier in summary line.", "Line = $desc");
        $desc = 'Unknown sequence ID' if not $desc;
        $self->name($desc);
    }
}


#line 769

#--------------------
sub ambiguous_aln { 
#--------------------
    my $self = shift;
    if(@_) { $self->{'_ambiguous_aln'} = shift; }
    $self->{'_ambiguous_aln'} || '-';
}



#line 797

#-------------
sub overlap { 
#-------------
    my $self = shift; 
    if(@_) { $self->{'_overlap'} = shift; }
    defined $self->{'_overlap'} ? $self->{'_overlap'} : 0;
}






#line 824

#---------
sub bits { 
#---------
    my $self = shift; 

    # The check for $self->{'_bits'} is a remnant from the 'query' mode days
    # in which the sbjct object would collect data from the description line only.

    my ($bits);
    if(not defined($self->{'_bits'})) {
	$bits = $self->hsp->bits;
    } else {
	$bits = $self->{'_bits'}; 
    } 
    return $bits;
}



#line 865

#-----
sub n { 
#-----
    my $self = shift; 

    # The check for $self->{'_n'} is a remnant from the 'query' mode days
    # in which the sbjct object would collect data from the description line only.

    my ($n);
    if(not defined($self->{'_n'})) {
	$n = $self->hsp->n;
    } else {
	$n = $self->{'_n'}; 
    } 
    $n ||= $self->num_hsps;

    return $n;
}



#line 904

#----------'
sub frame { 
#----------
    my $self = shift; 

    Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};

    # The check for $self->{'_frame'} is a remnant from the 'query' mode days
    # in which the sbjct object would collect data from the description line only.

    my ($frame);
    if(not defined($self->{'_frame'})) {
	$frame = $self->hsp->frame;
    } else {
	$frame = $self->{'_frame'}; 
    } 
    return $frame;
}





#line 954

#--------
sub p { 
#--------
# Some duplication of logic for p(), expect() and signif() for the sake of performance.
    my ($self, $fmt) = @_;

    my $val = $self->{'_p'};

    # $val can be zero.
    if(not defined $val) {
        # P-value not defined, must be a NCBI Blast2 report.
        # Use expect instead.
        $self->warn( "P-value not defined. Using expect() instead.");
        $val = $self->{'_expect'};
    }

    return $val if not $fmt or $fmt =~ /^raw/i;
    ## Special formats: exponent-only or as list.
    return &Bio::Search::BlastUtils::get_exponent($val) if $fmt =~ /^exp/i;
    return (split (/eE/, $val)) if $fmt =~ /^parts/i;

    ## Default: return the raw P-value.
    return $val;
}



#line 1007

#-----------
sub expect { 
#-----------
# Some duplication of logic for p(), expect() and signif() for the sake of performance.
    my ($self, $fmt) = @_;

    my $val;

    # For Blast reports that list the P value on the description line,
    # getting the expect value requires fully parsing the HSP data.
    # For NCBI blast, there's no problem.
    if(not defined($self->{'_expect'})) {
        if( defined $self->{'_hsps'}) {
            $self->{'_expect'} = $val = $self->hsp->expect;
        } else {
            # If _expect is not set and _hsps are not set, 
            # then this must be a P-value-based report that was
            # run without setting the HSPs (shallow parsing).
            $self->throw("Can't get expect value. HSPs have not been set.");
        }
    } else {
        $val = $self->{'_expect'};
    }

    # $val can be zero.
    defined($val) or $self->throw("Can't get Expect value.");

    return $val if not $fmt or $fmt =~ /^raw/i;
    ## Special formats: exponent-only or as list.
    return &Bio::Search::BlastUtils::get_exponent($val) if $fmt =~ /^exp/i;
    return (split (/eE/, $val)) if $fmt =~ /^parts/i;

    ## Default: return the raw Expect-value.
    return $val;
}


#line 1061

#---------
sub hsps {
#---------
    my $self = shift;

    if (not ref $self->{'_hsps'}) {
	$self->throw("Can't get HSPs: data not collected.");
    }

    return wantarray 
        #  returning list containing all HSPs.
	? @{$self->{'_hsps'}}
        #  returning number of HSPs.
        : scalar(@{$self->{'_hsps'}});
}



#line 1098

#----------
sub hsp {
#----------
    my( $self, $option ) = @_;
    $option ||= 'best';
    
    if (not ref $self->{'_hsps'}) {
	$self->throw("Can't get HSPs: data not collected.");
    }

    my @hsps = @{$self->{'_hsps'}};
    
    return $hsps[0]      if $option =~ /best|first|1/i;
    return $hsps[$#hsps] if $option =~ /worst|last/i;

    $self->throw("Can't get HSP for: $option\n" .
		 "Valid arguments: 'best', 'worst'");
}



#line 1132

#-------------
sub num_hsps {
#-------------
    my $self = shift;
    
    if (not defined $self->{'_hsps'}) {
	$self->throw("Can't get HSPs: data not collected.");
    }

    return scalar(@{$self->{'_hsps'}});
}



#line 1168

#--------------------
sub logical_length {
#--------------------
    my $self = shift;
    my $seqType = shift || 'query';
    $seqType = 'sbjct' if $seqType eq 'hit';

    my $length;

    # For the sbjct, return logical sbjct length
    if( $seqType eq 'sbjct' ) {
	$length = $self->{'_logical_length'} || $self->{'_length'};
    }
    else {
        # Otherwise, return logical query length
        $length = $self->{'_query_length'};

        # Adjust length based on BLAST flavor.
        if($self->{'_blast_program'} =~ /T?BLASTX/ ) {
            $length /= 3;
        }
    }
    return $length;
}


#line 1218

#---------------'
sub length_aln {
#---------------
    my( $self, $seqType ) = @_;
    
    $seqType ||= 'query';
    $seqType = 'sbjct' if $seqType eq 'hit';

    Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};

    my $data = $self->{'_length_aln_'.$seqType};
    
    ## If we don't have data, figure out what went wrong.
    if(!$data) {
	$self->throw("Can't get length aln for sequence type \"$seqType\"" . 
		     "Valid types are 'query', 'hit', 'sbjct' ('sbjct' = 'hit')");
    }		
    $data;
}    


#line 1273

#----------
sub gaps {
#----------
    my( $self, $seqType ) = @_;

    $seqType ||= (wantarray ? 'list' : 'total');
    $seqType = 'sbjct' if $seqType eq 'hit';

    Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};

    $seqType = lc($seqType);

    if($seqType =~ /list|array/i) {
	return ($self->{'_gaps_query'}, $self->{'_gaps_sbjct'});
    }

    if($seqType eq 'total') {
	return ($self->{'_gaps_query'} + $self->{'_gaps_sbjct'}) || 0;
    } else {
	return $self->{'_gaps_'.$seqType} || 0;
    }
}    



#line 1326

#---------------
sub matches {
#---------------
    my( $self, $arg) = @_;
    my(@data,$data);

    if(!$arg) {
	@data = ($self->{'_totalIdentical'}, $self->{'_totalConserved'});

	return @data if @data;

    } else {

	if($arg =~ /^id/i) { 
	    $data = $self->{'_totalIdentical'};
	} else {
	    $data = $self->{'_totalConserved'};
	}
	return $data if $data;
    }
    
    ## Something went wrong if we make it to here.
    $self->throw("Can't get identical or conserved data: no data.");
}


#line 1377

#----------
sub start {
#----------
    my ($self, $seqType) = @_;

    $seqType ||= (wantarray ? 'list' : 'query');
    $seqType = 'sbjct' if $seqType eq 'hit';

    # If there is only one HSP, defer this call to the solitary HSP.
    if($self->num_hsps == 1) {
	return $self->hsp->start($seqType);
    } else {
	Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};
	if($seqType =~ /list|array/i) {
	    return ($self->{'_queryStart'}, $self->{'_sbjctStart'});
	} else {
	    ## Sensitive to member name changes.
	    $seqType = "_\L$seqType\E";
	    return $self->{$seqType.'Start'};
	}
    }
}


#line 1426

#----------
sub end {
#----------
    my ($self, $seqType) = @_;

    $seqType ||= (wantarray ? 'list' : 'query');
    $seqType = 'sbjct' if $seqType eq 'hit';

    # If there is only one HSP, defer this call to the solitary HSP.
    if($self->num_hsps == 1) {
	return $self->hsp->end($seqType);
    } else {
	Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};
	if($seqType =~ /list|array/i) {
	    return ($self->{'_queryStop'}, $self->{'_sbjctStop'});
	} else {
	    ## Sensitive to member name changes.
	    $seqType = "_\L$seqType\E";
	    return $self->{$seqType.'Stop'};
	}
    }
}

#line 1465

#----------
sub range {
#----------
    my ($self, $seqType) = @_;
    $seqType ||= 'query';
    $seqType = 'sbjct' if $seqType eq 'hit';
    return ($self->start($seqType), $self->end($seqType));
}


#line 1512

#------------------
sub frac_identical {
#------------------
    my ($self, $seqType) = @_;
    $seqType ||= 'query';
    $seqType = 'sbjct' if $seqType eq 'hit';

    ## Sensitive to member name format.
    $seqType = lc($seqType);

    Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};

    sprintf( "%.2f", $self->{'_totalIdentical'}/$self->{'_length_aln_'.$seqType});
}



#line 1566

#--------------------
sub frac_conserved {
#--------------------
    my ($self, $seqType) = @_;
    $seqType ||= 'query';
    $seqType = 'sbjct' if $seqType eq 'hit';

    ## Sensitive to member name format.
    $seqType = lc($seqType);

    Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};

    sprintf( "%.2f", $self->{'_totalConserved'}/$self->{'_length_aln_'.$seqType});
}




#line 1608

#----------------------
sub frac_aligned_query {
#----------------------
    my $self = shift;

    Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};

    sprintf( "%.2f", $self->{'_length_aln_query'}/$self->logical_length('query'));
}



#line 1644

#--------------------
sub frac_aligned_hit {
#--------------------
    my $self = shift;

    Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};

    sprintf( "%.2f", $self->{'_length_aln_sbjct'}/$self->logical_length('sbjct'));
}


## These methods are being maintained for backward compatibility. 

#line 1663

#----------------
sub frac_aligned_sbjct {  my $self=shift; $self->frac_aligned_hit(@_); }
#----------------

#line 1673

#----------------
sub num_unaligned_sbjct {  my $self=shift; $self->num_unaligned_hit(@_); }
#----------------



#line 1699

#---------------------
sub num_unaligned_hit {
#---------------------
    my $self = shift;

    Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};

    my $num = $self->logical_length('sbjct') - $self->{'_length_aln_sbjct'};
    ($num < 0 ? 0 : $num );
}


#line 1731

#-----------------------
sub num_unaligned_query {
#-----------------------
    my $self = shift;

    Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};

    my $num = $self->logical_length('query') - $self->{'_length_aln_query'};
    ($num < 0 ? 0 : $num );
}



#line 1773

#-------------
sub seq_inds {
#-------------
    my ($self, $seqType, $class, $collapse) = @_;

    $seqType  ||= 'query';
    $class ||= 'identical';
    $collapse ||= 0;

    $seqType = 'sbjct' if $seqType eq 'hit';

    my (@inds, $hsp);
    foreach $hsp ($self->hsps) {
	# This will merge data for all HSPs together.
	push @inds, $hsp->seq_inds($seqType, $class);
    }
    
    # Need to remove duplicates and sort the merged positions.
    if(@inds) {
	my %tmp = map { $_, 1 } @inds;
	@inds = sort {$a <=> $b} keys %tmp;
    }

    $collapse ?  &Bio::Search::BlastUtils::collapse_nums(@inds) : @inds; 
}


#line 1815

#----------------
sub iteration { shift->{'_iteration'} }
#----------------


#line 1844

#----------------
sub found_again { shift->{'_found_again'} }
#----------------


#line 1889

#----------'
sub strand {
#----------
    my ($self, $seqType) = @_;

    Bio::Search::BlastUtils::tile_hsps($self) if not $self->{'_tile_hsps'};

    $seqType ||= (wantarray ? 'list' : 'query');
    $seqType = 'sbjct' if $seqType eq 'hit';

    my ($qstr, $hstr);
    # If there is only one HSP, defer this call to the solitary HSP.
    if($self->num_hsps == 1) {
	return $self->hsp->strand($seqType);
    } 
    elsif( defined $self->{'_qstrand'}) {
        # Get the data computed during hsp tiling.
        $qstr = $self->{'_qstrand'};
        $hstr = $self->{'_sstrand'};
    }
    else {
	# otherwise, iterate through all HSPs collecting strand info.
        # This will return the string "-1/1" if there are HSPs on different strands.
        # NOTE: This was the pre-10/21/02 procedure which will no longer be used,
        # (unless the above elsif{} is commented out).
        my (%qstr, %hstr);
        foreach my $hsp( $self->hsps ) {
            my ( $q, $h ) = $hsp->strand();
            $qstr{ $q }++;
            $hstr{ $h }++;
        }
        $qstr = join( '/', sort keys %qstr);
        $hstr = join( '/', sort keys %hstr);
    }

    if($seqType =~ /list|array/i) {
        return ($qstr, $hstr);
    } elsif( $seqType eq 'query' ) {
        return $qstr;
    } else {
        return $hstr;
    }
}


1;
__END__

#####################################################################################
#                                END OF CLASS                                       #
#####################################################################################


#line 2009

1;
