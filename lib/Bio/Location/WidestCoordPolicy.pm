#line 1 "Bio/Location/WidestCoordPolicy.pm"
# $Id: WidestCoordPolicy.pm,v 1.6 2002/12/01 00:05:20 jason Exp $
#
# BioPerl module for Bio::Location::WidestCoordPolicy
#
# Cared for by Hilmar Lapp <hlapp@gmx.net>
#          and Jason Stajich <jason@bioperl.org>
#
# Copyright Hilmar Lapp, Jason Stajich
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

#line 61

# Let the code begin...


package Bio::Location::WidestCoordPolicy;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::Location::CoordinatePolicyI;

@ISA = qw(Bio::Root::Root Bio::Location::CoordinatePolicyI);

sub new { 
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);

    return $self;
}



#line 93

sub start {
    my ($self,$loc) = @_;

    # For performance reasons we don't check that it's indeed a Bio::LocationI
    # object. Hopefully, Location-object programmers are smart enough.
    my $pos = $loc->min_start();
    # if min is not defined or equals 0 we resort to max
    $pos = $loc->max_start() if(! $pos);
    return $pos;
}

#line 115

sub end {
    my ($self,$loc) = @_;

    # For performance reasons we don't check that it's indeed a Bio::LocationI
    # object. Hopefully, Location-object programmers are smart enough.
    my $pos = $loc->max_end();
    # if max is not defined or equals 0 we resort to min
    $pos = $loc->min_end() if(! $pos);
    return $pos;
}

1;

