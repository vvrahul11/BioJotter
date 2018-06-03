#line 1 "Bio/IdentifiableI.pm"
# $Id: IdentifiableI.pm,v 1.6 2002/10/23 18:07:49 lapp Exp $

#
# This module is licensed under the same terms as Perl itself. You use,
# modify, and redistribute it under the terms of the Perl Artistic License.
#

#line 84

package Bio::IdentifiableI;
use vars qw(@ISA );
use strict;
use Bio::Root::RootI;


@ISA = qw(Bio::Root::RootI);

#line 110

sub object_id {
   my ($self) = @_;
   $self->throw_not_implemented();
}

#line 129

sub version {
   my ($self) = @_;
   $self->throw_not_implemented();
}


#line 148

sub authority {
   my ($self) = @_;
   $self->throw_not_implemented();
}


#line 167

sub namespace {
   my ($self) = @_;
   $self->throw_not_implemented();
}



#line 191

sub lsid_string {
  my ($self) = @_;

  return $self->authority.":".$self->namespace.":".$self->object_id;
}



#line 210

sub namespace_string {
  my ($self) = @_;

  return $self->namespace.":".$self->object_id .
      (defined($self->version()) ? ".".$self->version : '');
}

1;
