#line 1 "Bio/SearchIO/Writer/TextResultWriter.pm"
# $Id: TextResultWriter.pm,v 1.5.2.5 2003/09/15 16:19:24 jason Exp $
#
# BioPerl module for Bio::SearchIO::Writer::TextResultWriter
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 109


# Let the code begin...


package Bio::SearchIO::Writer::TextResultWriter;
use vars qw(@ISA $MaxNameLen $MaxDescLen $AlignmentLineWidth 
	    $DescLineLen $TextWrapLoaded);
use strict;

# Object preamble - inherits from Bio::Root::RootI

BEGIN {
    $MaxDescLen = 65;
    $AlignmentLineWidth = 60;    
    eval { require Text::Wrap; $TextWrapLoaded = 1;};
    if( $@ ) {
	$TextWrapLoaded = 0;
    }
}

use Bio::Root::Root;
use Bio::SearchIO::SearchWriterI;
use POSIX;

@ISA = qw(Bio::Root::Root Bio::SearchIO::SearchWriterI);

#line 148

sub new {
  my($class,@args) = @_;

  my $self = $class->SUPER::new(@args);
  my ($filters) = $self->_rearrange([qw(FILTERS)],@args);
  if( defined $filters ) {
      if( !ref($filters) =~ /HASH/i ) { 
	  $self->warn("Did not provide a hashref for the FILTERS option, ignoring.");
      } else { 
	  while( my ($type,$code) = each %{$filters} ) {
	      $self->filter($type,$code);
	  }
      }
  }
  unless( $TextWrapLoaded ) {
      $self->warn("Could not load Text::Wrap - the Query Description will not be line wrapped\n");
  } else { 
      $Text::Wrap::columns =  $MaxDescLen;
  }
  return $self;
}


#line 186

