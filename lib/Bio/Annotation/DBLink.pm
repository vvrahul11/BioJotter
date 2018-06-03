#line 1 "Bio/Annotation/DBLink.pm"
# $Id: DBLink.pm,v 1.12 2002/10/23 18:07:49 lapp Exp $
#
# BioPerl module for Bio::Annotation::Link
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 49


# Let the code begin...

package Bio::Annotation::DBLink;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::AnnotationI;
use Bio::IdentifiableI;

@ISA = qw(Bio::Root::Root Bio::AnnotationI Bio::IdentifiableI);


sub new {
  my($class,@args) = @_;

  my $self = $class->SUPER::new(@args);

  my ($database, $primary_id, $optional_id, $comment, $tag, $ns, $auth, $v) =
      $self->_rearrange([qw(DATABASE
			    PRIMARY_ID
			    OPTIONAL_ID
			    COMMENT
			    TAGNAME
			    NAMESPACE
			    AUTHORITY
			    VERSION
			    )], @args);
  
  $database    && $self->database($database);
  $primary_id  && $self->primary_id($primary_id);
  $optional_id && $self->optional_id($optional_id);
  $comment     && $self->comment($comment);
  $tag         && $self->tagname($tag);
  # Bio::IdentifiableI parameters:
  $ns          && $self->namespace($ns); # this will override $database
  $auth        && $self->authority($auth);
  defined($v)  && $self->version($v);

  return $self;
}

#line 96


#line 109

sub as_text{
   my ($self) = @_;

   return "Direct database link to ".$self->primary_id." in database ".$self->database;
}

#line 127

sub hash_tree{
   my ($self) = @_;
   
   my $h = {};
   $h->{'database'}   = $self->database;
   $h->{'primary_id'} = $self->primary_id;
   if( defined $self->optional_id ) {
       $h->{'optional_id'} = $self->optional_id;
   }
   if( defined $self->comment ) {
       # we know that comments have hash_tree methods
       $h->{'comment'} = $self->comment;
   }

   return $h;
}

#line 164

sub tagname{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'tagname'} = $value;
    }
    return $self->{'tagname'};
}

#line 176

#line 188

sub database{
   my ($self,$value) = @_;

   if( defined $value) {
      $self->{'database'} = $value;
    }
    return $self->{'database'};

}

#line 212

sub primary_id{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'primary_id'} = $value;
    }
    return $self->{'primary_id'};

}

#line 240

#'

sub optional_id{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'optional_id'} = $value;
    }
    return $self->{'optional_id'};

}

#line 263

sub comment {
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'comment'} = $value;
    }
    return $self->{'comment'};
}

#line 287

sub object_id {
    return shift->primary_id(@_);
}

#line 304

sub version{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_version'} = $value;
    }
    return $self->{'_version'};
}


#line 325

sub authority {
    my ($obj,$value) = @_;
    if( defined $value) {
	$obj->{'authority'} = $value;
    }
    return $obj->{'authority'};
}

#line 347

sub namespace{
    return shift->database(@_);
}

1;
