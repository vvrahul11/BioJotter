#line 1 "Bio/Factory/ObjectFactory.pm"
# $Id: ObjectFactory.pm,v 1.1.2.1 2003/03/27 10:07:56 lapp Exp $
#
# BioPerl module for Bio::Factory::ObjectFactory
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2003.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2003.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# POD documentation - main docs before the code

#line 82


# Let the code begin...


package Bio::Factory::ObjectFactory;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::Factory::ObjectFactoryI;

@ISA = qw(Bio::Root::Root Bio::Factory::ObjectFactoryI);

#line 109

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);
  
    my ($type,$interface) = $self->_rearrange([qw(TYPE INTERFACE)], @args);

    $self->{'_loaded_types'} = {};
    $self->interface($interface || "Bio::Root::RootI");
    $self->type($type) if $type;

    return $self;
}


#line 145

sub create_object {
   my ($self,@args) = @_;

   my $type = $self->type(); # type has already been loaded upon set
   return $type->new(-verbose => $self->verbose, @args);
}

#line 167

sub type{
    my $self = shift;

    if(@_) {
	my $type = shift;
	if($type && (! $self->{'_loaded_types'}->{$type})) {
	    eval {
		$self->_load_module($type);
	    };
	    if( $@ ) {
		$self->throw("module for '$type' failed to load: ".
			     $@);
	    }
	    my $o = bless {},$type;
	    if(!$self->_validate_type($o)) { # this may throw an exception
		$self->throw("'$type' is not valid for factory ".ref($self));
	    }
	    $self->{'_loaded_types'}->{$type} = 1;
	}
	return $self->{'type'} = $type;
    }
    return $self->{'type'};
}

#line 204

sub interface{
    my $self = shift;
    my $interface = shift;

    if($interface) {
	return $self->{'interface'} = $interface;
    }
    return $self->{'interface'};
}

#line 235

sub _validate_type{
    my ($self,$obj) = @_;

    if(! $obj->isa($self->interface())) {
	$self->throw("invalid type: '".ref($obj).
		     "' does not implement '".$self->interface()."'");
    }
    return 1;
}

#####################################################################
# aliases for naming consistency or other reasons                   #
#####################################################################

*create = \&create_object;

1;
