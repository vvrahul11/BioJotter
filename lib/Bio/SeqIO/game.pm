#line 1 "Bio/SeqIO/game.pm"
# $Id: game.pm,v 1.26.2.1 2003/06/28 22:23:15 jason Exp $
#
# BioPerl module for Bio::SeqIO::game
#
# Cared for by Brad Marshall <bradmars@yahoo.com>
#
# Copyright Ewan Birney & Lincoln Stein & Brad Marshall
#
# You may distribute this module under the same terms as perl itself
# _history
# June 25, 2000     written by Brad Marshall 
#
# POD documentation - main docs before the code

#line 76

# Let the code begin...

package Bio::SeqIO::game;
use vars qw(@ISA);
use strict;
# Object preamble - inherits from Bio::Root::Object

use Bio::SeqIO;
use Bio::SeqIO::game::seqHandler;
use Bio::SeqIO::game::featureHandler;
use Bio::SeqIO::game::idHandler;
use XML::Parser::PerlSAX;
use Bio::SeqFeature::Generic;
use XML::Writer;

use Bio::Seq;

@ISA = qw(Bio::SeqIO);


sub _initialize {        
  my($self,@args) = @_;
  $self->SUPER::_initialize(@args);
  my $xmlfile           = "";
  $self->{'counter'}    = 0;
  $self->{'id_counter'} = 1;  
  $self->{'leftovers'}  = undef;
  $self->{'header'}     = undef;
  $self->{'chunkable'}  = undef;
  $self->{'xmldoc'}     = undef;

  $self->_export_subfeatures(1);
  $self->_group_subfeatures(1);
  $self->_subfeature_types('exons', 'promoters','poly_A_sites',
			   'utrs','introns','sub_SeqFeature');
  
  # filehandle is stored by superclass _initialize
}


#line 126

sub _export_subfeatures{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'_export_subfeatures'} = $value;
    }
    return $obj->{'_export_subfeatures'};

} 

#line 146

sub _group_subfeatures{
   my $obj = shift;
   if( @_ ) {
      my $value = shift;
      $obj->{'_group_subfeatures'} = $value;
    }
    return $obj->{'_group_subfeatures'};
}

#line 168

sub _subfeature_types{
   my $obj = shift;
   if( @_ ) {
      my @values = @_;
      $obj->{'_subfeature_types'} = \@values;
    }
    return @{$obj->{'_subfeature_types'}};

} 

#line 189

sub _add_subfeature_type{
   my $obj = shift;
   if( @_ ) {
      my @values = @_;
      push @{$obj->{'_subfeature_types'}}, @values;
    }
    return 1;

} 


#line 210

