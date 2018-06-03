#line 1 "Bio/Search/DatabaseI.pm"
#-----------------------------------------------------------------
# $Id: DatabaseI.pm,v 1.6 2002/10/22 07:38:38 lapp Exp $
#
# BioPerl module Bio::Search::DatabaseI
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

# POD documentation - main docs before the code

#line 73

#line 79

# Let the code begin...

package Bio::Search::DatabaseI;

use strict;
use Bio::Root::RootI;
use vars qw( @ISA );

@ISA = qw( Bio::Root::RootI);


#line 99

sub name {
    my $self = shift;
    $self->throw_not_implemented;
}

#line 113

sub date {
    my $self = shift;
    $self->throw_not_implemented;
}


#line 128

sub letters {
    my $self = shift;
    $self->throw_not_implemented;
}


#line 143

sub entries {
    my $self = shift;
    $self->throw_not_implemented;
}

1;
