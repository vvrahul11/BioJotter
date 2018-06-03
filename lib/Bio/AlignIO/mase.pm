#line 1 "Bio/AlignIO/mase.pm"
# $Id: mase.pm,v 1.9 2002/10/22 07:38:25 lapp Exp $
#
# BioPerl module for Bio::AlignIO::mase

#	based on the Bio::SeqIO::mase module
#       by Ewan Birney <birney@sanger.ac.uk>
#       and Lincoln Stein  <lstein@cshl.org>
#
#       and the SimpleAlign.pm module of Ewan Birney
#
# Copyright Peter Schattner
#
# You may distribute this module under the same terms as perl itself
# _history
# September 5, 2000
# POD documentation - main docs before the code

#line 53

# Let the code begin...

package Bio::AlignIO::mase;
use vars qw(@ISA);
use strict;

use Bio::AlignIO;

@ISA = qw(Bio::AlignIO);


#line 74

sub next_aln {
    my $self = shift;
    my $entry;
    my $name;
    my $start;
    my $end;
    my $seq;
    my $add;
    my $count = 0;
    my $seq_residues;

    my $aln =  Bio::SimpleAlign->new(-source => 'mase');


    while( $entry = $self->_readline) {
        $entry =~ /^;/ && next;
	if(  $entry =~ /^(\S+)\/(\d+)-(\d+)/ ) {
	    $name = $1;
	    $start = $2;
	    $end = $3;
	} else {
	    $entry =~ s/\s//g;
	    $name = $entry;
	    $end = -1;
	}

	$seq = "";

	while( $entry = $self->_readline) {
	    $entry =~ /^;/ && last;
	    $entry =~ s/[^A-Za-z\.\-]//g;
	    $seq .= $entry;
	}
	if( $end == -1) {
	    $start = 1;

	    $seq_residues = $seq;
	    $seq_residues =~ s/\W//g;
	    $end = length($seq_residues);
	}

	$add = new Bio::LocatableSeq('-seq'=>$seq,
			    '-id'=>$name,
			    '-start'=>$start,
			    '-end'=>$end,
			    );


       $aln->add_seq($add);


#  If $end <= 0, we have either reached the end of
#  file in <> or we have encountered some other error
#
   if ($end <= 0) { undef $aln;}

   }

   return $aln;
}



#line 148

sub write_aln {
    my ($self,@aln) = @_;

    $self->throw("Sorry: mase-format output, not yet implemented! /n");
}

1;
