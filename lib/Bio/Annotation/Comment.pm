#line 1 "Bio/Annotation/Comment.pm"
# $Id: Comment.pm,v 1.8 2002/09/25 18:11:33 lapp Exp $
#
# BioPerl module for Bio::Annotation::Comment
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 40


# Let the code begin...

package Bio::Annotation::Comment;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::AnnotationI;

@ISA = qw(Bio::Root::Root Bio::AnnotationI);

#line 65


sub new {
  my($class,@args) = @_;

  my $self = $class->SUPER::new(@args);
  my ($text,$tag) = $self->_rearrange([qw(TEXT TAGNAME)], @args);

  defined $text && $self->text($text);
  defined $tag && $self->tagname($tag);

  return $self;
}

#line 82

#line 94

sub as_text{
   my ($self) = @_;

   return "Comment: ".$self->text;
}

#line 112

sub hash_tree{
   my ($self) = @_;
   
   my $h = {};
   $h->{'text'} = $self->text;
}

#line 137

sub tagname{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'tagname'} = $value;
    }
    return $self->{'tagname'};
}

#line 149


#line 164

sub text{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'text'} = $value;
    }
    return $self->{'text'};

}



1;
