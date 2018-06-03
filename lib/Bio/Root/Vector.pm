#line 1 "Bio/Root/Vector.pm"
#-----------------------------------------------------------------------------
# PACKAGE : Bio::Root::Vector.pm
# AUTHOR  : Steve Chervitz (sac@bioperl.org)
# CREATED : 15 April 1997
# REVISION: $Id: Vector.pm,v 1.10 2002/10/22 07:38:37 lapp Exp $
# STATUS  : Alpha
#
# WARNING: This is considered an experimental module.
#
# For documentation, run this module through pod2html
# (preferably from Perl v5.004 or better).
#
# MODIFIED:
#    sac --- Fri Nov  6 14:24:48 1998
#       * Added destroy() method (experimental).
#    0.023, 20 Jul 1998, sac:
#      * Improved memory management (_destroy_master()).
#
#   Copyright (c) 1997 Steve Chervitz. All Rights Reserved.
#             This module is free software; you can redistribute it and/or
#             modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------------

package Bio::Root::Vector;

use Bio::Root::Global qw(:devel);
use Bio::Root::Object ();

# @ISA = qw(Bio::Root::Object);  # Eventually perhaps...

use vars qw($ID $VERSION);
$ID = 'Bio::Root::Vector';
$VERSION = 0.04;

use strict;
my @SORT_BY = ('rank','name');

## POD Documentation:

#line 175


#'
##
###
#### END of main POD documentation.
###
##
#

#line 193

########################################################
#                CONSTRUCTOR                           #
########################################################

## No constructor. See _set_master() for construction of {Master} data member.

## Destructor: Use remove_all() or remove().

# New Idea for destructor
#-------------
sub destroy {
#-------------
    my $self = shift;
    local($^W) = 0;
    undef $self->{'_prev'};
    undef $self->{'_next'};
    undef $self->{'_rank'};
    undef $self->{'_master'};
}

#####################################################################################
##                                  ACCESSORS                                      ##
#####################################################################################


#line 234

#-------------'
sub set_rank {
#-------------
    my( $self, %param) = @_;

    $self->_set_master($self) unless $self->{'_master'}->{'_set'};

    my($rank, $rank_by) = $self->master->_rearrange([qw(RANK RANK_BY)], %param);

    $DEBUG==1 and do{ print STDERR "$ID:set_rank() = $rank; Criteria: $rank_by."; <STDIN>; };

    $self->{'_rank'} = ($rank || undef);
    $self->{'_master'}->{'_rankBy'} = ($rank_by || undef);
    if( defined $self->{'_rank'} and not defined $self->{'_master'}->{'_rankBy'} ) {
	return $self->master->warn('Rank defined without ranking criteria.');
    }	
    1;
}

sub _set_rank_by {
    my( $self, $arg) = @_;
    $self->{'_master'}->{'_rankBy'} = $arg || 'unknown';
}

sub _set_master {
    ## A vector does not need a master object unless it needs to grow.
    my($self,$obj) = @_;

#    print "$ID: _set_master() new Master object for ${\$obj->name}."; <STDIN>;

    require Bio::Root::Object;
    my $master = {};
    bless $master, 'Bio::Root::Object';

    $master->{'_set'}  = 1;  ## Special member indicating that this method has been called.
                            ## Necessary since perl will generate an anonymous {Master}
                            ## hash ref on the fly. This ref will not be blessed however.
    $master->{'_first'} = $obj;
    $master->{'_last'}  = $obj;
    $master->{'_size'}  = 1;
    $master->{'_index'}->{$obj->name()} = $obj;
    $self->{'_master'} = $master;

    $self->{'_rank'} = 1;
    $self->{'_prev'} = undef;
    $self->{'_next'} = undef;
#    $self->{'_master'}->{'_rankBy'} = undef;  # Default rank is the order of addition to Vector.
}

sub _destroy_master {
# This is called when the last object in the vector is being remove()d
    my $self = shift;

    return if !$self->master or !$self->master->{'_set'};

    my $master = $self->master;

    ## Get rid of the Vector master object.
    ref $master->{'_first'} and (%{$master->{'_first'}} = (), undef $master->{'_first'});
    ref $master->{'_last'}  and (%{$master->{'_last'}} = (), undef $master->{'_last'});
    ref $master->{'_index'} and (%{$master->{'_index'}} = (), undef $master->{'_index'});
    %{$master} = ();
    undef $master;
}


