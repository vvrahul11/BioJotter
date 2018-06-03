#line 1 "Bio/Root/Xref.pm"
#-----------------------------------------------------------------------------
# PACKAGE : Bio::Root::Xref.pm
# AUTHOR  : Steve Chervitz (sac@bioperl.org)
# CREATED : 8 May 1997
# REVISION: $Id: Xref.pm,v 1.9 2002/10/22 07:38:37 lapp Exp $
# STATUS  : Pre-Alpha 
#
# WARNING: This is considered an experimental module.
#
# Copyright (c) 1997-8 Steve Chervitz. All Rights Reserved.
#           This module is free software; you can redistribute it and/or 
#           modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------------

package Bio::Root::Xref;

use Bio::Root::Global;
use Bio::Root::Object ();
use Bio::Root::Vector ();

@Bio::Root::Xref::ISA = qw( Bio::Root::Vector Bio::Root::Object );

use vars qw($ID $VERSION);
$ID = 'Bio::Root::Xref';
$VERSION = 0.01;

## POD Documentation:

#line 126

#
##
###
#### END of main POD documentation.
###
##
#



#####################################################################################
##                                 CONSTRUCTOR                                     ##
#####################################################################################

sub _initialize {
    my( $self, %param ) = @_;

    $self->SUPER::_initialize(%param);
    
    $self->{'_obj'} = ($param{-OBJ} || undef);

    ## By default, all Xrefs are symmetric.
    ## Create symmetric cross-reference in obj.
    if(!$param{-ASYM}) {
	$self->{'_obj'}->xref(-OBJ=>$param{-PARENT});
	$self->{'_type'} = 'sym';
    } else {
	$self->{'_type'} = 'asym';
    }	
}


#####################################################################################
##                                  ACCESSORS                                      ##
#####################################################################################

sub obj {my ($self) = shift; return $self->{'_obj'}; }
sub desc {my ($self) = shift; return $self->{'_desc'}; }
sub type {my ($self) = shift; return $self->{'_type'}; }
    
sub set_desc {my ($self,$desc) = @_; 
	     $self->{'_desc'} = $desc;
	 }

sub clear {
## Not implemented. Need to do this carefully.
## Not sure if this method is needed.    
    my ($self) = @_;
}

1;
__END__

#####################################################################################
#                                  END OF CLASS                                     #
#####################################################################################

#line 196


