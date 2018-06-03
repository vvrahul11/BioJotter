#line 1 "Bio/AlignIO/fasta.pm"
# $Id: fasta.pm,v 1.11 2002/12/14 19:09:05 birney Exp $
#
# BioPerl module for Bio::AlignIO::fasta

#	based on the Bio::SeqIO::fasta module
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

#line 55

# Let the code begin...

package Bio::AlignIO::fasta;
use vars qw(@ISA);
use strict;

use Bio::AlignIO;
use Bio::SimpleAlign;

@ISA = qw(Bio::AlignIO);


#line 78

sub next_aln {
    my $self = shift;
    my $entry;
    my ($start,$end,$name,$seqname,$seq,$seqchar,$tempname,%align);
    my $aln =  Bio::SimpleAlign->new();

    while(defined ($entry = $self->_readline)) {
	if($entry =~ /^>(\S+)/ ) {
	    $tempname = $1;
	    if( defined $name ) {
		# put away last name and sequence

		if( $name =~ /(\S+)\/(\d+)-(\d+)/ ) {
		    $seqname = $1;
		    $start = $2;
		    $end = $3;
		} else {
		    $seqname=$name;
		    $start = 1;
		    $end = length($seqchar);   #ps 9/6/00
		}
#		print STDERR  "Going to add with $seqchar $seqname\n";
		$seq = new Bio::LocatableSeq('-seq'=>$seqchar,
				    '-id'=>$seqname,
				    '-start'=>$start,
				    '-end'=>$end,
				    );

		$aln->add_seq($seq);
	     }
	     $name = $tempname;
	     $seqchar  = "";
	     next;
	}
	$entry =~ s/[^A-Za-z\.\-]//g;
	$seqchar .= $entry;

    }
#
#  Next two lines are to silence warnings that
#  otherwise occur at EOF when using <$fh>

   if (!defined $name) {$name="";}
   if (!defined $seqchar) {$seqchar="";}

#  Put away last name and sequence
    if( $name =~ /(\S+)\/(\d+)-(\d+)/ ) {
	$seqname = $1;
	$start = $2;
	$end = $3;
    } else {
	$seqname=$name;
	$start = 1;
	$end = length($seqchar);   #ps 9/6/00
#	$end = length($align{$name});
    }


#  If $end <= 0, we have either reached the end of
#  file in <> or we have encountered some other error
#
   if ($end <= 0) { undef $aln; return $aln;}

# This logic now also reads empty lines at the 
# end of the file. Skip this is seqchar and seqname is null
    if( length($seqchar) == 0 && length($seqname) == 0 ) {
	# skip
    } else {
#	print STDERR "end to add with $seqchar $seqname\n";
	$seq = new Bio::LocatableSeq('-seq'=>$seqchar,
			'-id'=>$seqname,
			'-start'=>$start,
			'-end'=>$end,
			);

	$aln->add_seq($seq);
    }

    return $aln;

}
	

#line 172

sub write_aln {
    my ($self,@aln) = @_;
    my ($seq,$rseq,$name,$count,$length,$seqsub);

    foreach my $aln (@aln) {
	if( ! $aln || ! $aln->isa('Bio::Align::AlignI')  ) { 
	    $self->warn("Must provide a Bio::Align::AlignI object when calling write_aln");
	    next;
	}
	foreach $rseq ( $aln->each_seq() ) {
	    $name = $aln->displayname($rseq->get_nse());
	    $seq  = $rseq->seq();	
	    $self->_print (">$name\n") or return ;	
	    $count =0;
	    $length = length($seq);
	    while( ($count * 60 ) < $length ) {
		$seqsub = substr($seq,$count*60,60);
		$self->_print ("$seqsub\n") or return ;
		$count++;
	    }
	}
    }
    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

1;
