#line 1 "Bio/Factory/SequenceStreamI.pm"
# $Id: SequenceStreamI.pm,v 1.3 2002/10/22 07:45:14 lapp Exp $
#
# BioPerl module for Bio::Factory::SequenceStreamI
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 67


# Let the code begin...


package Bio::Factory::SequenceStreamI;
use vars qw(@ISA);
use strict;
use Bio::Root::RootI;

@ISA= qw(Bio::Root::RootI);

#line 100

sub next_seq {
    shift->throw_not_implemented();
}

#line 114

sub write_seq {
    shift->throw_not_implemented();
}

#line 129

sub sequence_factory{
    shift->throw_not_implemented();
}

1;
