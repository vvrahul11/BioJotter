#line 1 "Bio/Ontology/OntologyEngineI.pm"
# $Id: OntologyEngineI.pm,v 1.2.2.3 2003/03/27 10:07:56 lapp Exp $
#
# BioPerl module for OntologyEngineI
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

#line 86


# Let the code begin...


package Bio::Ontology::OntologyEngineI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

#line 110

sub add_term{
    shift->throw_not_implemented();
}

#line 126

sub add_relationship{
    shift->throw_not_implemented();
}

#line 144

sub get_relationships{
    shift->throw_not_implemented();
}

#line 160

sub get_predicate_terms{
    shift->throw_not_implemented();
}

#line 182

sub get_child_terms{
    shift->throw_not_implemented();
}

#line 201

sub get_descendant_terms{
    shift->throw_not_implemented();
}

#line 223

sub get_parent_terms{
    shift->throw_not_implemented();
}

#line 243

sub get_ancestor_terms{
    shift->throw_not_implemented();
}

#line 261

sub get_leaf_terms{
    shift->throw_not_implemented();
}

#line 279

sub get_root_terms{
    shift->throw_not_implemented();
}

#line 287

#line 303

sub relationship_factory{
    return shift->throw_not_implemented();
}

#line 323

sub term_factory{
    return shift->throw_not_implemented();
}

#line 336

#line 362

sub get_all_terms{
    my $self = shift;
    # get all root nodes
    my @roots = $self->get_root_terms();
    # accumulate all descendants for each root term
    my @terms = map { $self->get_descendant_terms($_); } @roots;
    # add on the root terms themselves
    push(@terms, @roots);
    # make unique by name and ontology
    my %name_map = map { ($_->name."@".$_->ontology->name, $_); } @terms;
    # done 
    return values %name_map;
}

#line 398

sub find_terms{
    my $self = shift;
    my %params = @_;
    @params{ map { lc $_; } keys %params } = values %params; # lowercase keys

    my @terms = grep {
	my $ok = exists($params{-identifier}) ?
	    $_->identifier() eq $params{-identifier} : 1;
	$ok && ((! exists($params{-name})) ||
		($_->name() eq $params{-name}));
    } $self->get_all_terms();
    return @terms;
}

1;
