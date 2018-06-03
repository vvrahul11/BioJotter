#line 1 "Bio/Location/SplitLocationI.pm"
# $Id: SplitLocationI.pm,v 1.14 2002/12/01 00:05:20 jason Exp $
#
# BioPerl module for Bio::Location::SplitLocationI
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

#line 65

# Let the code begin...


package Bio::Location::SplitLocationI;
use vars qw(@ISA);
use strict;

use Bio::LocationI;
use Carp;

@ISA = qw(Bio::LocationI);


#line 88

sub sub_Location {
    my ($self,@args) = @_;
    $self->throw_not_implemented();
}

#line 103

sub splittype {
    my($self) = @_;
    $self->throw_not_implemented();
}


#line 124

sub is_single_sequence {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 143

#line 153

#line 164

#line 174

#line 184

#line 195

#line 205

#line 232

#line 242

1;

