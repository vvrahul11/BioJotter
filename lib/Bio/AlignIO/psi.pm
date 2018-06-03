#line 1 "Bio/AlignIO/psi.pm"
# $Id: psi.pm,v 1.6 2002/12/23 19:36:39 jason Exp $
#
# BioPerl module for Bio::AlignIO::psi
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 61


# Let the code begin...


package Bio::AlignIO::psi;
use vars qw(@ISA $BlockLen $IdLength);
use strict;

$BlockLen = 100; 
$IdLength = 13;

# Object preamble - inherits from Bio::Root::Root

use Bio::SimpleAlign;
use Bio::AlignIO;
use Bio::LocatableSeq;

@ISA = qw(Bio::AlignIO);

#line 90

#line 100

sub next_aln {
    my ($self) = @_;
    my $aln;
    my %seqs;
    my @order;
    while( defined ($_ = $self->_readline ) ) {
	next if( /^\s+$/);
	if( !defined $aln ) {
	    $aln = new Bio::SimpleAlign;
	}
	my ($id,$s) = split;
	push @order, $id if( ! defined $seqs{$id});
	$seqs{$id} .= $s;
    }
    foreach my $id ( @order) {
	my $seq = new Bio::LocatableSeq(-seq => $seqs{$id},
					-id  => $id,
					-start => 1,
					-end   => length($seqs{$id}));
	$aln->add_seq($seq);
    }
    return $aln;
}

#line 135

sub write_aln {
    my ($self,$aln) = @_;
    unless( defined $aln && ref($aln) && 
	    $aln->isa('Bio::Align::AlignI') ) {
	$self->warn("Must provide a valid Bio::Align::AlignI to write_aln");
	return 0;
    }
    my $ct = 0;
    my @seqs = $aln->each_seq;
    my $len = 1;
    my $alnlen = $aln->length;
    my $idlen = $IdLength;
    my @ids = map { substr($_->display_id,0,$idlen) } @seqs;
    while( $len < $alnlen ) {
	my $start = $len;
	my $end   = $len + $BlockLen;
	if( $end > $alnlen ) { $end = $alnlen; }
	my $c = 0;
	foreach my $seq ( @seqs ) {
	    $self->_print(sprintf("%-".$idlen."s %s\n",
				  $ids[$c++],
				  $seq->subseq($start,$end)));
	}
	$self->_print("\n");
	$len += $BlockLen+1;
    }
    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

1;
