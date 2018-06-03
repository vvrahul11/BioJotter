#line 1 "Bio/Ontology/SimpleOntologyEngine.pm"
# $Id: SimpleOntologyEngine.pm,v 1.3.2.5 2003/07/03 00:41:40 lapp Exp $
#
# BioPerl module for SimpleOntologyEngine
#
# Cared for by Peter Dimitrov <dimitrov@gnf.org>
#
# Copyright Peter Dimitrov
# (c) Peter Dimitrov, dimitrov@gnf.org, 2002.
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

#line 69


# Let the code begin...


package Bio::Ontology::SimpleOntologyEngine;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::Root;
use Bio::Ontology::RelationshipFactory;
use Bio::Ontology::OntologyEngineI;
use Data::Dumper;

@ISA = qw( Bio::Root::Root Bio::Ontology::OntologyEngineI );

#line 96

sub new{
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);
#   my %param = @args;

  $self->_term_store( {} );
  $self->_relationship_store( {} );
  $self->_inverted_relationship_store( {} );
  $self->_relationship_type_store( {} );
  $self->_instantiated_terms_store( {} );

  # set defaults for the factories
  $self->relationship_factory(Bio::Ontology::RelationshipFactory->new(
				     -type => "Bio::Ontology::Relationship"));
  return $self;
}

#line 125

sub _instantiated_terms_store{
  my ($self, $value) = @_;

  if( defined $value) {
    $self->{'_instantiated_terms_store'} = $value;
  }
  return $self->{'_instantiated_terms_store'};
}

#line 149

sub mark_instantiated{
  my ($self, @terms) = @_;

  foreach my $term (@terms) {
    $self->throw( "term ".$term->identifier." not in the term store\n" )
      if !defined $self->_term_store->{$term->identifier};
    $self->_instantiated_terms_store->{$term->identifier} = 1;
  }

  return @terms;
}

#line 174

sub mark_uninstantiated{
  my ($self, @terms) = @_;

  foreach my $term (@terms) {
    $self->throw( "term ".$term->identifier." not in the term store\n" )
      if !defined $self->_term_store->{$term->identifier};
    delete $self->_instantiated_terms_store->{$term->identifier}
      if defined $self->_instantiated_terms_store->{$term->identifier};
  }

  return @terms;
}

#line 198

sub _term_store{
  my ($self, $value) = @_;

  if( defined $value) {
    if ( defined $self->{'_term_store'}) {
      $self->throw("_term_store already defined\n");
    }
    else {
      $self->{'_term_store'} = $value;
    }
  }

  return $self->{'_term_store'};
}

#line 225

sub add_term{
  my ($self, $term) = @_;
  my $term_store = $self->_term_store;

  if ( defined $term_store -> {$term->identifier}) {
    $self->throw( "term ".$term->identifier." already defined\n" );
  }
  else {
    $term_store->{$term->identifier} = $term;
    $self->_instantiated_terms_store->{$term->identifier} = 1;
  }

  return $term;
}

#line 253

sub get_term_by_identifier{
  my ($self, @ids) = @_;
  my @ans = ();

  foreach my $id (@ids) {
      my $term = $self->_term_store->{$id};
      push @ans, $term if defined $term;
  }

  return @ans;
}

#line 277

sub _get_number_rels{
  my ($self) = @_;
  my $num_rels = 0;

  foreach my $entry ($self->_relationship_store) {
    $num_rels += scalar keys %$entry;
  }
  return $num_rels;
}

#line 299

sub _get_number_terms{
  my ($self) = @_;

  return scalar $self->_filter_unmarked( values %{$self->_term_store} );

}

#line 318

sub _relationship_store{
  my ($self, $value) = @_;

  if( defined $value) {
    if ( defined $self->{'_relationship_store'}) {
      $self->throw("_relationship_store already defined\n");
    }
    else {
      $self->{'_relationship_store'} = $value;
    }
  }

  return $self->{'_relationship_store'};
}

#line 345

sub _inverted_relationship_store{
  my ($self, $value) = @_;

  if( defined $value) {
    if ( defined $self->{'_inverted_relationship_store'}) {
      $self->throw("_inverted_relationship_store already defined\n");
    }
    else {
      $self->{'_inverted_relationship_store'} = $value;
    }
  }

  return $self->{'_inverted_relationship_store'};
}

#line 372

sub _relationship_type_store{
  my ($self, $value) = @_;

  if( defined $value) {
    if ( defined $self->{'_relationship_type_store'}) {
      $self->throw("_relationship_type_store already defined\n");
    }
    else {
      $self->{'_relationship_type_store'} = $value;
    }
  }

  return $self->{'_relationship_type_store'};
}

#line 399