#line 312

#-----------------'
sub clone_vector {
#-----------------
    my($self, $obj) = @_;

    ref($obj) || throw($self, "Can't clone $ID object: Not an object ref ($obj)");

    $self->{'_prev'} = $obj->{'_prev'};
    $self->{'_next'} = $obj->{'_next'};
    $self->{'_rank'} = $obj->{'_rank'};
    $self->{'_master'} = $obj->{'_master'};
}


#line 334

#--------
sub prev { my $self = shift; $self->{'_prev'}; }
#--------



#line 348

#--------
sub next { my $self = shift; $self->{'_next'}; }
#--------



#line 362

#----------
sub first  {
#----------
    my $self = shift;
    defined $self->{'_master'} ? $self->{'_master'}->{'_first'} : $self;
}


#line 378

#-------
sub last   {
#-------
    my $self = shift;
    defined $self->{'_master'} ? $self->{'_master'}->{'_last'} : $self;
}



#line 397

#---------
sub rank { my $self = shift; $self->{'_rank'} || 1; }
#---------



#line 413

#-----------
sub rank_by {
#-----------
    my $self = shift;
    defined $self->{'_master'} ? ($self->{'_master'}->{'_rankBy'}||'order of addition')
	: 'unranked';
}



#line 430

#---------
sub size {
#---------
    my $self = shift;
    defined $self->{'_master'} ? $self->{'_master'}->{'_size'} : 1;
}


#line 446

#-----------
sub master { my $self = shift; $self->{'_master'}; }
#-----------


## Not sure what these potentially dangerous methods are used for.
## Should be unnecessary and probably can be removed.
sub set_prev { my($self,$obj) = @_; $self->{'_prev'} = $obj;  }
sub set_next { my($self,$obj) = @_; $self->{'_next'} = $obj; }

#############################################################################
#                           INSTANCE METHODS                               ##
#############################################################################


#line 468

#------------
sub is_first { my($self) = shift; return not defined $self->{'_prev'}; }
#------------


#line 480

#------------
sub is_last { my($self) = shift; return not defined $self->{'_next'}; }
#------------




#line 498

#--------
sub get {
#--------
    my($self,$name) = @_;

    my ($obj);
#    print "$ID get(): getting $name\n";

    if($self->{'_master'}->{'_set'}) {
#	my @names = keys %{$self->{'_master'}->{'_index'}};
#	print "$ID: names in hash:\n@names";<STDIN>;
#	print "  returning $self->{'_master'}->{'_index'}->{$name}\n";
	local($^W) = 0;
	$obj = $self->{'_master'}->{'_index'}->{$name};
    }

    elsif($self->name =~ /$name/i) {
#	print "  returning self\n";
	$obj = $self;
    }

    if(not ref $obj) {
	$self->throw("Can't get object named \"$name\": object not set or name undefined.");
    }
    $obj;
}

## Former strategy: hunt through the list for the object.
## No longer needed since master indexes all objects.
#	 do{
#	     if($obj->name eq $name) { return $obj; }
#	
#	 } while($obj = $current->prev());




#line 544

#--------
sub add {
#--------
    my($self,$new,$index) = @_;

    $self->_set_master($self) unless $self->{'_master'}->{'_set'};

#    print "\n\nADDING TO VECTOR ${\ref $self} ${\$self->name}\nFOR PARENT: ${\ref $self->parent} ${\$self->parent->name}\n\n";

    $self->{'_next'} = $new;
    $new->{'_prev'} = $self;
    $self->{'_master'}->{'_last'} = $new;
    $self->{'_master'}->{'_size'}++;
    $new->{'_master'} = $self->{'_master'};
    $new->_incrementRank();
    $new->Bio::Root::Vector::_index();

#    printf "NEW CONTENTS: (n=%s)\n", $self->size;
#    my $obj = $self->first;
#    my $count=0;
#    do { print "\n","Object #",++$count,"\n";
#	       $obj->display;
#     } while($obj=$obj->next);
#    <STDIN>;
}