sub next_seq {
  my $self = shift; 


  #  The header is the top level stuff in the XML file.
  #  IE  before the first <bx-seq:seq> tag.
  #  If you don't include this in each 'chunk', the
  #  parser will barf.
  my $header;
  unless ($self->{'header'}) {
    while (my $next_line = $self->_readline) {
      if($next_line=~/<bx-seq:seq?/) {
	$header .= $`;
	$self->{'header'}=$header;
	$self->{'leftovers'} .= "<bx-seq:seq".$';
	last;
      } else {
	$header .= $next_line;
      }      
    }
    if ($self->{'header'}=~m|<bx-game:flavor>.*chunkable.*</bx-game:flavor>|) {
      $self->{'chunkable'}=1;
    }
    
  }

  my $not_top_level;
  my $xmldoc;
  my $seq;
  #  If chunkable, we read in the document until the next 
  #  TOP LEVEL sequence.
  if ($self->{'chunkable'}) {
    $xmldoc = $self->{'header'}.$self->{'leftovers'};
    while (my $next_line = $self->_readline) {
      # Maintain depth of computations and annotations. 
      # We only want TOP LEVEL seqs if chunkable.
      while ($next_line=~ m|<bx-computation:computation|g) {
	$not_top_level++;
      }
      while ($next_line=~ m|<bx-annotation:annotation|g) {
	$not_top_level++;
      }
      while ($next_line=~ m|</bx-computation:computation|g) {
	$not_top_level--;
      }
      while ($next_line=~ m|</bx-annotation:annotation|g) {
	$not_top_level--;
      }
      if($next_line=~/<bx-seq:seq?/) {
	if (!$not_top_level) {
	  $xmldoc .= $`;
	  $self->{'leftovers'} .= "<bx-seq:seq".$';
	  last;
	}
      } else {
	$xmldoc .= $next_line;
      }  
    }
    #  Make sure the 'doc chunk' has a closing tag 
    #  to make the parser happy.
    if (!$xmldoc=~m|</bx-game:game>|){
      $xmldoc .= "</bx-game:game>";
    }
    # Grab the TOP LEVEL seq..
    if ($xmldoc =~ m|</bx-seq:seq|) {
      my $handler = Bio::SeqIO::game::idHandler->new();
      my $options = {Handler=>$handler};
      my $parser  = XML::Parser::PerlSAX->new($options);
      $self->{'seqs'} = $parser->parse(Source => { String => $xmldoc });
    } else { # No sequences.
      return 0;
    }
    # Get the seq out of the array.
    $seq = @{$self->{'seqs'}}[0];
  # If not chunkable,
  # only read document into memory once!
  } elsif (!$self->{'xmldoc'}) {
    $self->{'xmldoc'}=$self->{'header'}.$self->{'leftovers'};
    while (my $next_line = $self->_readline) {
      $self->{'xmldoc'} .= $next_line;
    }
    $xmldoc=$self->{'xmldoc'};
    # Get the seq id index.
    if ($xmldoc =~ m|</bx-seq:seq|) {
      my $handler = Bio::SeqIO::game::idHandler->new();
      my $options = {Handler=>$handler};
      my $parser  = XML::Parser::PerlSAX->new($options);
      $self->{'seqs'} = $parser->parse(Source => { String => $xmldoc });
      $seq = shift @{$self->{'seqs'}};
    } else { # No sequences.
      return 0;
    }
    my $seq = @{$self->{'seqs'}}[0];
  # if we already have the doc in memory, 
  # just get the doc.
  } elsif ($self->{'xmldoc'}) {
    $xmldoc=$self->{'xmldoc'};
    $seq = shift @{$self->{'seqs'}};
  }
  #  If there's more sequences:
  if ($seq) {
    # Get the next seq.
    my $handler = Bio::SeqIO::game::seqHandler->new(-seq => $seq);
    my $options = {Handler=>$handler};
    my $parser  = XML::Parser::PerlSAX->new($options);
    my $pseq = $parser->parse(Source => { String => $xmldoc });
    # get the features.
    my $fhandler = Bio::SeqIO::game::featureHandler->new($pseq->id(),
							 $pseq->length(), 
							 $pseq->alphabet());
    $options = {Handler=>$fhandler};
    
    $parser = XML::Parser::PerlSAX->new($options);
    my $features = $parser->parse(Source => { String => $xmldoc });
    my $seq = Bio::Seq->new();
    # Build the Bioperl Seq and return it.
    foreach my $feature (@{$features}) {
      $seq->add_SeqFeature($feature);
    }
    $seq->primary_seq($pseq);
    return $seq;
  } else {
    return 0;
  }
}

#line 346

