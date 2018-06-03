#line 1 "Bio/Ontology/Relationship.pm"
# $Id: Relationship.pm,v 1.4.2.3 2003/03/27 10:07:56 lapp Exp $
#
# BioPerl module for Relationship
#
# Cared for by Christian M. Zmasek <czmasek@gnf.org> or <cmzmasek@yahoo.com>
#
# (c) Christian M. Zmasek, czmasek@gnf.org, 2002.
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
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 98


# Let the code begin...


package Bio::Ontology::Relationship;
use vars qw( @ISA );
use strict;
use Bio::Root::Root;
use Bio::Ontology::TermI;
use Bio::Ontology::RelationshipI;

@ISA = qw( Bio::Root::Root
           Bio::Ontology::RelationshipI );




#line 131

sub new {

    my( $class, @args ) = @_;
    
    my $self = $class->SUPER::new( @args );
   
    my ( $identifier,
         $subject_term,
	 $child,        # for backwards compatibility
         $object_term,
	 $parent,       # for backwards compatibility
         $predicate_term,
	 $reltype,      # for backwards compatibility
	 $ont)
	= $self->_rearrange( [qw( IDENTIFIER
				  SUBJECT_TERM
				  CHILD_TERM
				  OBJECT_TERM
				  PARENT_TERM
				  PREDICATE_TERM
				  RELATIONSHIP_TYPE
				  ONTOLOGY)
			      ], @args );
   
    $self->init(); 
    
    $self->identifier( $identifier );
    $subject_term = $child unless $subject_term;
    $object_term = $parent unless $object_term;
    $predicate_term = $reltype unless $predicate_term;
    $self->subject_term( $subject_term) if $subject_term;
    $self->object_term( $object_term) if $object_term;
    $self->predicate_term( $predicate_term ) if $predicate_term;
    $self->ontology($ont) if $ont;
                                                    
    return $self;
    
} # new



#line 182

sub init {
    my( $self ) = @_;
    
    $self->{ "_identifier" }     = undef;
    $self->{ "_subject_term" }   = undef;
    $self->{ "_object_term" }    = undef;
    $self->{ "_predicate_term" } = undef;
    $self->ontology(undef);
   
} # init



#line 207

sub identifier {
    my ( $self, $value ) = @_;

    if ( defined $value ) {
        $self->{ "_identifier" } = $value;
    }

    return $self->{ "_identifier" };
} # identifier




#line 237

sub subject_term {
    my ( $self, $term ) = @_;
  
    if ( defined $term ) {
        $self->_check_class( $term, "Bio::Ontology::TermI" );
        $self->{ "_subject_term" } = $term;
    }

    return $self->{ "_subject_term" };
    
} # subject_term



#line 268

sub object_term {
    my ( $self, $term ) = @_;
  
    if ( defined $term ) {
        $self->_check_class( $term, "Bio::Ontology::TermI" );
        $self->{ "_object_term" } = $term;
    }

    return $self->{ "_object_term" };
}



#line 299

sub predicate_term {
    my ( $self, $term ) = @_;
  
    if ( defined $term ) {
        $self->_check_class( $term, "Bio::Ontology::TermI" );
        $self->{ "_predicate_term" } = $term;
    }

    return $self->{ "_predicate_term" };
}


#line 324

sub ontology{
    my $self = shift;
    my $ont;

    if(@_) {
	$ont = shift;
	if($ont) {
	    $ont = Bio::Ontology::Ontology->new(-name => $ont) if ! ref($ont);
	    if(! $ont->isa("Bio::Ontology::OntologyI")) {
		$self->throw(ref($ont)." does not implement ".
			     "Bio::Ontology::OntologyI. Bummer.");
	    }
	} 
	return $self->{"_ontology"} = $ont;
    } 
    return $self->{"_ontology"};
}

#line 352

sub to_string {
    my( $self ) = @_;
    
    local $^W = 0;

    my $s = "";

    $s .= "-- Identifier:\n";
    $s .= $self->identifier()."\n";
    $s .= "-- Subject Term Identifier:\n";
    $s .= $self->subject_term()->identifier()."\n";
    $s .= "-- Object Term Identifier:\n";
    $s .= $self->object_term()->identifier()."\n";
    $s .= "-- Relationship Type Identifier:\n";
    $s .= $self->predicate_term()->identifier();
    
    return $s;
    
} # to_string



sub _check_class {
    my ( $self, $value, $expected_class ) = @_;
    
    if ( ! defined( $value ) ) {
        $self->throw( "Found [undef] where [$expected_class] expected" );
    }
    elsif ( ! ref( $value ) ) {
        $self->throw( "Found [scalar] where [$expected_class] expected" );
    } 
    elsif ( ! $value->isa( $expected_class ) ) {
        $self->throw( "Found [" . ref( $value ) . "] where [$expected_class] expected" );
    }    

} # _check_type

#################################################################
# aliases for backwards compatibility
#################################################################

#line 400

*child_term        = \&subject_term;
*parent_term       = \&object_term;
*relationship_type = \&predicate_term;

1;
