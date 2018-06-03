#line 1 "Bio/Ontology/OntologyStore.pm"
# $Id: OntologyStore.pm,v 1.1.2.2 2003/03/27 10:07:56 lapp Exp $
#
# BioPerl module for Bio::Ontology::OntologyStore
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 67


# Let the code begin...


package Bio::Ontology::OntologyStore;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;


@ISA = qw(Bio::Root::Root );

# these are the static ontology stores by name and by identifier - there is
# only one of each in any application
my %ont_store_by_name = ();
my %ont_store_by_id = ();
# also, this is really meant as a singleton object, so we try to enforce it
my $instance = undef;

#line 108

sub new {
    return shift->get_instance(@_);
}

#line 134

sub get_instance{
   my ($self,@args) = @_;

   if(! $instance) {
       $instance = $self->SUPER::new(@args);
   }
   return $instance;
}

#line 171

sub get_ontology{
    my ($self,@args) = @_;
    my $ont;

    my ($name,$id) = $self->_rearrange([qw(NAME ID)], @args);
    if($id) {
	$ont = $ont_store_by_id{$id};
	return unless $ont; # no AND can be satisfied in this case
    }
    if($name) {
	my $o = $ont_store_by_name{$name};
	if((! $ont) || ($ont->identifier() eq $o->identifier())) {
	    $ont = $o;
	} else {
	    $ont = undef;
	}
    }
    return $ont;
}

#line 205

sub register_ontology{
    my ($self,@args) = @_;
    my $ret = 1;

    foreach my $ont (@args) {
	if(! (ref($ont) && $ont->isa("Bio::Ontology::OntologyI"))) {
	    $self->throw((ref($ont) ? ref($ont) : $ont)." does not implement ".
			 "Bio::Ontology::OntologyI or is not an object");
	}
	if($self->get_ontology(-name => $ont->name())) {
	    $self->warn("ontology with name \"".$ont->name().
			"\" already exists in the store, ignoring new one");
	    $ret = 0;
	    next;
	}
	if($self->get_ontology(-id => $ont->identifier())) {
	    $self->warn("ontology with id \"".$ont->identifier().
			"\" already exists in the store, ignoring new one");
	    $ret = 0;
	    next;
	}
	$ont_store_by_name{$ont->name()} = $ont;
	$ont_store_by_id{$ont->identifier()} = $ont;
    }
    return $ret;
}

#line 245

sub remove_ontology{
    my $self = shift;
    my $ret = 1;

    foreach my $ont (@_) {
	$self->throw(ref($ont)." does not implement Bio::Ontology::OntologyI")
	    unless $ont && ref($ont) && $ont->isa("Bio::Ontology::OntologyI");
	# remove it from both the id hash and the name hash
	delete $ont_store_by_id{$ont->identifier()};
	delete $ont_store_by_name{$ont->name()} if $ont->name();
    }
    return 1;
}

1;