sub _add_relationship_simple{
   my ($self, $store, $rel, $inverted) = @_;
   my $parent_id;
   my $child_id;

   if ($inverted) {
     $parent_id = $rel->subject_term->identifier;
     $child_id = $rel->object_term->identifier;
   }
   else {
     $parent_id = $rel->object_term->identifier;
     $child_id = $rel->subject_term->identifier;
   }
   if((defined $store->{$parent_id}->{$child_id}) &&
      ($store->{$parent_id}->{$child_id}->name != $rel->predicate_term->name)){
       $self->throw("relationship ".Dumper($rel->predicate_term).
		    " between ".$parent_id." and ".$child_id.
		    " already defined as ".
		    Dumper($store->{$parent_id}->{$child_id})."\n");
   }
   else {
     $store->{$parent_id}->{$child_id} = $rel->predicate_term;
   }
}

#line 436

sub add_relationship{
   my ($self, $rel) = @_;

   $self->_add_relationship_simple($self->_relationship_store,
				   $rel, 0);
   $self->_add_relationship_simple($self->_inverted_relationship_store,
				   $rel, 1);
   $self->_relationship_type_store->{
       $self->_unique_termid($rel->predicate_term)} = $rel->predicate_term;

   return $rel;
}

#line 461

sub get_relationships{
    my $self = shift;
    my $term = shift;
    my @rels;
    my $store = $self->_relationship_store;
    my $relfact = $self->relationship_factory(); 

    my @parent_ids = $term ?
	# if a term is supplied then only get the term's parents
	(map { $_->identifier(); } $self->get_parent_terms($term)) :
	# otherwise use all parent ids
	(keys %{$store});
    # add the term as a parent too if one is supplied
    push(@parent_ids,$term->identifier) if $term;
    
    foreach my $parent_id (@parent_ids) {
	my $parent_entry = $store->{$parent_id};

	# if a term is supplied, add a relationship for the parent to the term
	# except if the parent is the term itself (we added that one before)
	if($term && ($parent_id ne $term->identifier())) {
	    my $parent_term = $self->get_term_by_identifier($parent_id);
	    push(@rels,
		 $relfact->create_object(-object_term    => $parent_term,
					 -subject_term   => $term,
					 -predicate_term =>
					    $parent_entry->{$term->identifier},
					 -ontology       => $term->ontology()
					 )
		 );
		 
	} else {
	    # otherwise, i.e., no term supplied, or the parent equals the
	    # supplied term
	    my $parent_term = $term ?
		$term : $self->get_term_by_identifier($parent_id);
	    foreach my $child_id (keys %$parent_entry) {
		my $rel_info = $parent_entry->{$child_id};

		push(@rels,
		     $relfact->create_object(-object_term    => $parent_term,
					     -subject_term   =>
					         $self->get_term_by_identifier(
							            $child_id),
					     -predicate_term => $rel_info,
					     -ontology =>$parent_term->ontology
					     )
		     );
	    }
	}
    }

    return @rels;
}

#line 528

sub get_all_relationships{
    return shift->get_relationships();
}

#line 544

sub get_predicate_terms{
  my ($self) = @_;

  return values %{$self->_relationship_type_store};
}

#line 562

sub _is_rel_type{
  my ($self, $term, @rel_types) = @_;

  foreach my $rel_type (@rel_types) {
      if($rel_type->identifier || $term->identifier) {
	  return 1 if $rel_type->identifier eq $term->identifier;
      } else {
	  return 1 if $rel_type->name eq $term->name;
      }
  }

  return 0;
}

#line 588

sub _typed_traversal{
  my ($self, $rel_store, $level, $term_id, @rel_types) = @_;
  return undef if !defined($rel_store->{$term_id});
  my %parent_entry = %{$rel_store->{$term_id}};
  my @children = keys %parent_entry;

  my @ans;

  if (@rel_types > 0) {
    @ans = ();

    foreach my $child_id (@children) {
      push @ans, $child_id
	  if $self->_is_rel_type( $rel_store->{$term_id}->{$child_id},
				  @rel_types);
    }
  }
  else {
    @ans = @children;
  }
  if ($level < 1) {
    my @ans1 = ();

    foreach my $child_id (@ans) {
      push @ans1, $self->_typed_traversal($rel_store,
					  $level - 1, $child_id, @rel_types)
	if defined $rel_store->{$child_id};
    }
    push @ans, @ans1;
  }

  return @ans;
}

#line 640

sub get_child_terms{
    my ($self, $term, @relationship_types) = @_;

    $self->throw("must provide TermI compliant object") 
	unless defined($term) && $term->isa("Bio::Ontology::TermI");

    return $self->_filter_unmarked(
               $self->get_term_by_identifier(
		   $self->_typed_traversal($self->_relationship_store,
					   1,
					   $term->identifier,
					   @relationship_types) ) );
}

