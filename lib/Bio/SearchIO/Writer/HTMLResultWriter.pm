#line 1 "Bio/SearchIO/Writer/HTMLResultWriter.pm"
# $Id: HTMLResultWriter.pm,v 1.12.2.4 2003/09/15 16:08:55 jason Exp $
#
# BioPerl module for Bio::SearchIO::Writer::HTMLResultWriter
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# Changes 2003-07-31 (jason)
# Gary has cleaned up the code a lot to produce better looking
# HTML
# POD documentation - main docs before the code

#line 129



package Bio::SearchIO::Writer::HTMLResultWriter;
use vars qw(@ISA %RemoteURLDefault
            $MaxDescLen $DATE $AlignmentLineWidth $Revision);
use strict;
$Revision = '$Id: HTMLResultWriter.pm,v 1.12.2.4 2003/09/15 16:08:55 jason Exp $'; #'

# Object preamble - inherits from Bio::Root::RootI

BEGIN {
    $DATE = localtime(time);
    %RemoteURLDefault = ( 'PROTEIN' => 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=protein&cmd=search&term=%s',			  
			  'NUCLEOTIDE' => 'http://www.ncbi.nlm.nih.gov/entrez/query.fcgi?db=nucleotide&cmd=search&term=%s'
			  );

    $MaxDescLen = 60;
    $AlignmentLineWidth = 60;
}

use Bio::Root::Root;
use Bio::SearchIO::SearchWriterI;

@ISA = qw(Bio::Root::Root Bio::SearchIO::SearchWriterI);

#line 166

sub new {
  my($class,@args) = @_;

  my $self = $class->SUPER::new(@args);
  my ($p,$n,$filters) = $self->_rearrange([qw(PROTEIN_URL 
					     NUCLEOTIDE_URL 
					     FILTERS)],@args);
  $self->remote_database_url('p',$p || $RemoteURLDefault{'PROTEIN'});
  $self->remote_database_url('n',$n || $RemoteURLDefault{'NUCLEOTIDE'});

  if( defined $filters ) {
      if( !ref($filters) =~ /HASH/i ) { 
	  $self->warn("Did not provide a hashref for the FILTERS option, ignoring.");
      } else { 
	  while( my ($type,$code) = each %{$filters} ) {
	      $self->filter($type,$code);
	  }
      }
  }

  return $self;
}

#line 203

sub remote_database_url{
   my ($self,$type,$value) = @_;
   if( ! defined $type || $type !~ /^(P|N)/i ) { 
       $self->warn("Must provide a type (PROTEIN or NUCLEOTIDE)");
       return '';
   }
   $type = uc $1;
   if( defined $value) {
      $self->{'remote_database_url'}->{$type} = $value;
    }
   return $self->{'remote_database_url'}->{$type};
}

