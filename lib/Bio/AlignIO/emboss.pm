#line 1 "Bio/AlignIO/emboss.pm"
# $Id: emboss.pm,v 1.11 2002/10/22 07:45:10 lapp Exp $
#
# BioPerl module for Bio::AlignIO::emboss
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 69


# Let the code begin...


package Bio::AlignIO::emboss;
use vars qw(@ISA $EMBOSSTitleLen $EMBOSSLineLen);
use strict;

use Bio::AlignIO;
use Bio::LocatableSeq;

@ISA = qw(Bio::AlignIO );

BEGIN { 
    $EMBOSSTitleLen    = 13;
    $EMBOSSLineLen     = 50;
}

sub _initialize {
    my($self,@args) = @_;
    $self->SUPER::_initialize(@args);
    $self->{'_type'} = undef;
}

#line 104

sub next_aln {
    my ($self) = @_;
    my $seenbegin = 0;
    my %data = ( 'seq1' => { 
		     'start'=> undef,
		     'end'=> undef,		
		     'name' => '',
		     'data' => '' },
		 'seq2' => { 
		     'start'=> undef,
		     'end'=> undef,
		     'name' => '',
		     'data' => '' },
		 'align' => '',
		 'type'  => $self->{'_type'},  # to restore type from 
		                                     # previous aln if possible
		 );
    my %names;
    while( defined($_ = $self->_readline) ) {
	next if( /^\#?\s+$/ || /^\#+\s*$/ );
	if( /^\#(\=|\-)+\s*$/) {
	    last if( $seenbegin);
	} elsif( /(Local|Global):\s*(\S+)\s+vs\s+(\S+)/ ||
		 /^\#\s+Program:\s+(\S+)/ )
	{
	    my ($name1,$name2) = ($2,$3);
	    if( ! defined $name1 ) { # Handle EMBOSS 2.2.X
		$data{'type'} = $1;
		$name1 = $name2 = '';
	    } else { 
		$data{'type'} = $1 eq 'Local' ? 'water' : 'needle';
	    }	    
	    $data{'seq1'}->{'name'} = $name1;
	    $data{'seq2'}->{'name'} = $name2;

	    $self->{'_type'} = $data{'type'};

	} elsif( /Score:\s+(\S+)/ ) {
	    $data{'score'} = $1;		
	} elsif( /^\#\s+(1|2):\s+(\S+)/ && !  $data{"seq$1"}->{'name'} ) {
	    my $nm = $2;
	    $nm = substr($nm,0,$EMBOSSTitleLen); # emboss has a max seq length
	    if( $names{$nm} ) {
		$nm .= "-". $names{$nm};
	    }
	    $names{$nm}++;
	    $data{"seq$1"}->{'name'} = $nm;	
	} elsif( $data{'seq1'}->{'name'} &&
		 /^$data{'seq1'}->{'name'}/ ) {	    
	    my $count = 0;
	    $seenbegin = 1;
	    my @current;
	    while( defined ($_) ) {
		my $align_other = '';
		my $delayed;		
		if($count == 0 || $count == 2 ) {
		    my @l = split;
		    my ($seq,$align,$start,$end);
		    if( $count == 2 && $data{'seq2'}->{'name'} eq '' ) {
			# weird boundary condition 
			($start,$align,$end) = @l;
		    } elsif( @l == 3 ) {
			$align = '';
			($seq,$start,$end) = @l
		    } else { 
			($seq,$start,$align,$end) = @l;
 		    }

		    my $seqname = sprintf("seq%d", ($count == 0) ? '1' : '2'); 
		    $data{$seqname}->{'data'} .= $align;
		    $data{$seqname}->{'start'} ||= $start;
		    $data{$seqname}->{'end'} = $end;
		    $current[$count] = [ $start,$align || ''];
		} else { 
		    s/^\s+//;
		    s/\s+$//;
		    $data{'align'} .= $_;
		}

	      BOTTOM:
		last if( $count++ == 2);
		$_ = $self->_readline();
	    }

	    if( $data{'type'} eq 'needle' ) {
		# which ever one is shorter we want to bring it up to 
		# length.  Man this stinks.
		my ($s1,$s2) =  ($data{'seq1'}, $data{'seq2'});
		
		my $d = length($current[0]->[1]) - length($current[2]->[1]);
		if( $d < 0 ) { # s1 is smaller, need to add some
		    # compare the starting points for this alignment line
		    if( $current[0]->[0] <= 1 && $current[2]->[0] > 1) { 
			$s1->{'data'} = ('-' x abs($d)) . $s1->{'data'};
			$data{'align'} = (' 'x abs($d)).$data{'align'};
		    } else { 
			$s1->{'data'} .= '-' x abs($d);
			$data{'align'} .= ' 'x abs($d);
		    }
		} elsif( $d > 0) { # s2 is smaller, need to add some  
		    if( $current[2]->[0] <= 1 && $current[0]->[0] > 1) { 
			$s2->{'data'} = ('-' x abs($d)) . $s2->{'data'};
			$data{'align'} = (' 'x abs($d)).$data{'align'};
		    } else { 
			$s2->{'data'} .= '-' x abs($d);
			$data{'align'} .= ' 'x abs($d);
		    }
		}
	    }
	    
	}
    }
    return undef unless $seenbegin;
    my $aln =  Bio::SimpleAlign->new(-verbose => $self->verbose(),
				     -source => "EMBOSS-".$data{'type'});
    
    foreach my $seqname ( qw(seq1 seq2) ) { 
	return undef unless ( defined $data{$seqname} );	
	$data{$seqname}->{'name'} ||= $seqname;
	my $seq = new Bio::LocatableSeq('-seq' => $data{$seqname}->{'data'},
					'-id'  => $data{$seqname}->{'name'},
					'-start'=> $data{$seqname}->{'start'},
					'-end' => $data{$seqname}->{'end'},
					);
	$aln->add_seq($seq);
    }
    return $aln;
}

#line 244

sub write_aln {
    my ($self,@aln) = @_;

    $self->throw("Sorry: writing emboss output is not currently available! \n");
}

1;
