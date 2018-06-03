#line 1 "Bio/Ontology/RelationshipFactory.pm"
# $Id: RelationshipFactory.pm,v 1.1.2.1 2003/03/27 10:07:56 lapp Exp $
#
# BioPerl module for Bio::Ontology::RelationshipFactory
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

#line 77


# Let the code begin...


package Bio::Ontology::RelationshipFactory;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::Factory::ObjectFactory;

@ISA = qw(Bio::Factory::ObjectFactory);

#line 102

sub new {
    my($class,@args) = @_;

    my $self = $class->SUPER::new(@args);
  
    # make sure this matches our requirements
    $self->interface("Bio::Ontology::RelationshipI");
    $self->type($self->type() || "Bio::Ontology::Relationship");

    return $self;
}

1;
