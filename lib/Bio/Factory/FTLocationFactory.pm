#line 1 "Bio/Factory/FTLocationFactory.pm"
# $Id: FTLocationFactory.pm,v 1.9.2.4 2003/09/14 19:15:39 jason Exp $
#
# BioPerl module for Bio::Factory::FTLocationFactory
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gnf.org, 2002.
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

#line 75


# Let the code begin...


package Bio::Factory::FTLocationFactory;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::Root::Root;
use Bio::Factory::LocationFactoryI;
use Bio::Location::Simple;
use Bio::Location::Split;
use Bio::Location::Fuzzy;


@ISA = qw(Bio::Root::Root Bio::Factory::LocationFactoryI);

#line 105

#line 121

sub from_string{
    # the third parameter is purely optional and indicates a recursive
    # call if set
    my ($self,$locstr,$is_rec) = @_;
    my $loc;

    # there is no place in FT-formatted location strings where whitespace 
    # carries meaning, so strip it off entirely upfront
    $locstr =~ s/\s+//g if ! $is_rec;

    # does it contain an operator?
    if($locstr =~ /^([A-Za-z]+)\((.*)\)$/) {
	# yes:
	my $op = $1;
	my $oparg = $2;
	if($op eq "complement") {
	    # parse the argument recursively, then set the strand to -1
	    $loc = $self->from_string($oparg, 1);
	    $loc->strand(-1);
	} elsif(($op eq "join") || ($op eq "order") || ($op eq "bond")) {
	    # This is a split location. Split into components and parse each
	    # one recursively, then gather into a SplitLocationI instance.
	    #
	    # Note: The following code will /not/ work with nested
	    # joins (you want to have grammar-based parsing for that).
	    $loc = Bio::Location::Split->new(-verbose => $self->verbose,
					     -splittype => $op);
	    foreach my $substr (split(/,/, $oparg)) {
		$loc->add_sub_Location($self->from_string($substr, 1));
	    }
	} else {
	    $self->throw("operator \"$op\" unrecognized by parser");
	}
    } else {
	# no operator, parse away
	$loc = $self->_parse_location($locstr);
    }
    return $loc;
}

#line 174

sub _parse_location {
    my ($self, $locstr) = @_;
    my ($loc, $seqid);

    $self->debug( "Location parse, processing $locstr\n");

    # 'remote' location?
    if($locstr =~ /^(\S+):(.*)$/) {
	# yes; memorize remote ID and strip from location string
	$seqid = $1;
	$locstr = $2;
    }
    
    # split into start and end
    my ($start, $end) = split(/\.\./, $locstr);
    # remove enclosing parentheses if any; note that because of parentheses
    # possibly surrounding the entire location the parentheses around start
    # and/or may be asymmetrical
    $start =~ s/^\(+//;
    $start =~ s/\)+$//;
    $end   =~ s/^\(+// if $end;
    $end   =~ s/\)+$// if $end;

    # Is this a simple (exact) or a fuzzy location? Simples have exact start
    # and end, or is between two adjacent bases. Everything else is fuzzy.
    my $loctype = ".."; # exact with start and end as default
    my $locclass = "Bio::Location::Simple";
    if(! defined($end)) {
	if($locstr =~ /(\d+)([\.\^])(\d+)/) {
	    $start = $1;
	    $end = $3;
	    $loctype = $2;
	    $locclass = "Bio::Location::Fuzzy"
		unless (abs($end - $start) <= 1) && ($loctype eq "^");
	    
	} else {
	    $end = $start;
	}
    }
    if ( ($start =~ /[\>\<\?\.\^]/) || ($end   =~ /[\>\<\?\.\^]/) ) {
	$locclass = 'Bio::Location::Fuzzy';
    } 

    # instantiate location and initialize
    $loc = $locclass->new(-verbose => $self->verbose,
			  -start   => $start, 
			  -end     => $end, 
			  -strand  => 1,
			  -location_type => $loctype);
    # set remote ID if remote location
    if($seqid) {
	$loc->is_remote(1);
	$loc->seq_id($seqid);
    }

    # done (hopefully)
    return $loc;
    
}

1;