sub next_primary_seq {
  my $self=shift;

  #  The header is the top level stuff in the XML file.
  #  IE  before the first <bx-seq:seq> tag.
  #  If you don't include this in each 'chunk', the
  #  parser will barf.
  my $header;
  unless ($self->{'header'}) {
    while (my $next_line = $self->_readline) {
      if($next_line=~/<bx-seq:seq?/) {
	$header .= $`;
	$self->{'header'}=$header;
	$self->{'leftovers'} .= "<bx-seq:seq".$';
	last;
      } else {
	$header .= $next_line;
      }      
    }
    if ($self->{'header'}=~m|<bx-game:flavor>.*chunkable.*</bx-game:flavor>|) {
      $self->{'chunkable'}=1;
    }
      
  }

  my $not_top_level = 0;
  my $xmldoc;
  my $seq;
  #  If chunkable, we read in the document until the next 
  #  TOP LEVEL sequence.
  if ($self->{'chunkable'}) {
    $xmldoc = $self->{'header'}.$self->{'leftovers'};
    while (my $next_line = $self->_readline) {
      # Maintain depth of computations and annotations. 
      # We only want TOP LEVEL seqs if chunkable.
      while ($next_line=~ m|<bx-computation:computation|g) {
	$not_top_level++;
      }
      while ($next_line=~ m|<bx-annotation:annotationn|g) {
	$not_top_level++;
      }
      while ($next_line=~ m|</bx-computation:computation|g) {
	$not_top_level--;
      }
      while ($next_line=~ m|</bx-annotation:annotationn|g) {
	$not_top_level--;
      }
      if($next_line=~/<bx-seq:seq?/) {
	if (!$not_top_level) {
	  $xmldoc .= $`;
	  $self->{'leftovers'} .= "<bx-seq:seq".$';
	  last;
	}
      } else {
	$xmldoc .= $next_line;
      }  
    }
    #  Make sure the 'doc chunk' has a closing tag 
    #  to make the parser happy.
    if (!$xmldoc=~m|</bx-game:game>|){
      $xmldoc .= "</bx-game:game>";
    }
    # Grab the TOP LEVEL seq..
    if ($xmldoc =~ m|</bx-seq:seq|) {
      my $handler = Bio::SeqIO::game::idHandler->new();
      my $options = {Handler=>$handler};
      my $parser  = XML::Parser::PerlSAX->new($options);
      $self->{'seqs'} = $parser->parse(Source => { String => $xmldoc });
    } else { # No sequences.
      return 0;
    }
    $seq = @{$self->{'seqs'}}[0];
  # If not chunkable,
  # only read document into memory once!
  } elsif (!$self->{'xmldoc'}) {
    $self->{'xmldoc'}=$self->{'header'}.$self->{'leftovers'};
    while (my $next_line = $self->_readline) {
      $self->{'xmldoc'} .= $next_line;
    }
    $xmldoc=$self->{'xmldoc'};
    # Get the seq id index.
    if ($xmldoc =~ m|</bx-seq:seq|) {
      my $handler = Bio::SeqIO::game::idHandler->new();
      my $options = {Handler=>$handler};
      my $parser  = XML::Parser::PerlSAX->new($options);
      $self->{'seqs'} = $parser->parse(Source => { String => $xmldoc });
      $seq = shift @{$self->{'seqs'}};
    } else { # No sequences.
      return 0;
    }
    my $seq = @{$self->{'seqs'}}[0];
  # if we already have the doc in memory, 
  # just get the doc.
  } elsif ($self->{'xmldoc'}) {
    $xmldoc=$self->{'xmldoc'};
    $seq = shift @{$self->{'seqs'}};
  }

  #print $xmldoc;
    
  if ($seq) {
    # Get the next seq.
    my $handler = Bio::SeqIO::game::seqHandler->new(-seq => $seq);
    my $options = {Handler=>$handler};
    my $parser  = XML::Parser::PerlSAX->new($options);
    my $pseq = $parser->parse(Source => { String => $xmldoc });
    return $pseq;
  } else {
    return 0;
  }
}


#line 470