#line 231

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

    $str .= "<table border=0>
            <tr><th>Sequences producing significant alignments:</th>
            <th>Score<br>(bits)</th><th>E<br>value</th></tr>";

    my $hspstr = '<p><p>';
    if( $result->can('rewind')) {
        $result->rewind(); # support stream based parsing routines
    }

    while( my $hit = $result->next_hit ) {
	next if( $hitfilter && ! &{$hitfilter}($hit) );
	my $nm = $hit->name();
	
	$self->debug( "no $nm for name (".$hit->description(). "\n") 
	    unless $nm;
	my ($gi,$acc) = &{$self->id_parser}($nm);
	my $p = "%-$MaxDescLen". "s";
	my $descsub;
	if( length($hit->description) > ($MaxDescLen - 3) ) {
	    $descsub = sprintf($p,
		substr($hit->description,0,$MaxDescLen-3) . "...");
	} else { 
	    $descsub = sprintf($p,$hit->description);
	}

	my $url_desc  = &{$self->hit_link_desc()}($self,$hit, $result);
	my $url_align = &{$self->hit_link_align()}($self,$hit, $result);

	my @hsps = $hit->hsps;
	
	# failover to first HSP if the data does not contain a 
	# bitscore/significance value for the Hit (NCBI XML data for one)
	
	$str .= sprintf('<tr><td>%s %s</td><td>%s</td><td><a href="#%s">%.2g</a></td></tr>'."\n",
			$url_desc, $descsub, 
			($hit->raw_score ? $hit->raw_score : 
			(defined $hsps[0] ? $hsps[0]->score : ' ')),
			$acc,
			( $hit->significance ? $hit->significance :
			 (defined $hsps[0] ? $hsps[0]->evalue : ' ')) 
			);

	$hspstr .= "<a name=\"$acc\">\n".
	    sprintf("><b>%s</b> %s\n<dd>Length = %s</dd><p>\n\n", $url_align, 
			defined $hit->description ? $hit->description : '', 
		    &_numwithcommas($hit->length));
	my $ct = 0;
	foreach my $hsp (@hsps ) {
	    next if( $hspfilter && ! &{$hspfilter}($hsp) );
	    $hspstr .= sprintf(" Score = %s bits (%s), Expect = %s",
			       $hsp->bits, $hsp->score, $hsp->evalue);
	    if( defined $hsp->pvalue ) {
		$hspstr .= ", P = ".$hsp->pvalue;
	    }
	    $hspstr .= "<br>\n";
	    $hspstr .= sprintf(" Identities = %d/%d (%d%%)",
			       ( $hsp->frac_identical('total') * 
				 $hsp->length('total')),
			       $hsp->length('total'),
			       $hsp->frac_identical('total') * 100);

	    if( $type eq 'PROTEIN' ) {
		$hspstr .= sprintf(", Positives = %d/%d (%d%%)",
				   ( $hsp->frac_conserved('total') * 
				     $hsp->length('total')),
				   $hsp->length('total'),
				   $hsp->frac_conserved('total') * 100);
	    }
	    if( $hsp->gaps ) {
		$hspstr .= sprintf(", Gaps = %d/%d (%d%%)",
				   $hsp->gaps('total'),
				   $hsp->length('total'),
				   (100 * $hsp->gaps('total') / 
				   $hsp->length('total')));
	    }
	    
	    my ($hframe,$qframe)   = ( $hsp->hit->frame, $hsp->query->frame);
	    my ($hstrand,$qstrand) = ($hsp->hit->strand,$hsp->query->strand);
	    # so TBLASTX will have Query/Hit frames
	    #    BLASTX  will have Query frame
	    #    TBLASTN will have Hit frame
	    if( $hstrand || $qstrand ) {
		$hspstr .= ", Frame = ";
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
#	    $hspstr .= "</pre></a><p>\n<pre>";
	    $hspstr .= "</a><p>\n<pre>";
	    
	    my @hspvals = ( {'name' => 'Query:',
			     'seq'  => $hsp->query_string,
			     'start' => ($qstrand >= 0 ? 
					 $hsp->query->start : 
					 $hsp->query->end),
			     'end'   => ($qstrand >= 0 ? 
					 $hsp->query->end : 
					 $hsp->query->start),
			     'index' => 0,
			     'direction' => $qstrand || 1
			     },
			    { 'name' => ' 'x6,
			      'seq'  => $hsp->homology_string,
			      'start' => undef,
			      'end'   => undef,
			      'index' => 0,
			      'direction' => 1
			      },
			    { 'name'  => 'Sbjct:',
			      'seq'   => $hsp->hit_string,
			      'start' => ($hstrand >= 0 ? 
					  $hsp->hit->start : 
					  $hsp->hit->end),
			      'end'   => ($hstrand >= 0 ? 
					  $hsp->hit->end : 
					  $hsp->hit->start),
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
		    my $piece = substr($v->{'seq'}, $v->{'index'} + $count,
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
		$hspstr .= "\n\n";
	    }
	    $hspstr .= "</pre>\n";
	}
#	$hspstr .= "</pre>\n";
    }


    # make table of search statistics and end the web page
    $str .= "</table><p>\n".$hspstr."<p><p><hr><h2>Search Parameters</h2><table border=1><tr><th>Parameter</th><th>Value</th>\n";
        
    foreach my $param ( $result->available_parameters ) {
	$str .= "<tr><td>$param</td><td>". $result->get_parameter($param) ."</td></tr>\n";
	
    }
    $str .= "</table><p><h2>Search Statistics</h2><table border=1><tr><th>Statistic</th><th>Value</th></tr>\n";
    foreach my $stat ( sort $result->available_statistics ) {
	$str .= "<tr><td>$stat</td><td>". $result->get_statistic($stat). "</td></th>\n";
    }
    $str .=  "</table><P>".$self->footer() . "<P>\n";
    return $str;
}

#line 502

sub hit_link_desc{
    my( $self, $code ) = @_; 
    if ($code) {
        $self->{'_hit_link_desc'} = $code;
    }
    return $self->{'_hit_link_desc'} || \&default_hit_link_desc;
}

#line 533

sub default_hit_link_desc {
    my($self, $hit, $result) = @_;
    my $type = ( $result->algorithm =~ /(P|X|Y)$/i ) ? 'PROTEIN' : 'NUCLEOTIDE';
    my ($gi,$acc) = &{$self->id_parser}($hit->name);

    my $url = length($self->remote_database_url($type)) > 0 ? 
              sprintf('<a href="%s">%s</a>',
                      sprintf($self->remote_database_url($type),$gi || $acc), 
                      $hit->name()) :  $hit->name();

    return $url;
}


#line 568

sub hit_link_align {
    my ($self,$code) = @_;
    if ($code) {
        $self->{'_hit_link_align'} = $code;
    }
    return $self->{'_hit_link_align'} || \&default_hit_link_desc;
}

#line 595

sub start_report {
    my( $self, $code ) = @_; 
    if ($code) {
        $self->{'_start_report'} = $code;
    }
    return $self->{'_start_report'} || \&default_start_report;
}

#line 613

sub default_start_report {
    my ($result) = @_;
    return sprintf(
    qq{<HTML>
      <HEAD> <CENTER><TITLE>Bioperl Reformatted HTML of %s output with Bioperl Bio::SearchIO system</TITLE></CENTER></HEAD>
      <!------------------------------------------------------------------->
      <!-- Generated by Bio::SearchIO::Writer::HTMLResultWriter          -->
      <!-- %s -->
      <!-- http://bioperl.org                                            -->
      <!------------------------------------------------------------------->
      <BODY BGCOLOR="WHITE">
    },$result->algorithm,$Revision);
    
}

#line 645

sub title {
    my( $self, $code ) = @_; 
    if ($code) {
        $self->{'_title'} = $code;
    }
    return $self->{'_title'} || \&default_title;
}

#line 668

sub default_title {
    my ($result) = @_;

    return sprintf(
        qq{<CENTER><H1><a href="http://bioperl.org">Bioperl</a> Reformatted HTML of %s Search Report<br> for %s</H1></CENTER>},
		    $result->algorithm,
		    $result->query_name());
}


#line 696

sub introduction {
    my( $self, $code ) = @_; 
    if ($code) {
        $self->{'_introduction'} = $code;
    }
    return $self->{'_introduction'} || \&default_introduction;
}

#line 716

sub default_introduction {
    my ($result) = @_;

    return sprintf(
    qq{
    <b>Query=</b> %s %s<br><dd>(%s letters)</dd>
    <p>
    <b>Database:</b> %s<br><dd>%s sequences; %s total letters<p></dd>
    <p>
  }, 
		   $result->query_name, 
		   $result->query_description, 
		   &_numwithcommas($result->query_length), 
		   $result->database_name(),
		   &_numwithcommas($result->database_entries()), 
		   &_numwithcommas($result->database_letters()),
		   );
}

#line 748

sub end_report {
    return "</BODY>\n</HTML>\n";
}

# copied from Bio::Index::Fasta
# useful here as well

#line 774

sub id_parser {
    my( $self, $code ) = @_;
    
    if ($code) {
        $self->{'_id_parser'} = $code;
    }
    return $self->{'_id_parser'} || \&default_id_parser;
}



#line 801

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

sub footer { 
    my ($self) = @_;
    return "<hr><h5>Produced by Bioperl module ".ref($self)." on $DATE<br>Revision: $Revision</h5>\n"
    
}

#line 838

sub algorithm_reference {
   my ($self,$result) = @_;
   return '' if( ! defined $result || !ref($result) ||
		 ! $result->isa('Bio::Search::Result::ResultI')) ;   
   if( $result->algorithm =~ /BLAST/i ) {
       my $res = $result->algorithm . ' ' . $result->algorithm_version . "<p>";
       if( $result->algorithm_version =~ /WashU/i ) {
	   return $res .
"Copyright (C) 1996-2000 Washington University, Saint Louis, Missouri USA.<br>
All Rights Reserved.<p>
<b>Reference:</b>  Gish, W. (1996-2000) <a href=\"http://blast.wustl.edu\">http://blast.wustl.edu</a><p>";	   
       } else {
	   return $res . 
"<b>Reference:</b> Altschul, Stephen F., Thomas L. Madden, Alejandro A. Schaffer,<br>
Jinghui Zhang, Zheng Zhang, Webb Miller, and David J. Lipman (1997),<br>
\"Gapped BLAST and PSI-BLAST: a new generation of protein database search<br>
programs\",  Nucleic Acids Res. 25:3389-3402.<p>";

       }       
   } elsif( $result->algorithm =~ /FAST/i ) {
       return $result->algorithm . " " . $result->algorithm_version . "<br>" .
	   "\n<b>Reference:</b> Pearson et al, Genomics (1997) 46:24-36<p>";
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

#line 888

1;