sub _index {
    my($self) = @_;
    my $name = $self->name;

    # Generate unique name, if necessary, for indexing purposes.
    if( not $name or $name =~ /anonymous/) {
	$name ||= '';
	$name .= $self->size();
    }
#    print "$ID: _index() called for $name\n";

    $self->{'_master'}->{'_index'}->{$name} = $self;
}

sub _incrementRank {
    my $self = shift;
    return if not defined $self->{'_prev'};
    $self->{'_rank'} = $self->{'_prev'}->rank() + 1;
}


#line 611

#-----------
sub remove {
#-----------
    my($self,%param) = @_;
    my $updateRank = $param{-UPDATE} || $param{'-update'}  || 0;
    my $ret = $param{-RET} || $param{'-ret'} || 'next';

    $DEBUG==2 && do{ print STDERR "$ID: removing ${\$self->name}; ret = $ret";<STDIN>; };

    ## This set of conditionals involves primarily pointer shuffling.
    ## The special case of destroying a vector of size 1 is handled.

    if($self->is_first()) {
	$DEBUG==2 && print STDERR "---> removing first object: ${\$self->name()}.\n";
	if($self->is_last) {
#	    print "Removing only object in vector: ${\$self->name}.\n";
	    $self->_destroy_master();
	    return $self->destroy;
	} else {
	    undef ($self->{'_next'}->{'_prev'});
	    $self->_update_first($self->{'_next'});
	}

    } elsif($self->is_last()) {
	$DEBUG==2 && print STDERR "---> removing last object: ${\$self->name()}.\n";
	undef ($self->{'_prev'}->{'_next'});
	$self->_update_last($self->{'_prev'});

    } else {
	$DEBUG==2 && print STDERR "---> removing internal object.\n";
	$self->{'_prev'}->{'_next'} = $self->{'_next'};
	$self->{'_next'}->{'_prev'} = $self->{'_prev'};
    }

    $updateRank && $self->_update_rank();
    $self->{'_master'}->{'_size'}--;

#    print "new vector size = ",$self->size,"\n"; <STDIN>;

    my($retObj);

    if( $self->size) {
	if($ret eq 'first') { $retObj = $self->first(); }
	elsif($ret eq 'last') { $retObj = $self->last(); }
	elsif($ret eq 'next') { $retObj = $self->next(); }
	elsif($ret eq 'prev') { $retObj = $self->prev(); }
    }

    ## Destroy the object.
#    $self->destroy;

    $DEBUG && do{ print STDERR "$ID: returning ${\$retObj->name}";<STDIN>; };

    $retObj;
}

sub _update_first {
    my($self,$first) = @_;
    $DEBUG && print STDERR "Updating first.\n";
    undef ($first->{'_prev'});
    $self->{'_master'}->{'_first'} = $first;
}

sub _update_last {
    my($self,$last) = @_;
    $DEBUG && print STDERR "Updating last.\n";
    undef ($last->{'_next'});
    $self->{'_master'}->{'_last'} = $last;
}


#line 691

#---------------
sub remove_all {
#---------------
    my($self,%param) = @_;

    $DEBUG==2 && print STDERR "DESTROYING VECTOR $self ${\$self->name}";

#    print "$ID Removing all.";

    $self = $self->first();

    while(ref $self) {
#	print "$ID: removing ${\$self->name}\n";
	$self = $self->remove(-RET=>'next');
    }
}


#line 720

#---------
sub shift {
#---------
    my($self,%param) = @_;
    $self = $self->first();
    $self = $self->remove(%param);
}


#line 740

#----------
sub chop {
#----------
    my($self,%param) = @_;
    $self = $self->last();
    $self = $self->remove(%param);
}



#line 763

#-----------
sub insert {
#-----------
    my($self,$object,$where) = @_;
    my($first);
    $where ||= 'after';

    $self->_set_master($self) unless $self->{'_master'}->{'_set'};

    ref($object) || return $self->master->throw("Can't insert. Not an object: $object");

    if($where eq 'before') {
	$object->{'_next'} = $self;
	$object->{'_prev'} = $self->{'_prev'};
	$object->{'_master'} = $self->{'_master'};
	$self->{'_prev'}->{'_next'} = $object;
	$self->{'_prev'} = $object;
    } else {
	$object->{'_prev'} = $self;
	$object->{'_next'} = $self->{'_next'};
	$object->{'_master'} = $self->{'_master'};
	$self->{'_next'}->{'_prev'} = $object;
	$self->{'_next'} = $object;
    }
    $self->{'_master'}->{'_size'}++;
    $object->Bio::Root::Vector::_index();  ##Fully qualified to disambiguate a potentially common method name.
    $self->_update_rank();
}

