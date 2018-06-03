#line 1 "Bio/AlignIO/prodom.pm"
# $Id: prodom.pm,v 1.8 2002/10/22 07:38:26 lapp Exp $
#
# BioPerl module for Bio::AlignIO::prodom

#	based on the Bio::SeqIO::prodom module
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

package Bio::AlignIO::prodom;
use vars qw(@ISA);
use strict;

use Bio::AlignIO;

@ISA = qw(Bio::AlignIO);

#line 73

sub next_aln {
    my $self = shift;
    my $entry;
    my ($acc, $fake_id, $start, $end, $seq, $add, %names);

    my $aln =  Bio::SimpleAlign->new(-source => 'prodom');

    while( $entry = $self->_readline) {

       if ($entry =~ /^AC\s+(\S+)\s*$/) {         #ps 9/12/00
	   $aln->id( $1 );
       }
       elsif ($entry =~ /^AL\s+(\S+)\|(\S+)\s+(\d+)\s+(\d+)\s+\S+\s+(\S+)\s*$/){    #ps 9/12/00
	   $acc=$1;
	   $fake_id=$2;  # Accessions have _species appended
	   $start=$3;
	   $end=$4;
	   $seq=$5;
	
	   $names{'fake_id'} = $fake_id;

	   $add = new Bio::LocatableSeq('-seq'=>$seq,
			       '-id'=>$acc,
			       '-start'=>$start,
			       '-end'=>$end,
			       );
	
	   $aln->add_seq($add);
       }
       elsif ($entry =~ /^CO/) {
	   # the consensus line marks the end of the alignment part of the entry
	   last;
       }
   }

#  If $end <= 0, we have either reached the end of
#  file in <> or we have encountered some other error
#
   if ($end <= 0) { undef $aln;}


   return $aln;
}



#line 130

sub write_aln {
    my ($self,@aln) = @_;

    $self->throw("Sorry: prodom-format output, not yet implemented! /n");
}

1;
