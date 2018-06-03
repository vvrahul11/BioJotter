#line 1 "Bio/Factory/BlastResultFactory.pm"
#-----------------------------------------------------------------
# $Id: BlastResultFactory.pm,v 1.5 2002/10/22 07:38:32 lapp Exp $
#
# BioPerl module for Bio::Factory::BlastResultFactory
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

# POD documentation - main docs before the code

#line 73

#'

package Bio::Factory::BlastResultFactory;

use strict;
use Bio::Root::Root;
use Bio::Factory::ResultFactoryI;
use Bio::Search::Result::BlastResult;

use vars qw(@ISA);

@ISA = qw(Bio::Root::Root Bio::Factory::ResultFactoryI); 

sub new {
    my ($class, @args) = @_;
    my $self = $class->SUPER::new(@args);
    return $self;
}

#line 102

sub create_result {
    my ($self, @args) = @_;

    my $result = Bio::Search::Result::BlastResult->new( @args );

    return $result;
}



1;
