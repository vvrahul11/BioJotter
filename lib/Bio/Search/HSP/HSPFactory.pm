#line 1 "Bio/Search/HSP/HSPFactory.pm"
# $Id: HSPFactory.pm,v 1.4 2002/10/22 07:45:17 lapp Exp $
#
# BioPerl module for Bio::Search::HSP::HSPFactory
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 68


# Let the code begin...


package Bio::Search::HSP::HSPFactory;
use vars qw(@ISA $DEFAULT_TYPE);
use strict;

use Bio::Root::Root;
use Bio::Factory::ObjectFactoryI;

@ISA = qw(Bio::Root::Root Bio::Factory::ObjectFactoryI );

BEGIN { 
    $DEFAULT_TYPE = 'Bio::Search::HSP::GenericHSP'; 
}

#line 96

sub new {
  my($class,@args) = @_;

  my $self = $class->SUPER::new(@args);
  my ($type) = $self->_rearrange([qw(TYPE)],@args);
  $self->type($type) if defined $type;
  return $self;
}

#line 116

sub create{
   my ($self,@args) = @_;
   my $type = $self->type;
   eval { $self->_load_module($type) };
   if( $@ ) { $self->throw("Unable to load module $type"); }
   return $type->new(@args);
}


#line 135

sub type{
    my ($self,$type) = @_;
   if( defined $type ) { 
       # redundancy with the create method which also calls _load_module
       # I know - but this is not a highly called object so I am going 
       # to leave it in
       eval {$self->_load_module($type) };
       if( $@ ){ $self->warn("Cannot find module $type, unable to set type") } 
       else { $self->{'_type'} = $type; }
   }
    return $self->{'_type'} || $DEFAULT_TYPE;
}

1;
