#line 1 "Bio/AlignIO/phylip.pm"
# $Id: phylip.pm,v 1.24.2.1 2003/01/26 15:52:30 jason Exp $
#
# BioPerl module for Bio::AlignIO::phylip
#
# Copyright Heikki Lehvaslaiho
#

#line 76

# Let the code begin...

package Bio::AlignIO::phylip;
use vars qw(@ISA $DEFAULTIDLENGTH $DEFAULTLINELEN);
use strict;

use Bio::SimpleAlign;
use Bio::AlignIO;

@ISA = qw(Bio::AlignIO);

BEGIN { 
    $DEFAULTIDLENGTH = 10;
    $DEFAULTLINELEN = 60;
}

#line 112

sub _initialize {
  my($self,@args) = @_;
  $self->SUPER::_initialize(@args);

  my ($interleave,$linelen,$idlinebreak,
      $idlength) = $self->_rearrange([qw(INTERLEAVED 
					 LINELENGTH
					 IDLINEBREAK
					 IDLENGTH)],@args);
  $self->interleaved(1) if( $interleave || ! defined $interleave);
  $self->idlength($idlength || $DEFAULTIDLENGTH);
  $self->id_linebreak(1) if( $idlinebreak );
  $self->line_length($linelen) if defined $linelen && $linelen > 0;
  1;
}

#line 140

sub next_aln {
    my $self = shift;
    my $entry;
    my ($seqcount, $residuecount, %hash, $name,$str,
	@names,$seqname,$start,$end,$count,$seq);
    
    my $aln =  Bio::SimpleAlign->new(-source => 'phylip');
    $entry = $self->_readline and 
        ($seqcount, $residuecount) = $entry =~ /\s*(\d+)\s+(\d+)/;
    return 0 unless $seqcount and $residuecount;
    
    # first alignment section
    my $idlen = $self->idlength;
    $count = 0;
    my $non_interleaved = ! $self->interleaved ;
    while( $entry = $self->_readline) {
	last if( $entry =~ /^\s?$/ && ! $non_interleaved );

	if( $entry =~ /^\s+(.+)$/ ) {
	    $str = $1;
	    $non_interleaved = 1;
	    $str =~ s/\s//g;
	    $count = scalar @names;
	    $hash{$count} .= $str;
	} elsif( $entry =~ /^(.{$idlen})\s+(.*)\s$/ ) {
	    $name = $1;
	    $str = $2;
	    $name =~ s/[\s\/]/_/g;
	    $name =~ s/_+$//; # remove any trailing _'s
	    push @names, $name;
	    $str =~ s/\s//g;
	    $count = scalar @names;
	    $hash{$count} = $str;
	} 
	$self->throw("Not a valid interleaved PHYLIP file!") if $count > $seqcount; 
    }
    
    unless( $non_interleaved ) {    
	# interleaved sections
	$count = 0;
	while( $entry = $self->_readline) {
	    # finish current entry
	    if($entry =~/\s*\d+\s+\d+/){
		$self->_pushback($entry);
		last;
	    }
	    $count = 0, next if $entry =~ /^\s$/;
	    
	    $entry =~ /\s*(.*)$/ && do {
		$str = $1;
		$str =~ s/\s//g;
		$count++;
		$hash{$count} .= $str;
	    };
	    $self->throw("Not a valid interleaved PHYLIP file!") if $count > $seqcount; 
	}
    }
    return 0 if scalar @names < 1;
    
    # sequence creation
    $count = 0;
    foreach $name ( @names ) {
	$count++;
	if( $name =~ /(\S+)\/(\d+)-(\d+)/ ) {
	    $seqname = $1;
	    $start = $2;
	    $end = $3;
	} else {
	    $seqname=$name;
	    $start = 1;
	    $str = $hash{$count};
	    $str =~ s/[^A-Za-z]//g;
	    $end = length($str);
	}
	# consistency test
	$self->throw("Length of sequence [$seqname] is not [$residuecount]! ") 
	    unless CORE::length($hash{$count}) == $residuecount; 

       $seq = new Bio::LocatableSeq('-seq'=>$hash{$count},
				    '-id'=>$seqname,
				    '-start'=>$start,
				    '-end'=>$end,
				    );

       $aln->add_seq($seq);

   }
   return $aln;
}


#line 241

sub write_aln {
    my ($self,@aln) = @_;
    my $count = 0;
    my $wrapped = 0;
    my $maxname;
    my ($length,$date,$name,$seq,$miss,$pad,
	%hash,@arr,$tempcount,$index,$idlength);
    
    foreach my $aln (@aln) {
	if( ! $aln || ! $aln->isa('Bio::Align::AlignI')  ) { 
	    $self->warn("Must provide a Bio::Align::AlignI object when calling write_aln");
	    next;
	}
	$self->throw("All sequences in the alignment must be the same length") 
	    unless $aln->is_flush(1) ;

	$aln->set_displayname_flat(); # plain
	$length  = $aln->length();
	$self->_print (sprintf(" %s %s\n", $aln->no_sequences, $aln->length));

	$idlength = $self->idlength();	
	foreach $seq ( $aln->each_seq() ) {
	    $name = $aln->displayname($seq->get_nse);
	    $name = substr($name, 0, $idlength) if length($name) > $idlength;
	    $name = sprintf("%-".$idlength."s",$name);	    
	    if( $self->interleaved() ) {
		$name .= '   ' ;
	    } elsif( $self->id_linebreak) { 
		$name .= "\n"; 
	    }

      #phylip needs dashes not dots 
      my $seq = $seq->seq();
      $seq=~s/\./-/g;
	    $hash{$name} = $seq;
	    push(@arr,$name);
	}

	if( $self->interleaved() ) {
	    while( $count < $length ) {	
		
		# there is another block to go!
		foreach $name ( @arr ) {
		    my $dispname = $name;
		    $dispname = '' if $wrapped;
		    $self->_print (sprintf("%".($idlength+3)."s",$dispname));
		    $tempcount = $count;
		    $index = 0;
		    while( ($tempcount + $idlength < $length) && ($index < 5)  ) {
			$self->_print (sprintf("%s ",substr($hash{$name},
							    $tempcount,
							    $idlength)));
			$tempcount += $idlength;
			$index++;
		    }
		    # last
		    if( $index < 5) {
			# space to print!
			$self->_print (sprintf("%s ",substr($hash{$name},
							    $tempcount)));
			$tempcount += $idlength;
		    }
		    $self->_print ("\n");
		}
		$self->_print ("\n");
		$count = $tempcount;
		$wrapped = 1;
	    } 			
	} else {
	    foreach $name ( @arr ) {
		my $dispname = $name;
		$dispname = '' if $wrapped;
		$self->_print (sprintf("%s%s\n",$dispname,$hash{$name}));
	    }	
	}
    }
    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

#line 332

sub interleaved{
   my ($self,$value) = @_;
   my $previous = $self->{'_interleaved'};
   if( defined $value ) { 
       $self->{'_interleaved'} = $value;
   }
   return $previous;
}

#line 352

sub idlength {
	my($self,$value) = @_;
	if (defined $value){
	   $self->{'_idlength'} = $value;
	}
	return $self->{'_idlength'};
}

#line 371

sub line_length{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'line_length'} = $value;
    }
    return $self->{'line_length'} || $DEFAULTLINELEN;

}

#line 391

sub id_linebreak{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'_id_linebreak'} = $value;
    }
    return $self->{'_id_linebreak'} || 0;
}

1;
