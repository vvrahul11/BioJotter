#line 1 "Bio/SearchIO/EventHandlerI.pm"
# $Id: EventHandlerI.pm,v 1.8 2002/10/22 07:45:18 lapp Exp $
#
# BioPerl module for Bio::SearchIO::EventHandlerI
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 66


# Let the code begin...


package Bio::SearchIO::EventHandlerI;
use vars qw(@ISA);
use strict;
use Carp;

use Bio::Event::EventHandlerI;

@ISA = qw (Bio::Event::EventHandlerI);

#line 89

sub start_result {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 105

sub end_result{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

#line 121

sub start_hsp{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

#line 136

sub end_hsp{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

#line 152

sub start_hit {
   my ($self,@args) = @_;
   $self->throw_not_implemented
}

#line 168

sub end_hit {
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}


#line 187

sub register_factory{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}


#line 205

sub factory{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

#line 214

#line 225

#line 231


1;
