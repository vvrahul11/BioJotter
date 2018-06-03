#line 1 "Bio/Factory/HitFactoryI.pm"
#-----------------------------------------------------------------
# $Id: HitFactoryI.pm,v 1.6 2002/10/22 07:38:32 lapp Exp $
#
# BioPerl module for Bio::Factory::HitFactoryI
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

# POD documentation - main docs before the code

#line 65

#'

package Bio::Factory::HitFactoryI;

use strict;
use Bio::Root::RootI;

use vars qw(@ISA);

@ISA = qw(Bio::Root::RootI); 

#line 86

sub create_hit {
    my ($self, @args) = @_;
    $self->throw_not_implemented;
}


1;
