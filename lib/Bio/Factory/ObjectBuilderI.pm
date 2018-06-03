#line 1 "Bio/Factory/ObjectBuilderI.pm"
# $Id: ObjectBuilderI.pm,v 1.2 2002/10/22 07:45:14 lapp Exp $
#
# BioPerl module for Bio::Factory::ObjectBuilderI
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
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

#line 84


# Let the code begin...


package Bio::Factory::ObjectBuilderI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

#line 116

sub want_slot{
    shift->throw_not_implemented();
}

#line 145

sub add_slot_value{
    shift->throw_not_implemented();
}

#line 169

sub want_object{
    shift->throw_not_implemented();
}

#line 196

sub make_object{
    shift->throw_not_implemented();
}

1;
