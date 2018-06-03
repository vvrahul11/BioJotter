#line 1 "Bio/Seq/SeqBuilder.pm"
# $Id: SeqBuilder.pm,v 1.6 2002/10/22 07:45:20 lapp Exp $
#
# BioPerl module for Bio::Seq::SeqBuilder
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2002.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

# POD documentation - main docs before the code

#line 114


# Let the code begin...


package Bio::Seq::SeqBuilder;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;
use Bio::Factory::ObjectBuilderI;

@ISA = qw(Bio::Root::Root Bio::Factory::ObjectBuilderI);

my %slot_param_map = ("add_SeqFeature" => "features",
		      );
my %param_slot_map = ("features"       => "add_SeqFeature",
		      );

#line 145

sub new {
    my($class,@args) = @_;
    
    my $self = $class->SUPER::new(@args);
    
    $self->{'wanted_slots'} = [];
    $self->{'unwanted_slots'} = [];
    $self->{'object_conds'} = [];
    $self->{'_objhash'} = {};
    $self->want_all(1);

    return $self;
}

#line 163

#line 187

sub want_slot{
    my ($self,$slot) = @_;
    my $ok = 0;

    $slot = substr($slot,1) if substr($slot,0,1) eq '-';
    if($self->want_all()) {
	foreach ($self->get_unwanted_slots()) {
	    # this always overrides in want-all mode
	    return 0 if($slot eq $_);
	}
	if(! exists($self->{'_objskel'})) {
	    $self->{'_objskel'} = $self->sequence_factory->create_object();
	}
	if(exists($param_slot_map{$slot})) {
	    $ok = $self->{'_objskel'}->can($param_slot_map{$slot});
	} else {
	    $ok = $self->{'_objskel'}->can($slot);
	}
	return $ok if $ok;
	# even if the object 'cannot' do this slot, it might have been
	# added to the list of wanted slot, so carry on
    }
    foreach ($self->get_wanted_slots()) {
	if($slot eq $_) {
	    $ok = 1;
	    last;
	}
    }
    return $ok;
}

#line 260

sub add_slot_value{
    my ($self,$slot,@args) = @_;

    my $h = $self->{'_objhash'};
    return unless $h;
    # multiple named parameter variant of calling?
    if((@args > 1) && (@args % 2) && (substr($slot,0,1) eq '-')) {
	unshift(@args, $slot);
	while(@args) {
	    my $key = shift(@args);
	    $h->{$key} = shift(@args);
	}
    } else {
	if($slot eq 'add_SeqFeature') {
	    $slot = '-'.$slot_param_map{$slot};
	    $h->{$slot} = [] unless $h->{$slot};
	    push(@{$h->{$slot}}, @args);
	} else {
	    $slot = '-'.$slot unless substr($slot,0,1) eq '-';
	    $h->{$slot} = $args[0];
	}
    }
    return 1;
}

#line 308

sub want_object{
    my $self = shift;

    my $ok = 1;
    foreach my $cond ($self->get_object_conditions()) {
	$ok = &$cond($self->{'_objhash'});
	last unless $ok;
    }
    delete $self->{'_objhash'} unless $ok;
    return $ok;
}

#line 343

sub make_object{
    my $self = shift;

    my $obj;
    if(exists($self->{'_objhash'}) && %{$self->{'_objhash'}}) {
	$obj = $self->sequence_factory->create_object(%{$self->{'_objhash'}});
    }
    $self->{'_objhash'} = {}; # reset
    return $obj;
}

#line 382

#line 394

sub get_wanted_slots{
    my $self = shift;

    return @{$self->{'wanted_slots'}};
}

#line 412

sub add_wanted_slot{
    my ($self,@slots) = @_;

    my $myslots = $self->{'wanted_slots'};
    foreach my $slot (@slots) {
	if(! grep { $slot eq $_; } @$myslots) {
	    push(@$myslots, $slot);
	}
    }
    return 1;
}

#line 437

sub remove_wanted_slots{
    my $self = shift;
    my @slots = $self->get_wanted_slots();
    $self->{'wanted_slots'} = [];
    return @slots;
}

#line 456

sub get_unwanted_slots{
    my $self = shift;

    return @{$self->{'unwanted_slots'}};
}

#line 474

sub add_unwanted_slot{
    my ($self,@slots) = @_;

    my $myslots = $self->{'unwanted_slots'};
    foreach my $slot (@slots) {
	if(! grep { $slot eq $_; } @$myslots) {
	    push(@$myslots, $slot);
	}
    }
    return 1;
}

#line 499

sub remove_unwanted_slots{
    my $self = shift;
    my @slots = $self->get_unwanted_slots();
    $self->{'unwanted_slots'} = [];
    return @slots;
}

#line 525

sub want_none{
    my $self = shift;

    $self->want_all(0);
    $self->remove_wanted_slots();
    $self->remove_unwanted_slots();
    return 1;
}

#line 555

sub want_all{
    my $self = shift;

    return $self->{'want_all'} = shift if @_;
    return $self->{'want_all'};
}

#line 584

sub get_object_conditions{
    my $self = shift;

    return @{$self->{'object_conds'}};
}

#line 613

sub add_object_condition{
    my ($self,@conds) = @_;

    if(grep { ref($_) ne 'CODE'; } @conds) {
	$self->throw("conditions against which to validate an object ".
		     "must be anonymous code blocks");
    }
    push(@{$self->{'object_conds'}}, @conds);
    return 1;
}

#line 637

sub remove_object_conditions{
    my $self = shift;
    my @conds = $self->get_object_conditions();
    $self->{'object_conds'} = [];
    return @conds;
}

#line 648

#line 662

sub sequence_factory{
    my $self = shift;

    if(@_) {
	delete $self->{'_objskel'};
	return $self->{'sequence_factory'} = shift;
    }
    return $self->{'sequence_factory'};
}

1;
