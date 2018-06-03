#line 1 "Bio/SeqAnalysisParserI.pm"
# $Id: SeqAnalysisParserI.pm,v 1.12 2002/12/01 00:05:19 jason Exp $
#
# BioPerl module for Bio::SeqAnalysisParserI
#
# Cared for by Jason Stajich <jason@bioperl.org>,
# and Hilmar Lapp <hlapp@gmx.net>
#
# Copyright Jason Stajich, Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 78

package Bio::SeqAnalysisParserI;
use strict;
use vars qw(@ISA);
use Bio::Root::RootI;
use Carp;
@ISA = qw(Bio::Root::RootI);

#line 98

sub next_feature {
    my ($self) = shift;
    $self->throw_not_implemented();
}

1;
