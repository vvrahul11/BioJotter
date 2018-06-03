#line 1 "Bio/Location/FuzzyLocationI.pm"
# $Id: FuzzyLocationI.pm,v 1.17 2002/12/01 00:05:20 jason Exp $
#
# BioPerl module for Bio::Location::FuzzyLocationI
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

#line 61

# Let the code begin...


package Bio::Location::FuzzyLocationI;
use vars qw(@ISA);
use strict;

use Bio::LocationI;
use Carp;

@ISA = qw(Bio::LocationI);

#line 85

sub location_type {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 104

#line 114

#line 125

#line 135

#line 145

#line 156

#line 166

#line 193

#line 203

1;
