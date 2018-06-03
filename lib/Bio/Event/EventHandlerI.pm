#line 1 "Bio/Event/EventHandlerI.pm"
# $Id: EventHandlerI.pm,v 1.5 2002/10/22 07:45:14 lapp Exp $
#
# BioPerl module for Bio::Event::EventHandlerI
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 64


# Let the code begin...


package Bio::Event::EventHandlerI;
use vars qw(@ISA);
use strict;
use Bio::Root::RootI;
use Carp;

@ISA = qw(Bio::Root::RootI);

#line 87

sub will_handle{
   my ($self,$type) = @_;
   $self->throw_not_implemented();
}

#line 96

#line 107

sub start_document{
   my ($self,@args) = @_;
   $self->throw_not_implemented;
}

#line 123

sub end_document{
   my ($self,@args) = @_;
   $self->throw_not_implemented;
}

#line 139

sub start_element{
   my ($self,@args) = @_;
   $self->throw_not_implemented;
}

#line 155

sub end_element{
   my ($self,@args) = @_;
   $self->throw_not_implemented;
}


#line 174

sub in_element{
   my ($self,@args) = @_;
   $self->throw_not_implemented;

}

#line 193

sub within_element{
   my ($self,@args) = @_;
   $self->throw_not_implemented;
}

#line 209

sub characters{
   my ($self,@args) = @_;
   $self->throw_not_implemented;
}

1;