sub write_seq {
    my ($self,@seqs) = @_;

    my $bxfeat  = "http://www.bioxml.org/dtds/current/feature.dtd";
    my $bxann   = "http://www.bioxml.org/dtds/current/annotation.dtd";
    my $bxcomp  = "http://www.bioxml.org/dtds/current/computation.dtd";
    my $bxgame  = "http://www.bioxml.org/dtds/current/game.dtd";
    my $bxlink  = "http://www.bioxml.org/dtds/current/link.dtd";
    my $bxseq   = "http://www.bioxml.org/dtds/current/seq.dtd";

    my $writer = new XML::Writer(OUTPUT      => $self->_fh || \*STDOUT,
				 NAMESPACES  => 1,
				 DATA_MODE   => 1,
				 DATA_INDENT => 4,
				 PREFIX_MAP  => {
				     ''     => '', # to keep undef warnings away in XML::Writer, fill in with something as a default prefix later?
				     $bxfeat => 'bx-feature',
				     $bxann =>  'bx-annotation',
				     $bxcomp => 'bx-computation',
				     $bxgame => 'bx-game',
				     $bxlink => 'bx-link',
				     $bxseq =>  'bx-seq'
				     });
    $writer->xmlDecl("UTF-8");
    $writer->doctype("bx-game:game", 'game', $bxgame);
    $writer ->startTag ([$bxgame, 'game']);
    $writer->startTag  ([$bxgame, 'flavor']);
    $writer->characters('chunkable');
    $writer->endTag    ([$bxgame, 'flavor']);

    foreach my $seq (@seqs) {
	$writer->startTag([$bxseq, 'seq'], 
			  [$bxseq, 'id'] => $seq->display_id,
			  [$bxseq, 'length'] => $seq->length,
			  [$bxseq, 'type'] => $seq->alphabet);
	if ($seq->length > 0) {
	    $writer->startTag([$bxseq, 'residues']);
	    $writer->characters($seq->seq);
	    $writer->endTag([$bxseq, 'residues']);
	}
	$writer->endTag([$bxseq, 'seq']);

	my @feats = $seq->all_SeqFeatures;

	my $features;
	foreach my $feature (@feats) {
	    if ($feature->has_tag('annotation_id')) {
		my @ann_id = $feature->each_tag_value('annotation_id');
		push (@{$features->{'annotations'}->{$ann_id[0]}}, $feature);
	    } elsif ($feature->has_tag('computation_id')) {
		my @comp_id = $feature->each_tag_value('computation_id');
		push (@{$features->{'computations'}->{$comp_id[0]}}, $feature);
	    } else {
		push (@{$features->{'everybody_else'}}, $feature);
	    }
	}
	foreach my $key (keys %{$features->{'annotations'}}) {
	    $writer->startTag([$bxann, 'annotation'],
			      [$bxann, 'id']=>$key
			      );
	    $writer->startTag([$bxann, 'seq_link']);
	    $writer->startTag([$bxlink, 'link']);
	    $writer->emptyTag([$bxlink, 'ref_link'],
			      [$bxlink, 'ref'] => $seq->display_id());
	    $writer->endTag([$bxlink, 'link']);
	    $writer->endTag([$bxann, 'seq_link']);					   
	    $self->__draw_feature_set($writer, $seq, $bxann, "", @{$features->{'annotations'}->{$key}});
	    $writer->endTag([$bxann, 'annotation']);
	}

	foreach my $key (keys %{$features->{'computations'}}) {
	    $writer->startTag([$bxcomp, 'computation'],
			      [$bxcomp, 'id']=>$key
			      );
	    $writer->startTag([$bxcomp, 'seq_link']);
	    $writer->startTag([$bxlink, 'link']);
	    $writer->emptyTag([$bxlink, 'ref_link'],
			      [$bxlink, 'ref'] => $seq->display_id());
	    $writer->endTag([$bxlink, 'link']);
	    $writer->endTag([$bxcomp, 'seq_link']);
	    $self->__draw_feature_set($writer, $seq, $bxcomp, "", @{$features->{'computations'}->{$key}});   
	    $writer->endTag([$bxcomp, 'computation']);
	}
	foreach my $feature (@{$features->{'everybody_else'}}) {
	    $self->__draw_feature($writer, $feature, $seq, "", 
				  $self->_export_subfeatures());
	}
    }
    $writer->endTag([$bxgame, 'game']);

    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}


#these two subroutines are very specific!

