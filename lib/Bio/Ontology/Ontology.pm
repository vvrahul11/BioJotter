#line 1 "Bio/Ontology/Ontology.pm"
# $Id: Ontology.pm,v 1.2.2.4 2003/03/27 10:07:56 lapp Exp $
#
# BioPerl module for Bio::Ontology::Ontology
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2003.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2003.
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

#line 97


# Let the code begin...


package Bio::Ontology::Ontology;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;
use Bio::Ontology::OntologyI;
use Bio::Ontology::SimpleOntologyEngine;

@ISA = qw(Bio::Root::Root Bio::Ontology::OntologyI);

#line 124

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);
    my ($name,$auth,$def,$id,$engine) =
	$self->_rearrange([qw(NAME
			      AUTHORITY
			      DEFINITION
			      IDENTIFIER
			      ENGINE)
			   ],
			  @args);
    defined($name) && $self->name($name);
    defined($auth) && $self->authority($auth);
    defined($def) && $self->definition($def);
    defined($id) && $self->identifier($id);
    $engine = Bio::Ontology::SimpleOntologyEngine->new() unless $engine;
    $self->engine($engine);

    return $self;
}

#line 150

#line 162

sub name{
    my $self = shift;

    return $self->{'name'} = shift if @_;
    return $self->{'name'};
}

#line 189

sub authority{
    my $self = shift;

    return $self->{'authority'} = shift if @_;
    return $self->{'authority'};
}

#line 208

sub definition{
    my $self = shift;

    return $self->{'definition'} = shift if @_;
    return $self->{'definition'};
}

#line 234

sub identifier{
    my $self = shift;

    if(@_) {
	$self->throw("cannot modify identifier for ".ref($self))
	    if exists($self->{'identifier'});
	my $id = shift;
	$self->{'identifier'} = $id if $id;
    }
    if(! exists($self->{'identifier'})) {
	($self->{'identifier'}) = "$self" =~ /(0x[0-9a-fA-F]+)/;
    }
    return $self->{'identifier'};
}

#line 265

sub close{
    my $self = shift;

    # if it is in the ontology store, remove it from there
    my $store = Bio::Ontology::OntologyStore->get_instance();
    $store->remove_ontology($self);
    # essentially we need to dis-associate from the engine here
    $self->engine(undef);
    return 1;
}

#line 280

#line 294

sub engine{
    my $self = shift;

    if(@_) {
	my $engine = shift;
	if($engine && (! (ref($engine) &&
			  $engine->isa("Bio::Ontology::OntologyEngineI")))) {
	    $self->throw("object of class ".ref($engine)." does not implement".
			 " Bio::Ontology::OntologyEngineI. Bummer!");
	}
	$self->{'engine'} = $engine;
    }
    return $self->{'engine'};
}

#line 313

#line 330

sub add_term{
    my $self = shift;
    my $term = shift;

    # set ontology if not set already
    $term->ontology($self) if $term && (! $term->ontology());
    return $self->engine->add_term($term,@_);
}

#line 352

sub add_relationship{
    my $self = shift;
    my $rel = shift;

    if($rel && $rel->isa("Bio::Ontology::TermI")) {
	# we need to construct the relationship object on the fly
	my ($predicate,$object) = @_;
	$rel = Bio::Ontology::Relationship->new(-subject_term   => $rel,
						-object_term    => $object,
						-predicate_term => $predicate,
						-ontology       => $self);
    }
    # set ontology if not set already
    $rel->ontology($self) unless $rel->ontology();
    return $self->engine->add_relationship($rel);
}

#line 382

sub get_relationships{
    my $self = shift;
    my $term = shift;
    if($term) {
	# we don't need to filter in this case
	return $self->engine->get_relationships($term);
    } 
    # else we need to filter by ontology
    return grep { my $ont = $_->ontology;
		  # the first condition is a superset of the second, but
		  # we add it here for efficiency reasons, as many times
		  # it will short-cut to true and is supposedly faster than
		  # string comparison
		  ($ont == $self) || ($ont->name eq $self->name);
	      } $self->engine->get_relationships(@_);
}

#line 411

sub get_predicate_terms{
    my $self = shift;
    return grep { $_->ontology->name eq $self->name;
	      } $self->engine->get_predicate_terms(@_);
}

#line 441

sub get_child_terms{
    return shift->engine->get_child_terms(@_);
}

#line 467

sub get_descendant_terms{
    return shift->engine->get_descendant_terms(@_);
}

#line 495

sub get_parent_terms{
    return shift->engine->get_parent_terms(@_);
}

#line 521

sub get_ancestor_terms{
    return shift->engine->get_ancestor_terms(@_);
}

#line 539

sub get_leaf_terms{
    my $self = shift;
    return grep { my $ont = $_->ontology;
		  # the first condition is a superset of the second, but
		  # we add it here for efficiency reasons, as many times
		  # it will short-cut to true and is supposedly faster than
		  # string comparison
		  ($ont == $self) || ($ont->name eq $self->name);
	      } $self->engine->get_leaf_terms(@_);
}

#line 564

sub get_root_terms{
    my $self = shift;
    return grep { my $ont = $_->ontology;
		  # the first condition is a superset of the second, but
		  # we add it here for efficiency reasons, as many times
		  # it will short-cut to true and is supposedly faster than
		  # string comparison
		  ($ont == $self) || ($ont->name eq $self->name);
	      } $self->engine->get_root_terms(@_);
}

#line 592

sub get_all_terms{
    my $self = shift;
    return grep { my $ont = $_->ontology;
		  # the first condition is a superset of the second, but
		  # we add it here for efficiency reasons, as many times
		  # it will short-cut to true and is supposedly faster than
		  # string comparison
		  ($ont == $self) || ($ont->name eq $self->name);
	      } $self->engine->get_all_terms(@_);
}

#line 625

sub find_terms{
    my $self = shift;
    return grep { $_->ontology->name eq $self->name;
	      } $self->engine->find_terms(@_);
}

#line 635

#line 651

sub relationship_factory{
    return shift->engine->relationship_factory(@_);
}

#line 671

sub term_factory{
    return shift->engine->term_factory(@_);
}


#################################################################
# aliases
#################################################################

*get_relationship_types = \&get_predicate_terms;

1;
