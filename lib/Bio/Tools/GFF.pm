#line 1 "Bio/Tools/GFF.pm"
# $Id: GFF.pm,v 1.26 2002/11/24 21:35:40 jason Exp $
#
# BioPerl module for Bio::Tools::GFF
#
# Cared for by the Bioperl core team
#
# Copyright Matthew Pocock
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 78

# Let the code begin...

package Bio::Tools::GFF;

use vars qw(@ISA);
use strict;

use Bio::Root::IO;
use Bio::SeqAnalysisParserI;
use Bio::SeqFeature::Generic;

@ISA = qw(Bio::Root::Root Bio::SeqAnalysisParserI Bio::Root::IO);

#line 104

sub new {
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);
  
  my ($gff_version) = $self->_rearrange([qw(GFF_VERSION)],@args);

  # initialize IO
  $self->_initialize_io(@args);
    
  $gff_version ||= 2;
  if(($gff_version != 1) && ($gff_version != 2)) {
    $self->throw("Can't build a GFF object with the unknown version ".
		 $gff_version);
  }
  $self->gff_version($gff_version);
  return $self;
}

#line 135

sub next_feature {
    my ($self) = @_;
    
    my $gff_string;

    # be graceful about empty lines or comments, and make sure we return undef
    # if the input's consumed
    while(($gff_string = $self->_readline()) && defined($gff_string)) {	
	next if($gff_string =~ /^\#/ || $gff_string =~ /^\s*$/ ||
		$gff_string =~ /^\/\//);
	last;
    }
    return undef unless $gff_string;

    my $feat = Bio::SeqFeature::Generic->new();
    $self->from_gff_string($feat, $gff_string);

    return $feat;
}

#line 172

sub from_gff_string {
    my ($self, $feat, $gff_string) = @_;

    if($self->gff_version() == 1)  {
	$self->_from_gff1_string($feat, $gff_string);
    } else {
	$self->_from_gff2_string($feat, $gff_string);
    }
}

#line 194

sub _from_gff1_string {
   my ($gff, $feat, $string) = @_;
   chomp $string;
   my ($seqname, $source, $primary, $start, $end, $score, $strand, $frame, @group) = split(/\t/, $string);

   if ( !defined $frame ) {
       $feat->throw("[$string] does not look like GFF to me");
   }
   $frame = 0 unless( $frame =~ /^\d+$/);
   $feat->seq_id($seqname);
   $feat->source_tag($source);
   $feat->primary_tag($primary);
   $feat->start($start);
   $feat->end($end);
   $feat->frame($frame);
   if ( $score eq '.' ) {
       #$feat->score(undef);
   } else {
       $feat->score($score);
   }
   if ( $strand eq '-' ) { $feat->strand(-1); }
   if ( $strand eq '+' ) { $feat->strand(1); }
   if ( $strand eq '.' ) { $feat->strand(0); }
   foreach my $g ( @group ) {
       if ( $g =~ /(\S+)=(\S+)/ ) {
	   my $tag = $1;
	   my $value = $2;
	   $feat->add_tag_value($1, $2);
       } else {
	   $feat->add_tag_value('group', $g);
       }
   }
}

#line 241

sub _from_gff2_string {
   my ($gff, $feat, $string) = @_;
   chomp($string);
   # according to the Sanger website, GFF2 should be single-tab separated elements, and the
   # free-text at the end should contain text-translated tab symbols but no "real" tabs,
   # so splitting on \t is safe, and $attribs gets the entire attributes field to be parsed later
   my ($seqname, $source, $primary, $start, $end, $score, $strand, $frame, @attribs) = split(/\t+/, $string);
   my $attribs = join '', @attribs;  # just in case the rule against tab characters has been broken
   if ( !defined $frame ) {
       $feat->throw("[$string] does not look like GFF2 to me");
   }
   $feat->seq_id($seqname);
   $feat->source_tag($source);
   $feat->primary_tag($primary);
   $feat->start($start);
   $feat->end($end);
   $feat->frame($frame);
   if ( $score eq '.' ) {
       #$feat->score(undef);
   } else {
       $feat->score($score);
   }
   if ( $strand eq '-' ) { $feat->strand(-1); }
   if ( $strand eq '+' ) { $feat->strand(1); }
   if ( $strand eq '.' ) { $feat->strand(0); }


   #  <Begin Inefficient Code from Mark Wilkinson> 
   # this routine is necessay to allow the presence of semicolons in
   # quoted text Semicolons are the delimiting character for new
   # tag/value attributes.  it is more or less a "state" machine, with
   # the "quoted" flag going up and down as we pass thorugh quotes to
   # distinguish free-text semicolon and hash symbols from GFF control
   # characters
   
   
   my $flag = 0; # this could be changed to a bit and just be twiddled
   my @parsed;

   # run through each character one at a time and check it
   # NOTE: changed to foreach loop which is more efficient in perl
   # --jasons

   foreach my $a ( split //, $attribs ) { 
       # flag up on entering quoted text, down on leaving it
       if( $a eq '"') { $flag = ( $flag == 0 ) ? 1:0 }
       elsif( $a eq ';' && $flag ) { $a = "INSERT_SEMICOLON_HERE"}
       elsif( $a eq '#' && ! $flag ) { last } 
       push @parsed, $a;
   }
   $attribs = join "", @parsed; # rejoin into a single string

   # <End Inefficient Code>   
   # Please feel free to fix this and make it more "perlish"

   my @key_vals = split /;/, $attribs;   # attributes are semicolon-delimited

   foreach my $pair ( @key_vals ) {
       # replace semicolons that were removed from free-text above.
       $pair =~ s/INSERT_SEMICOLON_HERE/;/g;        

       # separate the key from the value
       my ($blank, $key, $values) = split  /^\s*([\w\d]+)\s/, $pair; 


       if( defined $values ) {
	   my @values;
	   # free text is quoted, so match each free-text block
	   # and remove it from the $values string
	   while ($values =~ s/"(.*?)"//){
	       # and push it on to the list of values (tags may have
	       # more than one value... and the value may be undef)	       
	       push @values, $1;
	   }

	   # and what is left over should be space-separated
	   # non-free-text values

	   my @othervals = split /\s+/, $values;  
	   foreach my $othervalue(@othervals){
	       # get rid of any empty strings which might 
	       # result from the split
	       if (CORE::length($othervalue) > 0) {push @values, $othervalue}  
	   }

	   foreach my $value(@values){
	       $feat->add_tag_value($key, $value);
	   }
       }
   }
}

#line 344

sub write_feature {
    my ($self, @features) = @_;
    foreach my $feature ( @features ) {
	$self->_print($self->gff_string($feature)."\n");
    }
}

#line 366

sub gff_string{
    my ($self, $feature) = @_;

    if($self->gff_version() == 1) {
	return $self->_gff1_string($feature);
    } else {
	return $self->_gff2_string($feature);
    }
}

#line 387

sub _gff1_string{
   my ($gff, $feat) = @_;
   my ($str,$score,$frame,$name,$strand);

   if( $feat->can('score') ) {
       $score = $feat->score();
   }
   $score = '.' unless defined $score;

   if( $feat->can('frame') ) {
       $frame = $feat->frame();
   }
   $frame = '.' unless defined $frame;

   $strand = $feat->strand();
   if(! $strand) {
       $strand = ".";
   } elsif( $strand == 1 ) {
       $strand = '+';
   } elsif ( $feat->strand == -1 ) {
       $strand = '-';
   }
   
   if( $feat->can('seqname') ) {
       $name = $feat->seq_id();
       $name ||= 'SEQ';
   } else {
       $name = 'SEQ';
   }


   $str = join("\t",
                 $name,
		 $feat->source_tag(),
		 $feat->primary_tag(),
		 $feat->start(),
		 $feat->end(),
		 $score,
		 $strand,
		 $frame);

   foreach my $tag ( $feat->all_tags ) {
       foreach my $value ( $feat->each_tag_value($tag) ) {
	   $str .= " $tag=$value";
       }
   }


   return $str;
}

#line 449

sub _gff2_string{
   my ($gff, $feat) = @_;
   my ($str,$score,$frame,$name,$strand);

   if( $feat->can('score') ) {
       $score = $feat->score();
   }
   $score = '.' unless defined $score;

   if( $feat->can('frame') ) {
       $frame = $feat->frame();
   }
   $frame = '.' unless defined $frame;

   $strand = $feat->strand();
   if(! $strand) {
       $strand = ".";
   } elsif( $strand == 1 ) {
       $strand = '+';
   } elsif ( $feat->strand == -1 ) {
       $strand = '-';
   }

   if( $feat->can('seqname') ) {
       $name = $feat->seq_id();
       $name ||= 'SEQ';
   } else {
       $name = 'SEQ';
   }
   $str = join("\t",
                 $name,
		 $feat->source_tag(),
		 $feat->primary_tag(),
		 $feat->start(),
		 $feat->end(),
		 $score,
		 $strand,
		 $frame);

   # the routine below is the only modification I made to the original
   # ->gff_string routine (above) as on November 17th, 2000, the
   # Sanger webpage describing GFF2 format reads: "From version 2
   # onwards, the attribute field must have a tag value structure
   # following the syntax used within objects in a .ace file,
   # flattened onto one line by semicolon separators. Tags must be
   # standard identifiers ([A-Za-z][A-Za-z0-9_]*).  Free text values
   # must be quoted with double quotes".

   # MW

   my $valuestr;
   my @all_tags = $feat->all_tags;
   if (@all_tags) {  # only play this game if it is worth playing...
       $str .= "\t"; # my interpretation of the GFF2
                     # specification suggests the need 
                     # for this additional TAB character...??
       foreach my $tag ( @all_tags ) {
	   my $valuestr; # a string which will hold one or more values 
	                 # for this tag, with quoted free text and 
	                 # space-separated individual values.
	   foreach my $value ( $feat->each_tag_value($tag) ) {
	       if ($value =~ /[^A-Za-z0-9_]/){
		   $value =~ s/\t/\\t/g; # substitute tab and newline 
		                         # characters
		   $value =~ s/\n/\\n/g; # to their UNIX equivalents
		   $value = '"' . $value . '" '} # if the value contains 
	                                         # anything other than valid 
	                                         # tag/value characters, then 
	                                         # quote it
	       $value = "\"\"" unless defined $value; 
                                              # if it is completely empty, 
	                                      # then just make empty double 
	                                      # quotes
	       $valuestr .=  $value . " "; # with a trailing space in case 
	                                   # there are multiple values
	       # for this tag (allowed in GFF2 and .ace format)		
	   }
	   $str .= "$tag $valuestr ; ";	# semicolon delimited with no '=' sign
       }
       chop $str; chop $str  # remove the trailing semicolon and space
       }
   return $str;
}

#line 544

sub gff_version {
  my ($self, $value) = @_;
  if(defined $value && (($value == 1) || ($value == 2))) {
    $self->{'GFF_VERSION'} = $value;
  }
  return $self->{'GFF_VERSION'};
}

# Make filehandles

#line 567

sub newFh {
  my $class = shift;
  return unless my $self = $class->new(@_);
  return $self->fh;
}

#line 586


sub fh {
  my $self = shift;
  my $class = ref($self) || $self;
  my $s = Symbol::gensym;
  tie $$s,$class,$self;
  return $s;
}

sub DESTROY {
    my $self = shift;

    $self->close();
}

sub TIEHANDLE {
    my ($class,$val) = @_;
    return bless {'gffio' => $val}, $class;
}

sub READLINE {
  my $self = shift;
  return $self->{'gffio'}->next_feature() unless wantarray;
  my (@list, $obj);
  push @list, $obj while $obj = $self->{'gffio'}->next_feature();
  return @list;
}

sub PRINT {
  my $self = shift;
  $self->{'gffio'}->write_feature(@_);
}

1;

