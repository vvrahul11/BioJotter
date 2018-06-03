#line 1 "Bio/AlignIO/selex.pm"
# $Id: selex.pm,v 1.10 2002/10/22 07:38:26 lapp Exp $
#
# BioPerl module for Bio::AlignIO::selex

#	based on the Bio::SeqIO::selex module
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

package Bio::AlignIO::selex;
use vars qw(@ISA);
use strict;
use Bio::AlignIO;

@ISA = qw(Bio::AlignIO);

#line 75

sub next_aln {
    my $self = shift;
    my $entry;
    my ($start,$end,%align,$name,$seqname,$seq,$count,%hash,%c2name, %accession, $no);
    my $aln =  Bio::SimpleAlign->new(-source => 'selex');

    # in selex format, every non-blank line that does not start
    # with '#=' is an alignment segment; the '#=' lines are mark up lines.
    # Of particular interest are the '#=GF <name/st-ed> AC <accession>'
    # lines, which give accession numbers for each segment

    while( $entry = $self->_readline) {
        $entry =~ /^\#=GS\s+(\S+)\s+AC\s+(\S+)/ && do {
	    				$accession{ $1 } = $2;
	    				next;
					};
	$entry !~ /^([^\#]\S+)\s+([A-Za-z\.\-]+)\s*/ && next;
	
	$name = $1;
	$seq = $2;

	if( ! defined $align{$name}  ) {
	    $count++;
	    $c2name{$count} = $name;
	}
	$align{$name} .= $seq;
    }

    # ok... now we can make the sequences

    $count = 0;
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
	$count++;
    }

#  If $end <= 0, we have either reached the end of
#  file in <> or we have encountered some other error
#
   if ($end <= 0) { undef $aln;}

    return $aln;
}


#line 151

sub write_aln {
    my ($self,@aln) = @_;
    my ($namestr,$seq,$add);
    my ($maxn);
    foreach my $aln (@aln) {
	$maxn = $aln->maxdisplayname_length();
	foreach $seq ( $aln->each_seq() ) {
	    $namestr = $aln->displayname($seq->get_nse());
	    $add = $maxn - length($namestr) + 2;
	    $namestr .= " " x $add;
	    $self->_print (sprintf("%s  %s\n",$namestr,$seq->seq())) or return;
	}
    }
    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

1;
