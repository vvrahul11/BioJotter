#line 1 "Bio/Event/EventGeneratorI.pm"
# $Id: EventGeneratorI.pm,v 1.7 2002/10/22 07:45:14 lapp Exp $
#
# BioPerl module for Bio::Event::EventGeneratorI
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 63


# Let the code begin...


package Bio::Event::EventGeneratorI;
use vars qw(@ISA);
use strict;

@ISA = qw( Bio::Root::RootI );

#line 83

sub attach_EventHandler{
    my ($self) = @_;
    $self->throw_not_implemented();
}

1;
