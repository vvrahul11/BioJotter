#line 1 "Bio/DB/RandomAccessI.pm"
# POD documentation - main docs before the code
#
# $Id: RandomAccessI.pm,v 1.12 2002/10/22 07:38:29 lapp Exp $
#

#line 50


# Let the code begin...

package Bio::DB::RandomAccessI;

use vars qw(@ISA);
use strict;

use Bio::Root::RootI;
use Bio::Root::Root;

@ISA = qw(Bio::Root::Root);

#line 73

sub get_Seq_by_id{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

#line 96

sub get_Seq_by_acc{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}


#line 113


sub get_Seq_by_version{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}



## End of Package

1;

