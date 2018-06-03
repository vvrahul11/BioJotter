#line 1 "Bio/Annotation/SimpleValue.pm"
# $Id: SimpleValue.pm,v 1.9.2.1 2003/03/10 22:04:56 lapp Exp $
#
# BioPerl module for Bio::Annotation::SimpleValue
#
# Cared for by bioperl <bioperl-l@bio.perl.org>
#
# Copyright bioperl
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 61


# Let the code begin...


package Bio::Annotation::SimpleValue;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::AnnotationI;
#use Bio::Ontology::TermI;
use Bio::Root::Root;

@ISA = qw(Bio::Root::Root Bio::AnnotationI);

#line 89

sub new{
   my ($class,@args) = @_;

   my $self = $class->SUPER::new(@args);

   my ($value,$tag,$term) =
       $self->_rearrange([qw(VALUE TAGNAME TAG_TERM)], @args);

   # set the term first
   defined $term   && $self->tag_term($term);
   defined $value  && $self->value($value);
   defined $tag    && $self->tagname($tag);

   return $self;
}


#line 110

#line 121

sub as_text{
   my ($self) = @_;

   return "Value: ".$self->value;
}

#line 139

sub hash_tree{
   my ($self) = @_;
   
   my $h = {};
   $h->{'value'} = $self->value;
}

#line 163

sub tagname{
    my $self = shift;

    # check for presence of an ontology term
    if($self->{'_tag_term'}) {
	# keep a copy in case the term is removed later
	$self->{'tagname'} = $_[0] if @_;
	# delegate to the ontology term object
	return $self->tag_term->name(@_);
    }
    return $self->{'tagname'} = shift if @_;
    return $self->{'tagname'};
}


#line 182

#line 193

sub value{
   my ($self,$value) = @_;
   
   if( defined $value) {
      $self->{'value'} = $value;
    }
    return $self->{'value'};
}

#line 229

sub tag_term{
    my $self = shift;

    return $self->{'_tag_term'} = shift if @_;
    return $self->{'_tag_term'};
}

1;
