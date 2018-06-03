#line 1 "Bio/Annotation/TypeManager.pm"
# $Id: TypeManager.pm,v 1.4 2002/10/22 07:38:26 lapp Exp $
#
# BioPerl module for Bio::Annotation::TypeManager
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 65


# Let the code begin...


package Bio::Annotation::TypeManager;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;


@ISA = qw(Bio::Root::Root);
# new() can be inherited from Bio::Root::Root

#line 93

sub new{
   my ($class,@args) = @_;

   my $self = $class->SUPER::new(@args);

   $self->{'_type'} = {};

   $self->_add_type_map('reference',"Bio::Annotation::Reference");
   $self->_add_type_map('comment',"Bio::Annotation::Comment");
   $self->_add_type_map('dblink',"Bio::Annotation::DBLink");

   return $self;
}


#line 120

sub type_for_key{
   my ($self,$key) = @_;

   $key = $key->name() if ref($key) && $key->isa("Bio::Ontology::TermI");
   return $self->{'_type'}->{$key};
}


#line 140

sub is_valid{
   my ($self,$key,$object) = @_;

   if( !defined $object || !ref $object ) {
       $self->throw("Cannot type an object [$object]!");
   }

   if( !$object->isa($self->type_for_key($key)) ) {
       return 0;
   } else {
       return 1;
   }
}


#line 167

sub _add_type_map{
   my ($self,$key,$type) = @_;
   
   $key = $key->name() if ref($key) && $key->isa("Bio::Ontology::TermI");
   $self->{'_type'}->{$key} = $type;
}


