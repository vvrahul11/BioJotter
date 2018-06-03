#line 1 "Bio/Ontology/TermI.pm"
# $Id: TermI.pm,v 1.8.2.3 2003/05/27 22:00:52 lapp Exp $
#
# BioPerl module for Bio::Ontology::Term
#
# Cared for by Christian M. Zmasek <czmasek@gnf.org> or <cmzmasek@yahoo.com>
#
# (c) Christian M. Zmasek, czmasek@gnf.org, 2002.
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


#line 88


# Let the code begin...

package Bio::Ontology::TermI;
use vars qw( @ISA );
use strict;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );



#line 112

sub identifier {
    shift->throw_not_implemented();
} # identifier




#line 131

sub name {
    shift->throw_not_implemented();
} # name





#line 151

sub definition {
    shift->throw_not_implemented();
} # definition



#line 181

sub ontology {
    shift->throw_not_implemented();
} # ontology



#line 199

sub version {
    shift->throw_not_implemented();
} # version




#line 218

sub is_obsolete {
    shift->throw_not_implemented();
} # is_obsolete



#line 236

sub comment {
    shift->throw_not_implemented();
} # comment




#line 259

sub get_synonyms {
    shift->throw_not_implemented();
} # get_synonyms

#line 279

sub get_dblinks {
    shift->throw_not_implemented();
} # get_dblinks

#line 302

sub get_secondary_ids {
    shift->throw_not_implemented();
} # get_secondary_ids


1;
