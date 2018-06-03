#line 1 "Bio/Annotation/Collection.pm"
# $Id: Collection.pm,v 1.16 2002/11/22 22:48:25 birney Exp $

#
# BioPerl module for Bio::Annotation::Collection.pm
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 70


# Let the code begin...


package Bio::Annotation::Collection;

use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::AnnotationCollectionI;
use Bio::AnnotationI;
use Bio::Root::Root;
use Bio::Annotation::TypeManager;
use Bio::Annotation::SimpleValue;


@ISA = qw(Bio::Root::Root Bio::AnnotationCollectionI Bio::AnnotationI);


#line 101

sub new{
   my ($class,@args) = @_;

   my $self = $class->SUPER::new(@args);

   $self->{'_annotation'} = {};
   $self->_typemap(Bio::Annotation::TypeManager->new());

   return $self;
}


#line 117

#line 127

sub get_all_annotation_keys{
   my ($self) = @_;
   return keys %{$self->{'_annotation'}};
}

#line 150

sub get_Annotations{
    my ($self,@keys) = @_;

    my @anns = ();
    @keys = $self->get_all_annotation_keys() unless @keys;
    foreach my $key (@keys) {
	if(exists($self->{'_annotation'}->{$key})) {
	    push(@anns,
		 map {
		     $_->tagname($key) if ! $_->tagname(); $_;
		 } @{$self->{'_annotation'}->{$key}});
	}
    }
    return @anns;
}

#line 187

sub get_all_Annotations{
    my ($self,@keys) = @_;

    return map {
	$_->isa("Bio::AnnotationCollectionI") ?
	    $_->get_all_Annotations() : $_;
    } $self->get_Annotations(@keys);
}

#line 207

sub get_num_of_annotations{
   my ($self) = @_;
   my $count = 0;
   map { $count += scalar @$_ } values %{$self->{'_annotation'}};
   return $count;
}

#line 218

#line 242

sub add_Annotation{
   my ($self,$key,$object,$archetype) = @_;
   
   # if there's no key we use the tagname() as key
   if(ref($key) && $key->isa("Bio::AnnotationI") &&
      (! ($object && ref($object)))) {
       $archetype = $object if $object;
       $object = $key;
       $key = $object->tagname();
       $key = $key->name() if $key && ref($key); # OntologyTermI
       $self->throw("Annotation object must have a tagname if key omitted")
	   unless $key;
   }

   if( !defined $object ) {
       $self->throw("Must have at least key and object in add_Annotation");
   }

   if( !ref $object ) {
       $self->throw("Must add an object. Use Bio::Annotation::{Comment,SimpleValue,OntologyTerm} for simple text additions");
   }

   if( !$object->isa("Bio::AnnotationI") ) {
       $self->throw("object must be AnnotationI compliant, otherwise we wont add it!");
   }

   # ok, now we are ready! If we don't have an archetype, set it
   # from the type of the object

   if( !defined $archetype ) {
       $archetype = ref $object;
   }

   # check typemap, storing if needed.
   my $stored_map = $self->_typemap->type_for_key($key);

   if( defined $stored_map ) {
       # check validity, irregardless of archetype. A little cheeky
       # this means isa stuff is executed correctly

       if( !$self->_typemap()->is_valid($key,$object) ) {
	   $self->throw("Object $object was not valid with key $key. If you were adding new keys in, perhaps you want to make use of the archetype method to allow registration to a more basic type");
       }
   } else {
       $self->_typemap->_add_type_map($key,$archetype);
   }

   # we are ok to store

   if( !defined $self->{'_annotation'}->{$key} ) {
       $self->{'_annotation'}->{$key} = [];
   }

   push(@{$self->{'_annotation'}->{$key}},$object);

   return 1;
}

#line 315