sub to_string {
    my ($self,$result,$num) = @_; 
    $num ||= 0;
    return unless defined $result;
    my ($resultfilter,$hitfilter, $hspfilter) = ( $self->filter('RESULT'),
						  $self->filter('HIT'),
						  $self->filter('HSP') );
    return '' if( defined $resultfilter && ! &{$resultfilter}($result) );    

    my ($qtype,$dbtype,$dbseqtype,$type);
    my $alg = $result->algorithm;

    # This is actually wrong for the FASTAs I think
    if(  $alg =~ /T(FAST|BLAST)([XY])/i ) {
	$qtype      = $dbtype = 'translated';
	$dbseqtype = $type       = 'PROTEIN';
    } elsif( $alg =~ /T(FAST|BLAST)N/i ) {
	$qtype      = '';
	$dbtype     = 'translated';
	$type       = 'PROTEIN';
	$dbseqtype  = 'NUCLEOTIDE';
    } elsif( $alg =~ /(FAST|BLAST)N/i || 
	     $alg =~ /(WABA|EXONERATE)/i ) {
	$qtype      = $dbtype = '';
	$type = $dbseqtype  = 'NUCLEOTIDE';
    } elsif( $alg =~ /(FAST|BLAST)P/  || $alg =~ /SSEARCH/i ) {
	$qtype      = $dbtype = '';
	$type = $dbseqtype  = 'PROTEIN';
    } elsif( $alg =~ /(FAST|BLAST)[XY]/i ) {
	$qtype      = 'translated';
        $dbtype     = 'PROTEIN';
	$dbseqtype  = $type      = 'PROTEIN';
    } else { 
	print STDERR "algorithm was ", $result->algorithm, " couldn't match\n";
    }
    
    
    my %baselens = ( 'Sbjct:'   => ( $dbtype eq 'translated' )  ? 3 : 1,
		     'Query:'   => ( $qtype  eq 'translated' )  ? 3 : 1);

    my $str;
    if( ! defined $num || $num <= 1 ) { 
	$str = &{$self->start_report}($result);
    }

    $str .= &{$self->title}($result);

    $str .= $result->algorithm_reference || $self->algorithm_reference($result);
    $str .= &{$self->introduction}($result);


    $str .= qq{
                                                                 Score       E
Sequences producing significant alignments:                      (bits)    value
};
    my $hspstr = '';
    if( $result->can('rewind')) {
        $result->rewind(); # support stream based parsing routines
    }
    while( my $hit = $result->next_hit ) {
	next if( defined $hitfilter && ! &{$hitfilter}($hit) );
	my $nm = $hit->name();
	$self->debug( "no $nm for name (".$hit->description(). "\n") 
	    unless $nm;
	my ($gi,$acc) = &{$self->id_parser}($nm);
	my $p = "%-$MaxDescLen". "s";
	my $descsub;
	my $desc = sprintf("%s %s",$nm,$hit->description);
	if( length($desc) - 3 > $MaxDescLen) {
	    $descsub = sprintf($p,
			       substr($desc,0,$MaxDescLen-3) . 
			       "...");
	} else { 
	    $descsub = sprintf($p,$desc);
	}

	$str .= sprintf("%s   %-4s  %s\n",
			$descsub,
			defined $hit->raw_score ? $hit->raw_score : ' ',
			defined $hit->significance ? $hit->significance : '?');
	my @hsps = $hit->hsps;
	
	$hspstr .= sprintf(">%s %s\n%9sLength = %d\n\n",
			   $hit->name, 
			   defined $hit->description ? $hit->description : '', 
			   '', # empty is for the %9s in the str formatting 
			   $hit->length);
	
	foreach my $hsp ( @hsps ) { 
	    next if( defined $hspfilter && ! &{$hspfilter}($hsp) );
	    $hspstr .= sprintf(" Score = %4s bits (%s), Expect = %s",
			       $hsp->bits, $hsp->score, $hsp->evalue);
	    if( $hsp->pvalue ) {
		$hspstr .= ", P = ".$hsp->pvalue;
	    }
	    $hspstr .= "\n";
	    $hspstr .= sprintf(" Identities = %d/%d (%d%%)",
			         ( $hsp->frac_identical('total') * 
				   $hsp->length('total')),
			       $hsp->length('total'),
			       POSIX::floor($hsp->frac_identical('total') 
					    * 100));

	    if( $type eq 'PROTEIN' ) {
		$hspstr .= sprintf(", Positives = %d/%d (%d%%)",
				   ( $hsp->frac_conserved('total') * 
				     $hsp->length('total')),
				   $hsp->length('total'),
				   POSIX::floor($hsp->frac_conserved('total') * 100));
		
	    }
	    if( $hsp->gaps ) {
		$hspstr .= sprintf(", Gaps = %d/%d (%d%%)",
				   $hsp->gaps('total'),
				   $hsp->length('total'),
				   POSIX::floor(100 * $hsp->gaps('total') / 
					       $hsp->length('total')));
	    }
	    $hspstr .= "\n";
	    my ($hframe,$qframe)   = ( $hsp->hit->frame, 
				       $hsp->query->frame);
	    my ($hstrand,$qstrand) = ($hsp->hit->strand,$hsp->query->strand);
	    # so TBLASTX will have Query/Hit frames
	    #    BLASTX  will have Query frame
	    #    TBLASTN will have Hit frame
	    if( $hstrand || $qstrand ) {
		$hspstr .= " Frame = ";
		my ($signq, $signh);
		unless( $hstrand ) {
		    $hframe = undef;
		    # if strand is null or 0 then it is protein
		    # and this no frame
		} else { 
		    $signh = $hstrand < 0 ? '-' : '+';
		}
		unless( $qstrand  ) {
		    $qframe = undef;
		    # if strand is null or 0 then it is protein
		} else { 
		    $signq =$qstrand < 0 ? '-' : '+';
		}
		# remember bioperl stores frames as 0,1,2 (GFF way)
		# BLAST reports reports as 1,2,3 so
		# we have to add 1 to the frame values
		if( defined $hframe && ! defined $qframe) {  
		    $hspstr .= "$signh".($hframe+1);
		} elsif( defined $qframe && ! defined $hframe) {  
		    $hspstr .= "$signq".($qframe+1);
		} else { 
		    $hspstr .= sprintf(" %s%d / %s%d",
				       $signq,$qframe+1,
				       $signh, $hframe+1);
		}
	    }
	    $hspstr .= "\n\n";
	    
	    my @hspvals = ( {'name'  => 'Query:',
			     'seq'   => $hsp->query_string,
			     'start' => ( $hstrand >= 0 ? 
					  $hsp->query->start : 
					  $hsp->query->end),
			     'end'   => ($qstrand >= 0 ? 
					 $hsp->query->end : 
					 $hsp->query->start),
			     'index' => 0,
			     'direction' => $qstrand || 1
			     },
			    { 'name' => ' 'x6, # this might need to adjust for long coordinates??
			      'seq'  => $hsp->homology_string,
			      'start' => undef,
			      'end'   => undef,
			      'index' => 0,
			      'direction' => 1
			      },
			    { 'name'  => 'Sbjct:',
			      'seq'   => $hsp->hit_string,
			      'start' => ($hstrand >= 0 ? 
					  $hsp->hit->start : $hsp->hit->end),
			      'end'   => ($hstrand >= 0 ? 
					  $hsp->hit->end : $hsp->hit->start),
			      'index' => 0,
			      'direction' => $hstrand || 1
			      }
			    );	    
	    
	    
	    # let's set the expected length (in chars) of the starting number
	    # in an alignment block so we can have things line up
	    # Just going to try and set to the largest
	    
	    my ($numwidth) = sort { $b <=> $a }(length($hspvals[0]->{'start'}),
						length($hspvals[0]->{'end'}),
						length($hspvals[2]->{'start'}),
						length($hspvals[2]->{'end'}));
	    my $count = 0;
	    while ( $count <= $hsp->length('total') ) {
		foreach my $v ( @hspvals ) {
		    my $piece = substr($v->{'seq'}, $v->{'index'} +$count,
				       $AlignmentLineWidth);
		    my $cp = $piece;
		    my $plen = scalar ( $cp =~ tr/\-//);
		    my ($start,$end) = ('','');
		    if( defined $v->{'start'} ) { 
			$start = $v->{'start'};
			# since strand can be + or - use the direction
			# to signify which whether to add or substract from end
			my $d = $v->{'direction'} * ( $AlignmentLineWidth - $plen )*
			    $baselens{$v->{'name'}};
			if( length($piece) < $AlignmentLineWidth ) {
			    $d = (length($piece) - $plen) * $v->{'direction'} * 
				$baselens{$v->{'name'}};
			}
			$end   = $v->{'start'} + $d - $v->{'direction'};
			$v->{'start'} += $d;
		    }
		    $hspstr .= sprintf("%s %-".$numwidth."s %s %s\n",
				       $v->{'name'},
				       $start,
				       $piece,
				       $end
				       );
		}
		$count += $AlignmentLineWidth;
		$hspstr .= "\n";
	    }
	}
	$hspstr .= "\n";
    }
    $str .= "\n\n".$hspstr;
    
    $str .= sprintf(qq{  Database: %s
    Posted date:  %s
  Number of letters in database: %s
  Number of sequences in database: %s

Matrix: %s
}, 		   
		    $result->database_name(),
		    $result->get_statistic('posted_date') || 
		    POSIX::strftime("%b %d, %Y %I:%M %p",localtime),
		    &_numwithcommas($result->database_entries()), 
		    &_numwithcommas($result->database_letters()),
		    $result->get_parameter('matrix') || '');

    if( defined (my $open = $result->get_parameter('gapopen')) ) {
	$str .= sprintf("Gap Penalties Existence: %d, Extension: %d\n",
			$open || 0, $result->get_parameter('gapext') || 0);
    }

    # skip those params we've already output
    foreach my $param ( grep { ! /matrix|gapopen|gapext/i } 
			$result->available_parameters ) {
	$str .= "$param: ". $result->get_parameter($param) ."\n";
	
    }
    $str .= "Search Statistics\n";
    # skip posted date, we already output it
   foreach my $stat ( sort grep { ! /posted_date/ } 
		      $result->available_statistics ) {
       my $expect = $result->get_parameter('expect');
       my $v = $result->get_statistic($stat);
       if( $v =~ /^\d+$/ ) {
	   $v = &_numwithcommas($v);
       }
       if( defined $expect && 
	   $stat eq 'seqs_better_than_cutoff' ) {
	   $str .= "seqs_better_than_$expect: $v\n";
       } else { 
	   my $v = 
	   $str .= "$stat: $v\n";
       }
    }
    $str .=  "\n\n";
    return $str;
}


#line 482

sub start_report {
    my( $self, $code ) = @_; 
    if ($code) {
        $self->{'_start_report'} = $code;
    }
    return $self->{'_start_report'} || \&default_start_report;
}

#line 500

sub default_start_report {
    my ($result) = @_;
    return "";    
}

#line 522

sub title {
    my( $self, $code ) = @_; 
    if ($code) {
        $self->{'_title'} = $code;
    }
    return $self->{'_title'} || \&default_title;
}

#line 541

sub default_title {
    my ($result) = @_;
    return "";
# The HTML implementation
#    return sprintf(
#        qq{<CENTER><H1><a href="http://bioperl.org">Bioperl</a> Reformatted HTML of %s Search Report<br> for %s</H1></CENTER>},
#		    $result->algorithm,
#		    $result->query_name());
}


#line 570

sub introduction {
    my( $self, $code ) = @_; 
    if ($code) {
        $self->{'_introduction'} = $code;
    }
    return $self->{'_introduction'} || \&default_introduction;
}

#line 590

sub default_introduction {
    my ($result) = @_;

    return sprintf(
    qq{
Query= %s
       (%s letters)

Database: %s
           %s sequences; %s total letters
}, 
		   &_linewrap($result->query_name . " " . 
			      $result->query_description), 
		   &_numwithcommas($result->query_length), 
		   $result->database_name(),
		   &_numwithcommas($result->database_entries()), 
		   &_numwithcommas($result->database_letters()),
		   );
}

#line 623

sub end_report {
    return "";
}


# copied from Bio::Index::Fasta
# useful here as well

#line 650

sub id_parser {
    my( $self, $code ) = @_;
    
    if ($code) {
        $self->{'_id_parser'} = $code;
    }
    return $self->{'_id_parser'} || \&default_id_parser;
}



#line 673

sub default_id_parser {    
    my ($string) = @_;
    my ($gi,$acc);
    if( $string =~ s/gi\|(\d+)\|?// ) 
    { $gi = $1; $acc = $1;}
    
    if( $string =~ /(\w+)\|([A-Z\d\.\_]+)(\|[A-Z\d\_]+)?/ ) {
	$acc = defined $2 ? $2 : $1;
    } else {
        $acc = $string;
	$acc =~ s/^\s+(\S+)/$1/;
	$acc =~ s/(\S+)\s+$/$1/;	
    } 
    return ($gi,$acc);
}
	
sub MIN { $a <=> $b ? $a : $b; }
sub MAX { $a <=> $b ? $b : $a; }


#line 705

sub algorithm_reference{
   my ($self,$result) = @_;
   return '' if( ! defined $result || !ref($result) ||
		 ! $result->isa('Bio::Search::Result::ResultI')) ;   
   if( $result->algorithm =~ /BLAST/i ) {
       my $res = $result->algorithm . ' '. $result->algorithm_version. "\n";
       if( $result->algorithm_version =~ /WashU/i ) {
	   return $res .qq{
Copyright (C) 1996-2000 Washington University, Saint Louis, Missouri USA.
All Rights Reserved.
 
Reference:  Gish, W. (1996-2000) http://blast.wustl.edu
};	   
       } else {
	   return $res . qq{
Reference: Altschul, Stephen F., Thomas L. Madden, Alejandro A. Schaffer,
Jinghui Zhang, Zheng Zhang, Webb Miller, and David J. Lipman (1997),
"Gapped BLAST and PSI-BLAST: a new generation of protein database search
programs",  Nucleic Acids Res. 25:3389-3402.
};
       }       
   } elsif( $result->algorithm =~ /FAST/i ) {
       return $result->algorithm. " ". $result->algorithm_version . "\n".
	   "\nReference: Pearson et al, Genomics (1997) 46:24-36\n";
   } else { 
       return '';
   }
}

# from Perl Cookbook 2.17
sub _numwithcommas {
    my $num = reverse( $_[0] );
    $num =~ s/(\d{3})(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $num;
}

sub _linewrap {
    my ($str) = @_;
    if($TextWrapLoaded) {
	return Text::Wrap::wrap("","",$str); # use Text::Wrap
    } else { return $str; }     # cannot wrap
}
#line 763


1;
