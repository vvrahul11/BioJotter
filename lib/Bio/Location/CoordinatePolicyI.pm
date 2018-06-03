#line 1 "Bio/Location/CoordinatePolicyI.pm"
# $Id: CoordinatePolicyI.pm,v 1.4 2002/10/22 07:38:34 lapp Exp $
#
# BioPerl module for Bio::Location::CoordinatePolicyI
# Cared for by Hilmar Lapp <hlapp@gmx.net>
#          and Jason Stajich <jason@bioperl.org>
#
# Copyright Hilmar Lapp, Jason Stajich
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

#line 68

# Let the code begin...


package Bio::Location::CoordinatePolicyI;
use vars qw(@ISA);
use strict;
use Bio::Root::RootI;

@ISA = qw(Bio::Root::RootI);

#line 89

sub start {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 105

sub end {
    my ($self) = @_;
    $self->throw_not_implemented();
}

1;