sub remove_Annotations{
    my ($self, @keys) = @_;

    @keys = $self->get_all_annotation_keys() unless @keys;
    my @anns = $self->get_Annotations(@keys);
    # flush
    foreach (@keys) {
	delete $self->{'_annotation'}->{$_};
    }
    return @anns;
}

#line 347

sub flatten_Annotations{
    my ($self,@keys) = @_;

    my @anns = $self->get_all_Annotations(@keys);
    my @origanns = $self->remove_Annotations(@keys);
    foreach (@anns) {
	$self->add_Annotation($_);
    }
    return @origanns;
}

#line 365

#line 377

sub as_text{
    my $self = shift;

    my $txt = "Collection consisting of ";
    my @texts = ();
    foreach my $ann ($self->get_Annotations()) {
	push(@texts, $ann->as_text());
    }
    if(@texts) {
	$txt .= join(", ", map { '['.$_.']'; } @texts);
    } else {
	$txt .= "no elements";
    }
    return $txt;
}

#line 405

sub hash_tree{
    my $self = shift;
    my $tree = {};

    foreach my $key ($self->get_all_annotation_keys()) {
	# all contained objects will support hash_tree() 
	# (they are AnnotationIs)
	$tree->{$key} = [$self->get_Annotations($key)];
    }
    return $tree;
}

#line 437

sub tagname{
    my $self = shift;

    return $self->{'tagname'} = shift if @_;
    return $self->{'tagname'};
}


#line 452

#line 464

sub description{
   my ($self,$value) = @_;

   $self->deprecated("Using old style annotation call on new Annotation::Collection object");

   if( defined $value ) {
       my $val = Bio::Annotation::SimpleValue->new();
       $val->value($value);
       $self->add_Annotation('description',$val);
   }

   my ($desc) = $self->get_Annotations('description');
   
   # If no description tag exists, do not attempt to call value on undef:
   return $desc ? $desc->value : undef;
}


#line 494

sub add_gene_name{
   my ($self,$value) = @_;

   $self->deprecated("Old style add_gene_name called on new style Annotation::Collection");

   my $val = Bio::Annotation::SimpleValue->new();
   $val->value($value);
   $self->add_Annotation('gene_name',$val);
}

#line 516

sub each_gene_name{
   my ($self) = @_;

   $self->deprecated("Old style each_gene_name called on new style Annotation::Collection");

   my @out;
   my @gene = $self->get_Annotations('gene_name');

   foreach my $g ( @gene ) {
       push(@out,$g->value);
   }

   return @out;
}

#line 543

sub add_Reference{
   my ($self, @values) = @_;

   $self->deprecated("add_Reference (old style Annotation) on new style Annotation::Collection");
   
   # Allow multiple (or no) references to be passed, as per old method
   foreach my $value (@values) {
       $self->add_Annotation('reference',$value);
   }
}

#line 566

sub each_Reference{
   my ($self) = @_;

   $self->deprecated("each_Reference (old style Annotation) on new style Annotation::Collection");
   
   return $self->get_Annotations('reference');
}


#line 587

sub add_Comment{
   my ($self,$value) = @_;

   $self->deprecated("add_Comment (old style Annotation) on new style Annotation::Collection");

   $self->add_Annotation('comment',$value);

}

#line 608

sub each_Comment{
   my ($self) = @_;

   $self->deprecated("each_Comment (old style Annotation) on new style Annotation::Collection");
   
   return $self->get_Annotations('comment');
}



#line 630

sub add_DBLink{
   my ($self,$value) = @_;

   $self->deprecated("add_DBLink (old style Annotation) on new style Annotation::Collection");

   $self->add_Annotation('dblink',$value);

}

#line 651

sub each_DBLink{
   my ($self) = @_;

   $self->deprecated("each_DBLink (old style Annotation) on new style Annotation::Collection - use get_Annotations('dblink')");
   
   return $self->get_Annotations('dblink');
}



#line 665

#line 677

sub _typemap{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'_typemap'} = $value;
    }
    return $self->{'_typemap'};

}

1;
