#line 1 "Bio/Seq/SeqFactory.pm"
# $Id: SeqFactory.pm,v 1.8 2002/10/25 22:49:04 lapp Exp $
#
# BioPerl module for Bio::Seq::SeqFactory
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 71


# Let the code begin...


package Bio::Seq::SeqFactory;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::Factory::SequenceFactoryI;

@ISA = qw(Bio::Root::Root Bio::Factory::SequenceFactoryI);

#line 95

sub new {
  my($class,@args) = @_;
  my $self = $class->SUPER::new(@args);
  my ($type) = $self->_rearrange([qw(TYPE)], @args);
  if( ! defined $type ) { 
      $type = 'Bio::PrimarySeq';
  }
  $self->type($type);
  return $self;
}


#line 123

sub create {
   my ($self,@args) = @_;
   return $self->type->new(-verbose => $self->verbose, @args);
}

#line 139

sub type{
   my ($self,$value) = @_;
   if( defined $value) {
       eval "require $value";
       if( $@ ) { $self->throw("$@: Unrecognized Sequence type for SeqFactory '$value'");}
       
       my $a = bless {},$value;
       unless( $a->isa('Bio::PrimarySeqI') ||
	       $a->isa('Bio::Seq::QualI') ) {
	   $self->throw("Must provide a valid Bio::PrimarySeqI or Bio::Seq::QualI or child class to SeqFactory Not $value");
       }
      $self->{'type'} = $value;
    }
    return $self->{'type'};
}

1;
