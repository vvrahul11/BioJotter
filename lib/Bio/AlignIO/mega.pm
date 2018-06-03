#line 1 "Bio/AlignIO/mega.pm"
# $Id: mega.pm,v 1.8 2002/10/22 07:45:10 lapp Exp $
#
# BioPerl module for Bio::AlignIO::mega
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 70


# Let the code begin...


package Bio::AlignIO::mega;
use vars qw(@ISA $MEGANAMELEN %VALID_TYPES $LINELEN $BLOCKLEN);
use strict;

use Bio::AlignIO;
use Bio::SimpleAlign;
use Bio::LocatableSeq;

BEGIN { 
  $MEGANAMELEN = 10;
  $LINELEN = 60;
  $BLOCKLEN = 10;
  %VALID_TYPES =  map {$_, 1} qw( dna rna protein standard);
}
@ISA = qw(Bio::AlignIO );


#line 109

sub next_aln{
   my ($self) = @_;
   my $entry;
   my ($alphabet,%seqs);
   
   my $aln = Bio::SimpleAlign->new(-source => 'mega');
   
   while( defined($entry = $self->_readline()) && ($entry =~ /^\s+$/) ) {}
   
   $self->throw("Not a valid MEGA file! [#mega] not starting the file!") 
       unless $entry =~ /^#mega/i;  
   
   while( defined($entry = $self->_readline() ) ) {
       local($_) = $entry;
       if(/\!Title:\s*([^\;]+)\s*/i) { $aln->id($1)}
       elsif( s/\!Format\s+([^\;]+)\s*/$1/ ) {
	   my (@fields) = split(/\s+/,$1);
	   foreach my $f ( @fields ) {
	       my ($name,$value) = split(/\=/,$f);
	       if( $name eq 'datatype' ) { 
		   $alphabet = $value;
	       } elsif( $name eq 'identical' ) {
		   $aln->match_char($value);
	       } elsif( $name eq 'indel' ) {
		   $aln->gap_char($value);
	       }
	   }
       } elsif( /^\#/ ) {
	   last;
       }   
   }
   my @order;
   while( defined($entry) ) {
       if( $entry !~ /^\s+$/ ) {
	   # this is to skip the leading '#'
	   my $seqname = substr($entry,1,$MEGANAMELEN-1);
	   $seqname =~ s/(\S+)\s+$/$1/g;
	   my $line = substr($entry,$MEGANAMELEN);
	   $line =~ s/\s+//g;
	   if( ! defined $seqs{$seqname} ) {push @order, $seqname; }
	   $seqs{$seqname} .= $line;
       }
       $entry = $self->_readline();
   }

   foreach my $seqname ( @order ) {
       my $s = $seqs{$seqname};
       $s =~ s/\-//g;
       my $end = length($s);
       my $seq = new Bio::LocatableSeq(-alphabet => $alphabet,
				       -id => $seqname,
				       -seq => $seqs{$seqname},
				       -start => 1,
				       -end   => $end);
       
       $aln->add_seq($seq);
   }
   return $aln;
}

#line 179

sub write_aln{
   my ($self,@aln) = @_;
   my $count = 0;
   my $wrapped = 0;
   my $maxname;
   
   foreach my $aln ( @aln ) {
       if( ! $aln || ! $aln->isa('Bio::Align::AlignI')  ) { 
	   $self->warn("Must provide a Bio::Align::AlignI object when calling write_aln");
	   return 0;
       } elsif( ! $aln->is_flush($self->verbose) ) {
	   $self->warn("All Sequences in the alignment must be the same length");	   
	   return 0;
       }
       $aln->match();
       my $len = $aln->length();
       my $format = sprintf('datatype=%s identical=%s indel=%s;',
			    $aln->get_seq_by_pos(1)->alphabet(),
			    $aln->match_char, $aln->gap_char);
			    
       $self->_print(sprintf("#mega\n!Title: %s;\n!Format %s\n\n\n",
			     $aln->id, $format));

       my ($count, $blockcount,$length) = ( 0,0,$aln->length());
       $aln->set_displayname_flat();
       while( $count < $length ) {
	   foreach my $seq ( $aln->each_seq ) {
	       my $seqchars = $seq->seq();
	       $blockcount = 0;
	       my $substring = substr($seqchars, $count, $LINELEN);
	       my @blocks;
	       while( $blockcount < length($substring) ) {
		   push @blocks, substr($substring, $blockcount,$BLOCKLEN);
		   $blockcount += $BLOCKLEN;
	       }
	       $self->_print(sprintf("#%-".($MEGANAMELEN-1)."s%s\n",
				     substr($aln->displayname($seq->get_nse()),
					    0,$MEGANAMELEN-2),
				     join(' ', @blocks)));	       
	   }	   
	   $self->_print("\n");
	   $count += $LINELEN;
       }
   }
   $self->flush if $self->_flush_on_write && defined $self->_fh;
   return 1;
}


1;
