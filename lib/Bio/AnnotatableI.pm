#line 1 "Bio/AnnotatableI.pm"
# $Id: AnnotatableI.pm,v 1.2 2002/12/31 13:09:06 birney Exp $
#
# BioPerl module for Bio::AnnotatableI
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 73


# Let the code begin...


package Bio::AnnotatableI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

#line 100

sub annotation{
    shift->throw_not_implemented();
}



1;
