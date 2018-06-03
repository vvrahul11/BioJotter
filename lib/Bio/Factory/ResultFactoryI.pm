#line 1 "Bio/Factory/ResultFactoryI.pm"
#-----------------------------------------------------------------
# $Id: ResultFactoryI.pm,v 1.6 2002/10/22 07:38:32 lapp Exp $
#
# BioPerl module Bio::Factory::ResultFactoryI
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

# POD documentation - main docs before the code

#line 65

#'

package Bio::Factory::ResultFactoryI;

use strict;
use Bio::Root::RootI;

use vars qw(@ISA);

@ISA = qw(Bio::Root::RootI); 

#line 86

sub create_result {
    my ($self, @args) = @_;
    $self->throw_not_implemented;
}


1;
