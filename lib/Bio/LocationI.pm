#line 1 "Bio/LocationI.pm"
# $Id: LocationI.pm,v 1.18 2002/12/01 00:05:19 jason Exp $
#
# BioPerl module for Bio::LocationI
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

#line 60

# Let the code begin...

package Bio::LocationI;
use vars qw(@ISA $coord_policy);
use strict;

use Bio::RangeI;
use Bio::Location::WidestCoordPolicy;
use Carp;

@ISA = qw(Bio::RangeI);

BEGIN {
    $coord_policy = Bio::Location::WidestCoordPolicy->new();
}

#line 86

sub location_type { 
    my ($self,@args) = @_;
    $self->throw_not_implemented();
}

#line 116

sub start {
    my ($self,@args) = @_;

    # throw if @args means that we don't support updating information
    # in the interface but will delegate to the coordinate policy object
    # for interpreting the 'start' value

    $self->throw_not_implemented if @args;
    return $self->coordinate_policy()->start($self);
}

#line 152

sub end {
    my ($self,@args) = @_;

    # throw if @args means that we don't support updating information
    # in the interface but will delegate to the coordinate policy object
    # for interpreting the 'end' value
    $self->throw_not_implemented if @args;
    return $self->coordinate_policy()->end($self);
}

#line 175

sub min_start {
    my($self) = @_;
    $self->throw_not_implemented();
}

#line 195

sub max_start {
    my($self) = @_;
    $self->throw_not_implemented();
}

#line 216

sub start_pos_type {
    my($self) = @_;
    $self->throw_not_implemented();
}

#line 236

sub min_end {
    my($self) = @_;
    $self->throw_not_implemented();
}

#line 256

sub max_end {
    my($self) = @_;
    $self->throw_not_implemented();
}

#line 277

sub end_pos_type {
    my($self) = @_;
    $self->throw_not_implemented();
}

#line 292

sub seq_id {
    my ($self, $seqid) = @_;
    if( defined $seqid ) {
	$self->{'_seqid'} = $seqid;
    }
    return $self->{'_seqid'};
}

#line 326

sub is_remote{
    shift->throw_not_implemented();
}

#line 361

sub coordinate_policy {
    my ($self, $policy) = @_;

    if(defined($policy)) {
	if(! $policy->isa('Bio::Location::CoordinatePolicyI')) {
	    $self->throw("Object of class ".ref($policy)." does not implement".
			 " Bio::Location::CoordinatePolicyI");
	}
	if(ref($self)) {
	    $self->{'_coordpolicy'} = $policy;
	} else {
	    # called as class method
	    $coord_policy = $policy;
	}
    }
    return (ref($self) && exists($self->{'_coordpolicy'}) ?
	    $self->{'_coordpolicy'} : $coord_policy);
}

#line 390

sub to_FTstring { 
    my($self) = @_;
    $self->throw_not_implemented();
}

#line 408

sub each_Location {
    my ($self,@args) = @_;
    $self->throw_not_implemented();
}

1;

