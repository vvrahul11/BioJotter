#line 1 "Bio/AlignIO/stockholm.pm"
# $Id: stockholm.pm,v 1.10.2.1 2003/03/14 09:14:59 heikki Exp $
#
# BioPerl module for Bio::AlignIO::stockholm

#	based on the Bio::SeqIO::stockholm module
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

#line 56

# Let the code begin...

package Bio::AlignIO::stockholm;
use vars qw(@ISA);
use strict;

use Bio::AlignIO;

@ISA = qw(Bio::AlignIO);

#line 76

sub next_aln {
    my $self = shift;
    my $entry;

    my ($start,$end,%align,$name,$seqname,$seq,$count,
	%hash,%c2name, %accession, $no);

    # in stockholm format, every non-blank line that does not start
    # with '#=' is an alignment segment; the '#=' lines are mark up lines.
    # Of particular interest are the '#=GF <name/st-ed> AC <accession>'
    # lines, which give accession numbers for each segment

    my $aln =  Bio::SimpleAlign->new(-source => 'stockholm');

    while( defined($entry = $self->_readline) ) {
        $entry !~ /\w+/ && next;

	if ($entry =~ /^#\s*STOCKHOLM\s+/) {
	    last;
	}
	else {
	    $self->throw("Not Stockholm format: Expecting \"# STOCKHOLM 1.0\"; Found \"$_\"");
	}
    }
#
#    Next section is same as for selex format
#
    while( defined($entry = $self->_readline) ) {
	# Double slash (//) signals end of file.  The flat Pfam-A data from
	# ftp://ftp.sanger.ac.uk/pub/databases/Pfam/Pfam-A.full.gz consists
	# of several concatenated Stockholm-formatted files.  The following
	# line makes it possible to parse it without this module trying to
	# read the whole file into memory.  Andreas Kähäri 10/3/2003.
	last if $entry =~ /^\/\//;

	# Extra bonus:  Get the name of the alignment.
	# Andreas Kähäri 10/3/2003.
	if ($entry =~ /^#=GF\s+AC\s+(\S+)/) {
	    $aln->id($1);
	    next;
	}

	$entry =~ /^#=GS\s+(\S+)\s+AC\s+(\S+)/ && do {
	    $accession{ $1 } = $2;
	    next;
	};
	$entry =~ /^([A-Za-z.-]+)$/ && ( $align{$name} .= $1 ) && next; 
	$entry !~ /^([^#]\S+)\s+([A-Za-z.-]+)\s*/ && next;

	
	$name = $1;
	$seq = $2;

	if( ! defined $align{$name}  ) {
	    $count++;
	    $c2name{$count} = $name;
	}
	$align{$name} .= $seq;
    }

    # ok... now we can make the sequences

     foreach $no ( sort { $a <=> $b } keys %c2name ) {
	$name = $c2name{$no};

	if( $name =~ /(\S+)\/(\d+)-(\d+)/ ) {
	    $seqname = $1;
	    $start = $2;
	    $end = $3;
	} else {
	    $seqname=$name;
	    $start = 1;
	    $end = length($align{$name});
	}
	$seq = new Bio::LocatableSeq('-seq'=>$align{$name},
			    '-id'=>$seqname,
			    '-start'=>$start,
			    '-end'=>$end,
			    '-type'=>'aligned',
				     '-accession_number' => $accession{$name},

			    );

       $aln->add_seq($seq);

   }

#  If $end <= 0, we have either reached the end of
#  file in <fh> or we have encountered some other error
#
   if ($end <= 0) { undef $aln;}

   return $aln;
}


#line 183

sub write_aln {
    my ($self,@aln) = @_;

    $self->throw("Sorry: stockholm-format output, not yet implemented! /n");
}

1;
