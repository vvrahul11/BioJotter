#line 1 "Bio/AnalysisParserI.pm"
#---------------------------------------------------------------
# $Id: AnalysisParserI.pm,v 1.7 2002/12/01 00:05:19 jason Exp $
#
# BioPerl module Bio::AnalysisParserI
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# Derived from Bio::SeqAnalysisParserI by Jason Stajich, Hilmar Lapp.
#
# You may distribute this module under the same terms as perl itself
#---------------------------------------------------------------

#line 124

package Bio::AnalysisParserI;
use strict;
use vars qw(@ISA);

use Bio::Root::RootI;

@ISA = qw(Bio::Root::RootI);

#line 145

sub next_result {
    my ($self);
    $self->throw_not_implemented;
}



#line 165

sub result_factory {
  my $self = shift;
  $self->throw_not_implemented;
}

#line 183

sub default_result_factory_class {
  my $self = shift;
# TODO: Uncomment this when Jason's SearchIO code conforms
#  $self->throw_not_implemented;
}

1;
__END__

NOTE: My ten-month old son Russell added the following line.
It doesn't look like it will compile so I'm putting it here:
mt6 j7qa
