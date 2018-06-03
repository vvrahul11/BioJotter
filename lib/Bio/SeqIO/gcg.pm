#line 1 "Bio/SeqIO/gcg.pm"
# $Id: gcg.pm,v 1.21 2002/10/25 16:22:01 jason Exp $
#
# BioPerl module for Bio::SeqIO::gcg
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#          and Lincoln Stein <lstein@cshl.org>
#
# Copyright Ewan Birney & Lincoln Stein
#
# You may distribute this module under the same terms as perl itself
#
# _history
# October 18, 1999  Largely rewritten by Lincoln Stein

# POD documentation - main docs before the code

#line 66

# Let the code begin...

package Bio::SeqIO::gcg;
use vars qw(@ISA);
use strict;

use Bio::SeqIO;
use Bio::Seq::SeqFactory;

@ISA = qw(Bio::SeqIO);

sub _initialize {
  my($self,@args) = @_;
  $self->SUPER::_initialize(@args);    
  if( ! defined $self->sequence_factory ) {
      $self->sequence_factory(new Bio::Seq::SeqFactory
			      (-verbose => $self->verbose(), 
			       -type => 'Bio::Seq::RichSeq'));      
   }
}

#line 97

sub next_seq {
   my ($self,@args)    = @_;
   my($id,$type,$desc,$line,$chksum,$sequence,$date,$len);

   while( defined($_ = $self->_readline()) ) {

       ## Get the descriptive info (anything before the line with '..')
       unless( /\.\.$/ ) { $desc.= $_; }
       ## Pull ID, Checksum & Type from the line containing '..'
       /\.\.$/ && do     { $line = $_; chomp; 
                           if(/Check\:\s(\d+)\s/) { $chksum = $1; }
                           if(/Type:\s(\w)\s/)    { $type   = $1; }
                           if(/(\S+)\s+Length/) 
			   { $id     = $1; }
			   if(/Length:\s+(\d+)\s+(\S.+\S)\s+Type/ )
			   { $len = $1; $date = $2;}
                           last; 
                         }
   }   
   return if ( !defined $_);
   chomp($desc);  # remove last "\n"

   while( defined($_ = $self->_readline()) ) {

       ## This is where we grab the sequence info.

       if( /\.\.$/ ) { 
        $self->throw("Looks like start of another sequence. See documentation. "); 
       }

       next if($_ eq "\n");       ## skip whitespace lines in formatted seq
       s/[^a-zA-Z]//g;            ## remove anything that is not alphabet char
       # $_ = uc($_);               ## uppercase sequence: NO. Keep the case. HL
       $sequence .= $_;
   }
   ##If we parsed out a checksum, we might as well test it

   if(defined $chksum) { 
       unless(_validate_checksum($sequence,$chksum)) {
	   $self->throw("Checksum failure on parsed sequence.");
       }
   }

   ## Remove whitespace from identifier because the constructor
   ## will throw a warning otherwise...
   if(defined $id) { $id =~ s/\s+//g;}

   ## Turn our parsed "Type: N" or "Type: P" (if found) into the appropriate
   ## keyword that the constructor expects...
   if(defined $type) {
       if($type eq "N") { $type = "dna";      }
       if($type eq "P") { $type = "prot";    }
   }

   return $self->sequence_factory->create(-seq  => $sequence, 
					  -id   => $id, 
					  -desc => $desc, 
					  -type => $type,
					  -dates => [ $date ]
					  );
}

#line 170

sub write_seq {
    my ($self,@seq) = @_;
    for my $seq (@seq) {
	$self->throw("Did not provide a valid Bio::PrimarySeqI object") 
	    unless defined $seq && ref($seq) && $seq->isa('Bio::PrimarySeqI');

	my $str         = $seq->seq;
	my $comment     = $seq->desc; 
	my $id          = $seq->id;
	my $type        = ( $seq->alphabet() =~ /[dr]na/i ) ? 'N' : 'P';
	my $timestamp;

	if( $seq->can('get_dates') ) {
	    ($timestamp) = $seq->get_dates;
	} else { 
	    $timestamp = localtime(time);
	}
	my($sum,$offset,$len,$i,$j,$cnt,@out);

	$len = length($str);
	## Set the offset if we have any non-standard numbering going on
	$offset=1;
	# checksum
	$sum = $self->GCG_checksum($seq);

	#Output the sequence header info
	push(@out,"$comment\n");                        
	push(@out,"$id  Length: $len  $timestamp  Type: $type  Check: $sum  ..\n\n");

	#Format the sequence
	$i = $#out + 1;
	for($j = 0 ; $j < $len ; ) {
	    if( $j % 50 == 0) {
		$out[$i] = sprintf("%8d  ",($j+$offset)); #numbering 
	    }
	    $out[$i] .= sprintf("%s",substr($str,$j,10));
	    $j += 10;
	    if( $j < $len && $j % 50 != 0 ) {
		$out[$i] .= " ";
	    }elsif($j % 50 == 0 ) {
		$out[$i++] .= "\n\n";
	    }                           
	}
	local($^W) = 0;
	if($j % 50 != 0 ) {
	    $out[$i] .= "\n";
	}
	$out[$i] .= "\n";
	return unless $self->_print(@out);
    }

    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

#line 238

sub GCG_checksum {
    my ($self,$seqobj) = @_;
    my $index = 0;
    my $checksum = 0;
    my $char;

    my $seq = $seqobj->seq();
    $seq =~ tr/a-z/A-Z/;
    
    foreach $char ( split(/[\.\-]*/, $seq)) {
	$index++;
	$checksum += ($index * (unpack("c",$char) || 0) );
	if( $index ==  57 ) {
	    $index = 0;
	}
    }

    return ($checksum % 10000);
}

#line 273

sub _validate_checksum {
    my($seq,$parsed_sum) = @_;
    my($i,$len,$computed_sum,$cnt);

    $len = length($seq);

    #Generate the GCG Checksum value

    for($i=0; $i<$len ;$i++) {             
	$cnt++;
	$computed_sum += $cnt * ord(substr($seq,$i,1));
	($cnt == 57) && ($cnt=0);
    }
    $computed_sum %= 10000;

    ## Compare and decide if success or failure

    if($parsed_sum == $computed_sum) {
	return 1;
    } else { return 0; }


}

1;
