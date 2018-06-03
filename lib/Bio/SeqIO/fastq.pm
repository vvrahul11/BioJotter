#line 1 "Bio/SeqIO/fastq.pm"
# BioPerl module for Bio::SeqIO::fastq
#
# Cared for by Tony Cox <avc@sanger.ac.uk>
#
# Copyright Tony Cox
#
# You may distribute this module under the same terms as perl itself
# _history
# October 29, 2001  incept data

# POD documentation - main docs before the code

#line 73

# Let the code begin...

package Bio::SeqIO::fastq;
use vars qw(@ISA);
use strict;
# Object preamble - inherits from Bio::Root::Object

use Bio::SeqIO;
use Bio::Seq::SeqFactory;

@ISA = qw(Bio::SeqIO);

sub _initialize {
  my($self,@args) = @_;
  $self->SUPER::_initialize(@args);  
  if( ! defined $self->sequence_factory ) {
      $self->sequence_factory(new Bio::Seq::SeqFactory(-verbose => $self->verbose(), -type => 'Bio::Seq::SeqWithQuality'));      
  }
}


#line 104

sub next_seq {

  my( $self ) = @_;
  my $seq;
  my $alphabet;
  local $/ = "\n\@";

  return unless my $entry = $self->_readline;

  if ($entry eq '@')  {  # very first one
    return unless $entry = $self->_readline;
  }
  my ($top,$sequence,$top2,$qualsequence) = $entry =~ /^
                                                        \@?(.+?)\n
                                                        ([^\@]*?)\n
                                                        \+?(.+?)\n
                                                        (.*)\n
                                                      /xs
    or $self->throw("Can't parse fastq entry");
  my ($id,$fulldesc) = $top =~ /^\s*(\S+)\s*(.*)/
    or $self->throw("Can't parse fastq header");
  if ($id eq '') {$id=$fulldesc;}   # FIX incase no space between \@ and name
  $sequence =~ s/\s//g;             # Remove whitespace
  $qualsequence =~ s/\s//g;
  
  if(length($sequence) != length($qualsequence)){
    $self->warn("Fastq sequence/quality data length mismatch error\n");
    $self->warn("Sequence: $top, seq length: ",length($sequence), " Qual length: ", length($qualsequence), " \n");
    $self->warn("$sequence\n");
    $self->warn("$qualsequence\n");
    $self->warn("FROM ENTRY: \n\n$entry\n");
  }

  my @qual = split('', $qualsequence);

  my $qual;
  foreach (@qual) {$qual .=  (unpack("C",$_) - 33) ." "};
  

  # for empty sequences we need to know the mol.type
  $alphabet = $self->alphabet();
  if(length($sequence) == 0) {
      if(! defined($alphabet)) {
	  # let's default to dna
	  $alphabet = "dna";
      }
  } else {
      # we don't need it really, so disable
      $alphabet = undef;
  }

  # create the SeqWithQuality object
  $seq = $self->sequence_factory->create(
					 -qual         => $qual,
					 -seq          => $sequence,
					 -id           => $id,
					 -primary_id   => $id,
					 -desc         => $fulldesc,
					 -alphabet     => $alphabet
					 );
  
  # if there wasn't one before, set the guessed type
  $self->alphabet($seq->alphabet());
  
  return $seq;
}

#line 182

sub write_seq {
   my ($self,@seq) = @_;
   foreach my $seq (@seq) {
     my $str = $seq->seq;
     my $top = $seq->display_id();
     if ($seq->can('desc') and my $desc = $seq->desc()) {
	 $desc =~ s/\n//g;
        $top .= " $desc";
     }
     if(length($str) > 0) {
	    $str =~ s/(.{1,60})/$1\n/g;
     } else {
	    $str = "\n";
     }
     
     $self->_print (">",$top,"\n",$str) or return;
   }

   $self->flush if $self->_flush_on_write && defined $self->_fh;
   return 1;
}

#line 215

sub write_qual {
   my ($self,@seq) = @_;
   foreach my $seq (@seq) {
     unless ($seq->isa("Bio::Seq::SeqWithQuality")){
        warn("You can write FASTQ without supplying a Bio::Seq::SeqWithQuality object! ", ref($seq), "\n");
        next;
     } 
     my @qual = @{$seq->qual};
     my $top = $seq->display_id();
     if ($seq->can('desc') and my $desc = $seq->desc()) {
	 $desc =~ s/\n//g;
        $top .= " $desc";
     }
     my $qual = "" ;
     if(scalar(@qual) > 0) {
        my $max = 60;
        for (my $q = 0;$q<scalar(@qual);$q++){
            $qual .= $qual[$q] . " ";
            if(length($qual) > $max){
                $qual .= "\n";
                $max += 60;
            }
        }
     } else {
	    $qual = "\n";
     }
     
     $self->_print (">",$top,"\n",$qual,"\n") or return;
   }
   return 1;
}

#line 258

sub write_fastq {
   my ($self,@seq) = @_;
   foreach my $seq (@seq) {
     unless ($seq->isa("Bio::Seq::SeqWithQuality")){
        warn("You can write FASTQ without supplying a Bio::Seq::SeqWithQuality object! ", ref($seq), "\n");
        next;
     } 
     my $str = $seq->seq;
     my @qual = @{$seq->qual};
     my $top = $seq->display_id();
     if ($seq->can('desc') and my $desc = $seq->desc()) {
	 $desc =~ s/\n//g;
        $top .= " $desc";
     }
     if(length($str) == 0) {
	    $str = "\n";
     }
     my $qual = "" ;
     if(scalar(@qual) > 0) {
        for (my $q = 0;$q<scalar(@qual);$q++){
            $qual .= chr($qual[$q] + 33);
        }
     } else {
	    $qual = "\n";
     }
     
     $self->_print ("\@",$top,"\n",$str,"\n") or return;
     $self->_print ("+",$top,"\n",$qual,"\n") or return;
   }
   return 1;
}
1;
