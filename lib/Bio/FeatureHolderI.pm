#line 1 "Bio/FeatureHolderI.pm"
# $Id: FeatureHolderI.pm,v 1.2 2002/11/19 07:04:22 lapp Exp $
#
# BioPerl module for Bio::FeatureHolderI
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 78


# Let the code begin...


package Bio::FeatureHolderI;
use vars qw(@ISA);
use strict;
use Carp;
use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );

#line 104

sub get_SeqFeatures{
    shift->throw_not_implemented();
}

#line 133

sub feature_count {
    return scalar(shift->get_SeqFeatures(@_));
}

#line 163

sub get_all_SeqFeatures{
    my $self = shift;
    my @flatarr;

    foreach my $feat ( $self->get_SeqFeatures(@_) ){
	push(@flatarr,$feat);
	&_add_flattened_SeqFeatures(\@flatarr,$feat,@_);
    }
    return @flatarr;
}

sub _add_flattened_SeqFeatures {
    my ($arrayref,$feat,@args) = @_;
    my @subs = ();

    if($feat->isa("Bio::FeatureHolderI")) {
	@subs = $feat->get_SeqFeatures(@args);
    } elsif($feat->isa("Bio::SeqFeatureI")) {
	@subs = $feat->sub_SeqFeature();
    } else {
	confess ref($feat)." is neither a FeatureHolderI nor a SeqFeatureI. ".
	    "Don't know how to flatten.";
    }
    foreach my $sub (@subs) {
	push(@$arrayref,$sub);
	&_add_flattened_SeqFeatures($arrayref,$sub);
    }

}

1;
