#line 1 "Bio/AlignIO/clustalw.pm"
# $Id: clustalw.pm,v 1.21 2002/10/22 07:38:25 lapp Exp $
#
# BioPerl module for Bio::AlignIO::clustalw

#	based on the Bio::SeqIO modules
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

#line 63

# Let the code begin...

package Bio::AlignIO::clustalw;
use vars qw(@ISA $LINELENGTH);
use strict;

use Bio::AlignIO;
use Bio::LocatableSeq;
use Bio::SimpleAlign; # to be Bio::Align::Simple

$LINELENGTH = 60;

@ISA = qw(Bio::AlignIO);

#line 96

sub _initialize {
    my ($self, @args) = @_;
    $self->SUPER::_initialize(@args);
    my ($percentages,
	$ll) = $self->_rearrange([qw(PERCENTAGES LINELENGTH)], @args);
    defined $percentages && $self->percentages($percentages);
    $self->line_length($ll || $LINELENGTH);
}

#line 117

sub next_aln {
    my ($self) = @_;

    my $first_line;
    if( defined ($first_line  = $self->_readline ) 
	&& $first_line !~ /CLUSTAL/ ) {	
	$self->warn("trying to parse a file which does not start with a CLUSTAL header");
    }
    my %alignments;
    my $aln =  Bio::SimpleAlign->new(-source => 'clustalw');
    my $order = 0;
    my %order;
    $self->{_lastline} = '';
    while( defined ($_ = $self->_readline) ) {
	next if ( /^\s+$/ );	

	my ($seqname, $aln_line) = ('', '');	
	if( /^\s*(\S+)\s*\/\s*(\d+)-(\d+)\s+(\S+)\s*$/ ) {
	    # clustal 1.4 format
	    ($seqname,$aln_line) = ("$1:$2-$3",$4);
	} elsif( /^(\S+)\s+([A-Z\-]+)\s*$/ ) {
	    ($seqname,$aln_line) = ($1,$2);
	} else { $self->{_lastline} = $_; next }
	
	if( !exists $order{$seqname} ) {
	    $order{$seqname} = $order++;
	}

	$alignments{$seqname} .= $aln_line;  
    }
    my ($sname,$start,$end);
    foreach my $name ( sort { $order{$a} <=> $order{$b} } keys %alignments ) {
	if( $name =~ /(\S+):(\d+)-(\d+)/ ) {
	    ($sname,$start,$end) = ($1,$2,$3);	    
	} else {
	    ($sname, $start) = ($name,1);
	    my $str  = $alignments{$name};
	    $str =~ s/[^A-Za-z]//g;
	    $end = length($str);
	}
	my $seq = new Bio::LocatableSeq('-seq'   => $alignments{$name},
					 '-id'    => $sname,
					 '-start' => $start,
					 '-end'   => $end);
	$aln->add_seq($seq);
    }
    undef $aln if( !defined $end || $end <= 0);
    return $aln;
}

#line 178

sub write_aln {
    my ($self,@aln) = @_;
    my ($count,$length,$seq,@seq,$tempcount,$line_len);
    $line_len = $self->line_length || $LINELENGTH;
    foreach my $aln (@aln) {
	if( ! $aln || ! $aln->isa('Bio::Align::AlignI')  ) { 
	    $self->warn("Must provide a Bio::Align::AlignI object when calling write_aln");
	    next;
	}
	my $matchline = $aln->match_line;
    
	$self->_print (sprintf("CLUSTAL W(1.81) multiple sequence alignment\n\n\n")) or return;

	$length = $aln->length();
	$count = $tempcount = 0;
	@seq = $aln->each_seq();
	my $max = 22;
	foreach $seq ( @seq ) {
	    $max = length ($aln->displayname($seq->get_nse())) 
		if( length ($aln->displayname($seq->get_nse())) > $max );
	}
	while( $count < $length ) {
	    foreach $seq ( @seq ) {
#
#  Following lines are to suppress warnings
#  if some sequences in the alignment are much longer than others.

		my ($substring);
		my $seqchars = $seq->seq();		
	      SWITCH: {
		  if (length($seqchars) >= ($count + $line_len)) {
		      $substring = substr($seqchars,$count,$line_len); 
		      last SWITCH; 
		  } elsif (length($seqchars) >= $count) {
		      $substring = substr($seqchars,$count); 
		      last SWITCH; 
		  }
		  $substring = "";
	      }
		
		$self->_print (sprintf("%-".$max."s %s\n",
				       $aln->displayname($seq->get_nse()),
				       $substring)) or return;
	    }		
	    
	    my $linesubstr = substr($matchline, $count,$line_len);
	    my $percentages = '';
	    if( $self->percentages ) {
		my ($strcpy) = ($linesubstr);
		my $count = ($strcpy =~ tr/\*//);
		$percentages = sprintf("\t%d%%", 100 * ($count / length($linesubstr)));
	    }
	    $self->_print (sprintf("%-".$max."s %s%s\n", '', $linesubstr,
				   $percentages));	    
	    $self->_print (sprintf("\n\n")) or return;
	    $count += $line_len;
	}
    }
    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

#line 252

sub percentages { 
    my ($self,$value) = @_; 
    if( defined $value) {
	$self->{'_percentages'} = $value; 
    } 
    return $self->{'_percentages'}; 
}

#line 271

sub line_length {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_line_length'} = $value;
    }
    return $self->{'_line_length'};
}

1;
