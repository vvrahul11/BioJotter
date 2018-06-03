#line 1 "Bio/Ontology/OntologyI.pm"
# $Id: OntologyI.pm,v 1.2.2.4 2003/03/27 10:07:56 lapp Exp $
#
# BioPerl module for Bio::Ontology::OntologyI
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

#line 76


# Let the code begin...


package Bio::Ontology::OntologyI;
use vars qw(@ISA);
use strict;

use Bio::Ontology::OntologyEngineI;

@ISA = qw( Bio::Ontology::OntologyEngineI );

#line 92

#line 104

sub name{
    shift->throw_not_implemented();
}

#line 128

sub authority{
    shift->throw_not_implemented();
}

#line 152

sub identifier{
    shift->throw_not_implemented();
}

#line 168

sub definition{
    shift->throw_not_implemented();
}

#line 188

sub close{
    shift->throw_not_implemented();
}

#line 200

#line 217

#line 229

#line 243

#line 255

#line 273

#line 288

#line 306

#line 322

#line 336

#line 350

#line 367


#line 390

#line 394

#line 410

sub relationship_factory{
    return shift->throw_not_implemented();
}

#line 430

sub term_factory{
    return shift->throw_not_implemented();
}

1;
