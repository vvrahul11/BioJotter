#line 1 "Bio/AnnotationI.pm"
# $Id: AnnotationI.pm,v 1.7 2002/10/22 07:38:24 lapp Exp $

#
# BioPerl module for Bio::AnnotationI
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 105

#'
# Let the code begin...


package Bio::AnnotationI;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::RootI;


@ISA = qw(Bio::Root::RootI);


#line 135

sub as_text{
    shift->throw_not_implemented();
}

#line 151

sub hash_tree{
    shift->throw_not_implemented();
}

#line 175

sub tagname{
    shift->throw_not_implemented();
}

1;
