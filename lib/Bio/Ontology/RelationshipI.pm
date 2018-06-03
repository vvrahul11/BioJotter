#line 1 "Bio/Ontology/RelationshipI.pm"
# $Id: RelationshipI.pm,v 1.2.2.2 2003/03/27 10:07:56 lapp Exp $
#
# BioPerl module for RelationshipI
#
# Cared for by Peter Dimitrov <dimitrov@gnf.org>
#
# (c) Peter Dimitrov
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
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 87


# Let the code begin...


package Bio::Ontology::RelationshipI;
use vars qw(@ISA);
use strict;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

#line 112

sub identifier{
    shift->throw_not_implemented();
}

#line 131

sub subject_term{
    shift->throw_not_implemented();
}

#line 150

sub object_term{
    shift->throw_not_implemented();
}

#line 169

sub predicate_term{
    shift->throw_not_implemented();
}

#line 186

sub ontology{
    shift->throw_not_implemented();
}

1;
