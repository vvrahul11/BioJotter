#line 1 "Bio/Factory/ObjectFactoryI.pm"
# $Id: ObjectFactoryI.pm,v 1.3 2002/10/22 07:45:14 lapp Exp $
#
# BioPerl module for Bio::Factory::ObjectFactoryI
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 66


# Let the code begin...


package Bio::Factory::ObjectFactoryI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

#line 89

sub create{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

#line 108

sub create_object{
   my ($self,@args) = @_;
   return $self->create(@args);
}

1;