sub __draw_feature_set {
    my ($self, $writer, $seq, $namespace, $parent, @features) = @_;
    my ($feature_set_id);

    my $bxfeat = "http://www.bioxml.org/dtds/current/feature.dtd";

    if ($self->_export_subfeatures() && $self->_group_subfeatures()) {
	$feature_set_id = $self->{'id_counter'}; $self->{'id_counter'}++;
	$writer->startTag([$namespace, 'feature_set'],
			  [$namespace, 'id'] => $feature_set_id);
	foreach my $feature (@features) {
	    $self->__draw_feature($writer, $feature, $seq, $parent , 0);  
	}
	$writer->endTag([$namespace, 'feature_set']);
	foreach my $feature (@features) {
	    foreach my $subset ($self->_subfeature_types()) {
		if (my @subfeatures = eval ( '$feature->' . $subset . '()' )) {
		    my @id = $feature->each_tag_value('id');
		    $self->__draw_feature_set($writer, $seq, $namespace, $id[0], @subfeatures);     
		}
	    }	        
	}

    } else {
	$feature_set_id = $self->{'id_counter'}; $self->{'id_counter'}++;
	$writer->startTag([$namespace, 'feature_set'],
			  [$namespace, 'id'] => $feature_set_id);
	foreach my $feature (@features) {
	    $self->__draw_feature($writer, $feature, $seq, "" , $self->_export_subfeatures());
	}
	$writer->endTag([$namespace, 'feature_set']);
    }
}


sub __draw_feature {
    my ($self, $writer, $feature, $seq, $parent, $recursive) = @_;
    my ($subfeature, $subset, @subfeatures, $score, $score_val, $score_no);
    my $bxfeat = "http://www.bioxml.org/dtds/current/feature.dtd";
    
    if (!$feature->has_tag('id')) {
	$feature->add_tag_value('id', $self->{'id_counter'});
	$self->{'id_counter'}++;
    }
    
    my @id = $feature->each_tag_value('id');
    if ($parent) {
	$writer->startTag([$bxfeat, 'feature'],
			  [$bxfeat, 'id'] => $id[0]
			  );
    } else {
	$writer->startTag([$bxfeat, 'feature'],
			  [$bxfeat, 'id'] => $id[0],
			  [$bxfeat, 'parent'] => $parent
			  );
    }    
    $writer->startTag([$bxfeat, 'type']);
    $writer->characters($feature->primary_tag());
    $writer->endTag([$bxfeat, 'type']);
    foreach $score ($feature->all_tags()) {
	next if ($score eq 'id');
	$writer->startTag([$bxfeat, 'score'],
			  [$bxfeat, 'type'] => $score 
			  );
	$score_no = 0;
	foreach $score_val ($feature->each_tag_value($score)) {
	    next unless defined $score_val;
	    $writer->characters(' ') if ($score_no > 0);
	    $writer->characters($score_val);
	    $score_no++;
	}
	$writer->endTag([$bxfeat, 'score']);
    }

    $writer->startTag([$bxfeat, 'seq_relationship'],
		      [$bxfeat, 'seq'] => $seq->display_id,
		      [$bxfeat, 'type'] => 'query'
		      );

    $writer->startTag([$bxfeat, 'span']);
    $writer->startTag([$bxfeat, 'start']);
    $writer->characters($feature->start());
    $writer->endTag([$bxfeat, 'start']);
    $writer->startTag([$bxfeat, 'end']);
    $writer->characters($feature->end());
    $writer->endTag([$bxfeat, 'end']);
    $writer->endTag([$bxfeat, 'span']);
    $writer->endTag([$bxfeat, 'seq_relationship']);
    $writer->endTag([$bxfeat, 'feature']);

    #proces subseqfeature's, exons, introns, promotors, whatever...
    if ($recursive) {
	foreach $subset ($self->_subfeature_types()) {
	    #determine if it exists
	    if (@subfeatures = eval ( '$feature->' . $subset . '()' )) {
		foreach $subfeature (@subfeatures) {
		    $self->__draw_feature ($writer, $subfeature, $seq, $id[0], 1);
		}        
	    }
	}
    }
}

1;

