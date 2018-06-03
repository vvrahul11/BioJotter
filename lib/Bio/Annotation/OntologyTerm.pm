#line 1 "Bio/Annotation/OntologyTerm.pm"
# $Id: OntologyTerm.pm,v 1.4.2.2 2003/04/04 15:53:20 lapp Exp $
#
# BioPerl module for Bio::Annotation::OntologyTerm
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

# 
# (c) Hilmar Lapp, hlapp at gmx.net, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# POD documentation - main docs before the code

#line 89


# Let the code begin...


package Bio::Annotation::OntologyTerm;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::AnnotationI;
use Bio::Ontology::TermI;
use Bio::Ontology::Term;
use Bio::Root::Root;

@ISA = qw(Bio::Root::Root Bio::AnnotationI Bio::Ontology::TermI);

#line 119

sub new{
    my ($class,@args) = @_;
    
    my $self = $class->SUPER::new(@args);
    
    my ($term,$name,$label,$identifier,$definition,$ont,$tag) =
	$self->_rearrange([qw(TERM
			      NAME
			      LABEL
			      IDENTIFIER
			      DEFINITION
			      ONTOLOGY
			      TAGNAME)],
			  @args);
    if($term) {
	$self->term($term);
    } else {
	$self->name($name || $label) if $name || $label;
	$self->identifier($identifier) if $identifier;
	$self->definition($definition) if $definition;
    }
    $self->ontology($ont || $tag) if $ont || $tag;

    return $self;
}


#line 150

#line 161

sub as_text{
   my ($self) = @_;

   return $self->tagname()."|".$self->name()."|".$self->identifier();
}

#line 179

sub hash_tree{
   my ($self) = @_;
   
   my $h = {};
   $h->{'name'} = $self->name();
   $h->{'identifier'} = $self->identifier();
   $h->{'definition'} = $self->definition();
   $h->{'synonyms'} = [$self->each_synonym()];
}


#line 207

sub tagname{
    my $self = shift;

    return $self->ontology(@_) if @_;
    # if in get mode we need to get the name from the ontology
    my $ont = $self->ontology();
    return ref($ont) ? $ont->name() : $ont;
}

#line 220

#line 235

sub term{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'term'} = $value;
    }
    if(! exists($self->{'term'})) {
	$self->{'term'} = Bio::Ontology::Term->new();
    }
    return $self->{'term'};
}

#line 258

sub identifier {
    return shift->term()->identifier(@_);
} # identifier

#line 274

sub name {
    return shift->term()->name(@_);
} # name


#line 291

sub definition {
    return shift->term()->definition(@_);
} # definition

#line 309

sub ontology {
    return shift->term()->ontology(@_);
}

#line 325

sub is_obsolete {
    return shift->term()->is_obsolete(@_);
} # is_obsolete

#line 341

sub comment {
    return shift->term()->comment(@_);
} # comment

#line 355

sub get_synonyms {
    return shift->term()->get_synonyms(@_);
} # get_synonyms

#line 371

sub add_synonym {
    return shift->term()->add_synonym(@_);
} # add_synonym


#line 386

sub remove_synonyms {
    return shift->term()->remove_synonyms(@_);
} # remove_synonyms

#line 400

sub get_dblinks {
    return shift->term->get_dblinks(@_);
} # get_dblinks


#line 419

sub add_dblink {
    return shift->term->add_dblink(@_);
} # add_dblink


#line 434

sub remove_dblinks {
    return shift->term->remove_dblinks(@_);
} # remove_dblinks

#line 452

sub get_secondary_ids {
    return shift->term->get_secondary_ids(@_);
} # get_secondary_ids


#line 469

sub add_secondary_id {
    return shift->term->add_secondary_id(@_);
} # add_secondary_id


#line 484

sub remove_secondary_ids {
    return shift->term->remove_secondary_ids(@_);
} # remove_secondary_ids


1;
