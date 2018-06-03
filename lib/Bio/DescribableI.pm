#line 1 "Bio/DescribableI.pm"
# $Id: DescribableI.pm,v 1.6 2002/10/25 01:29:37 lapp Exp $

#
# This module is licensed under the same terms as Perl itself. You use,
# modify, and redistribute it under the terms of the Perl Artistic License.
#

#line 57

package Bio::DescribableI;
use vars qw(@ISA );
use strict;
use Bio::Root::RootI;


@ISA = qw(Bio::Root::RootI);

#line 84

sub display_name {
   my ($self) = @_;
   $self->throw_not_implemented();
}


#line 105

sub description {
   my ($self) = @_;
   $self->throw_not_implemented();
}

1;
