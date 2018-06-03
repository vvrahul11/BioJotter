#line 1 "Bio/Annotation/Reference.pm"
# $Id: Reference.pm,v 1.18 2002/09/25 18:11:33 lapp Exp $
#
# BioPerl module for Bio::Annotation::Reference
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 49


# Let the code begin...

package Bio::Annotation::Reference;
use vars qw(@ISA);
use strict;

use Bio::Annotation::DBLink;
use Bio::AnnotationI;

@ISA = qw(Bio::Annotation::DBLink);

#line 77

sub new{
    my ($class,@args) = @_;

    my $self = $class->SUPER::new(@args);

    my ($start,$end,$authors,$location,$title,$medline,$tag) =
	$self->_rearrange([qw(START
			      END
			      AUTHORS
			      LOCATION
			      TITLE
			      MEDLINE
			      TAGNAME
			      )],@args);

    defined $start    && $self->start($start);
    defined $end      && $self->end($end);
    defined $authors  && $self->authors($authors);
    defined $location && $self->location($location);
    defined $title    && $self->title($title);
    defined $medline  && $self->medline($medline);
    defined $tag      && $self->tagname($tag);

    return $self;
}


#line 108

#line 120

sub as_text{
   my ($self) = @_;

   # this could get out of hand!
   return "Reference: ".$self->title;
}


#line 140

sub hash_tree{
   my ($self) = @_;
   
   my $h = {};
   $h->{'title'}   = $self->title;
   $h->{'authors'} = $self->authors;
   $h->{'location'} = $self->location;
   if( defined $self->start ) {
       $h->{'start'}   = $self->start;
   }
   if( defined $self->end ) {
       $h->{'end'} = $self->end;
   }
   $h->{'medline'} = $self->medline;

   return $h;
}

#line 176

sub tagname{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'tagname'} = $value;
    }
    return $self->{'tagname'};
}


#line 189


#line 202

sub start {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'start'} = $value;
    }
    return $self->{'start'};

}

#line 223

sub end {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'end'} = $value;
    }
    return $self->{'end'};
}

#line 243

sub rp{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'rp'} = $value;
    }
    return $self->{'rp'};

}

#line 264

sub authors{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'authors'} = $value;
    }
    return $self->{'authors'};

}

#line 285

sub location{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'location'} = $value;
    }
    return $self->{'location'};

}

#line 306

sub title{
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'title'} = $value;
    }
    return $self->{'title'};

}

#line 327

sub medline{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'medline'} = $value;
    }
    return $self->{'medline'};
}

#line 348

sub pubmed {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'pubmed'} = $value;
    }
    return $self->{'pubmed'};
}

#line 369

sub database{
   my ($self, @args) = @_;

   return $self->SUPER::database(@args) || 'MEDLINE';
}

#line 387

sub primary_id{
   my ($self, @args) = @_;

   return $self->medline(@args);
}

#line 405

sub optional_id{
   my ($self, @args) = @_;

   return $self->pubmed(@args);
}

#line 423

sub publisher {
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'publisher'} = $value;
   }
   return $self->{'publisher'};
}


#line 444

sub editors {
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'editors'} = $value;
   }
   return $self->{'editors'};
}


#line 467

sub encoded_ref {
   my ($self,$value) = @_;
   if( defined $value) {
      $self->{'encoded_ref'} = $value;
   }
   return $self->{'encoded_ref'};
}


1;
