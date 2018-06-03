#line 1 "Bio/AnnotationCollectionI.pm"
# $Id: AnnotationCollectionI.pm,v 1.9 2002/10/22 07:38:24 lapp Exp $

#
# BioPerl module for Bio::AnnotationCollectionI
#
# Cared for by Ewan Birney <birney@ebi.ac.uk>
#
# Copyright Ewan Birney
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 117


# Let the code begin...


package Bio::AnnotationCollectionI;
use vars qw(@ISA);
use strict;

# Interface preamble - inherits from Bio::Root::RootI

use Bio::Root::RootI;

@ISA = qw(Bio::Root::RootI);


#line 142

sub get_all_annotation_keys{
    shift->throw_not_implemented();
}


#line 157

sub get_Annotations{
    shift->throw_not_implemented();    
}

#line 172

sub get_num_of_annotations{
    shift->throw_not_implemented();
}

1;