#line 671

sub get_descendant_terms{
  my ($self, $term, @relationship_types) = @_;

  $self->throw("must provide TermI compliant object") 
      unless defined($term) && $term->isa("Bio::Ontology::TermI");

  return $self->_filter_unmarked(
	     $self->_filter_repeated(
	         $self->get_term_by_identifier(
		     $self->_typed_traversal($self->_relationship_store,
					     0,
					     $term->identifier,
					     @relationship_types) ) ) );
}

#line 704

sub get_parent_terms{
  my ($self, $term, @relationship_types) = @_;
  $self->throw("term must be a valid object, not undef") unless defined $term;

  return $self->_filter_unmarked(
	    $self->get_term_by_identifier(
		$self->_typed_traversal($self->_inverted_relationship_store,
					1,
					$term->identifier,
					@relationship_types) ) );
}

#line 734

sub get_ancestor_terms{
  my ($self, $term, @relationship_types) = @_;
  $self->throw("term must be a valid object, not undef") unless defined $term;

  return $self->_filter_unmarked(
	    $self->_filter_repeated(
               $self->get_term_by_identifier(
                  $self->_typed_traversal($self->_inverted_relationship_store,
					  0,
					  $term->identifier,
					  @relationship_types) ) ) );
}

#line 759

sub get_leaf_terms{
  my ($self) = @_;
  my @leaf_terms;

  foreach my $term (values %{$self->_term_store}) {
    push @leaf_terms, $term
      if !defined $self->_relationship_store->{$term->identifier} &&
	defined $self->_instantiated_terms_store->{$term->identifier};
  }

  return @leaf_terms;
}

#line 784

sub get_root_terms{
  my ($self) = @_;
  my @root_terms;

  foreach my $term (values %{$self->_term_store}) {
    push @root_terms, $term
      if !defined $self->_inverted_relationship_store->{$term->identifier} &&
	defined $self->_instantiated_terms_store->{$term->identifier};
  }

  return @root_terms;
}

#line 809

sub _filter_repeated{
  my ($self, @args) = @_;
  my %h;

  foreach my $element (@args) {
    $h{$element->identifier} = $element if !defined $h{$element->identifier};
  }

  return values %h;
}

#line 832

sub get_all_terms{
  my ($self) = @_;

  return $self->_filter_unmarked( values %{$self->_term_store} );
}

#line 858

sub find_terms{
    my ($self,@args) = @_;
    my @terms;

    my ($id,$name) = $self->_rearrange([qw(IDENTIFIER NAME)],@args);

    if(defined($id)) {
	@terms = $self->get_term_by_identifier($id);
    } else {
	@terms = $self->get_all_terms();
    }
    if(defined($name)) {
	@terms = grep { $_->name() eq $name; } @terms;
    }
    return @terms;
}


#line 891

sub relationship_factory{
    my $self = shift;

    return $self->{'relationship_factory'} = shift if @_;
    return $self->{'relationship_factory'};
}

#line 917

sub term_factory{
    my $self = shift;

    if(@_) {
	$self->warn("setting term factory, but ".ref($self).
		    " does not create terms on-the-fly");
	return $self->{'term_factory'} = shift;
    }
    return $self->{'term_factory'};
}

#line 940

sub _filter_unmarked{
  my ($self, @terms) = @_;
  my @filtered_terms = ();

  if ( scalar(@terms) >= 1) {
    foreach my $term (@terms) {
      push @filtered_terms, $term
	if defined $self->_instantiated_terms_store->{$term->identifier};
    }
  }

  return @filtered_terms;
}

#line 968

sub remove_term_by_id{
  my ($self, $id) = @_;

  if ( $self->get_term_by_identifier($id) ) {
    my $term = $self->{_term_store}->{$id};
    delete $self->{_term_store}->{$id};
    return $term;
  }
  else {
    $self->warn("Term with id '$id' is not in the term store");
    return undef;
  }
}

#line 995

sub to_string{
  my ($self) = @_;
  my $s = "";

  $s .= "-- # Terms:\n";
  $s .= scalar($self->get_all_terms)."\n";
  $s .= "-- # Relationships:\n";
  $s .= $self->_get_number_rels."\n";

  return $s;
}

#line 1028

sub _unique_termid{
    my $self = shift;
    my $term = shift;

    return $term->identifier() if $term->identifier();
    my $id = $term->ontology->name() if $term->ontology();
    if($id) { 
	$id .= '|'; 
    } else { 
	$id = ''; 
    }
    $id .= $term->name();
}


#################################################################
# aliases
#################################################################

*get_relationship_types = \&get_predicate_terms;

1;