sub _update_rank {
    my($self) = @_;
    my $current = $self->first();
    my $count = 0;
    $DEBUG && print STDERR "$ID: Updating rank.\n";
    do{
	$count++;
	$current->{'_rank'} = $count;

    } while($current = $current->next());
}


#line 816

#----------
sub list {
#----------
    my($self,$start,$stop) = @_;
    my(@list);

    $start ||= 1;
    $stop  ||= 'last';

    if( $start =~ /first|beg|start/i or $start <= 1 ) {
	$start = $self->first();
    }

    if( $stop =~ /last|end|stop/i ) {
	$stop = $self->last();
    }

    ref($start) || ($start = $self->first());
    ref($stop)  || ($stop = $self->last());

    my $obj = $start;
    my $fini = 0;
    do{
	push @list, $obj;
	if($obj eq $stop) { $fini = 1; }
    } while( $obj = $obj->next() and !$fini);

    @list;
}


#line 860

#---------'
sub sort {
#---------
    my ($self,$sortBy,$reverse) = @_;
    my (@unsortedList,@sortedList);

    $sortBy ||= 'rank';
    my $rankBy = $self->rank_by;

    ### Build the initial unsorted list.
    my $obj = $self->first();
    do{
	push @unsortedList, $obj;
    } while( $obj = $obj->next());

#    print "UNSORTED LIST:\n";
#    foreach(@unsortedList) {print $_->name().' '};<STDIN>;

    ### Sort it.
    if( $sortBy =~ /rank/i) {
#	print "sorting by rank";
	if($reverse) {
#	    print " (reverse).\n";
	    @sortedList = reverse sort _sort_by_rank @unsortedList;
	} else {
	    @sortedList = sort _sort_by_rank @unsortedList;
	}
    } elsif( $sortBy =~ /name/i) {
#	print "sorting by name";
	if($reverse) {
#	    print "(reverse).\n";
	    @sortedList = reverse sort _sort_by_name @unsortedList;
	} else {
	    @sortedList = sort _sort_by_name @unsortedList;
	}
    } else {
#	print "unknown sort criteria: $sortBy\n";
	$self->warn("Invalid sorting criteria: $sortBy.",
		    "Sorting by rank.");
	@sortedList = sort _sort_by_rank @unsortedList;
    }


#    if($reverse) { @sortedList = reverse sort @sortedList;  }

#    print "SORTED LIST:\n";
#    foreach(@sortedList) {print $_->name().' '};<STDIN>;

    ### Re-load the Vector with the sorted list.
    my $count=0;

    $self = $sortedList[0];
    $self->_set_master($self);
    $self->_set_rank_by($rankBy);

    my($i);
    my $current = $self;
    for($i=1; $i<@sortedList; $current=$sortedList[$i], $i++) {
	$current->add($sortedList[$i]);
	if($i==$#sortedList) { $sortedList[$i]->{'_next'} = undef;}
    }

    $self->last();
}

sub _sort_by_rank { my $aRank = $a->rank(); my $bRank = $b->rank(); $aRank <=> $bRank; }

sub _sort_by_name { my $aName = $a->name(); my $bName = $b->name(); $aName cmp $bName; }



#line 943

#-------------
sub valid_any {
#-------------
    my $self = &shift(@_);

    my $obj = $self->first();
    do{
	return 1 if $obj->valid();
    } while( $obj = $obj->next());

   return undef;
}


#line 968

#--------------
sub valid_all {
#--------------
    my $self = &shift(@_);

    my $obj = $self->first();
    do{
	return  unless $obj->valid();
    } while( $obj = $obj->next());

   return 1;
}

sub _display_stats {
# This could be fleshed out a bit...

    my( $self, $OUT ) = @_;

    printf ( $OUT "%-11s %s\n","RANK:", $self->rank());
    printf ( $OUT "%-11s %s\n","RANK BY:", $self->rank_by());
}

1;
__END__

#####################################################################################
#                                 END OF CLASS                                      #
#####################################################################################

#line 1049

1;
