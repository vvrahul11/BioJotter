#line 1 "Bio/Annotation/StructuredValue.pm"
# $Id: StructuredValue.pm,v 1.2 2002/10/22 07:38:26 lapp Exp $
#
# BioPerl module for Bio::Annotation::StructuredValue
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#

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

#line 73


# Let the code begin...


package Bio::Annotation::StructuredValue;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Root

use Bio::AnnotationI;
use Bio::Annotation::SimpleValue;

@ISA = qw(Bio::Annotation::SimpleValue);

#line 99

sub new{
   my ($class,@args) = @_;

   my $self = $class->SUPER::new(@args);

   my ($value,$tag) = $self->_rearrange([qw(VALUE TAGNAME)], @args);

   $self->{'values'} = [];
   defined $value  && $self->value($value);
   defined $tag    && $self->tagname($tag);

   return $self;
}


#line 118

#line 129

sub as_text{
   my ($self) = @_;

   return "Value: ".$self->value;
}

#line 147

sub hash_tree{
   my ($self) = @_;
   
   my $h = {};
   $h->{'value'} = $self->value;
}

#line 169

sub tagname{
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'tagname'} = $value;
    }
    return $self->{'tagname'};
}


#line 182

#line 213

sub value{
    my ($self,$value,@args) = @_;

    # set mode?
    return $self->add_value([0], $value) if defined($value) && (@args == 0);
    # no, get mode
    # determine joins and brackets
    unshift(@args, $value);
    my ($joins, $brackets) =
	$self->_rearrange([qw(JOINS BRACKETS)], @args);
    $joins = ['; '] unless $joins;
    $brackets = ['(', ')'] unless $brackets;
    my $txt = &_to_text($self->{'values'}, $joins, $brackets);
    # if there's only brackets at the start and end, remove them
    if((@{$self->{'values'}} == 1) &&
       (length($brackets->[0]) == 1) && (length($brackets->[1]) == 1)) {
	my $re = '\\'.$brackets->[0].
	    '([^\\'.$brackets->[1].']*)\\'.$brackets->[1];
	$txt =~ s/^$re$/$1/;
    }
    return $txt;
}

sub _to_text{
    my ($arr, $joins, $brackets, $rec_n) = @_;

    $rec_n = 0 unless defined($rec_n);
    my $i = $rec_n >= @$joins ? @$joins-1 : $rec_n;
    my $txt = join($joins->[$i],
		   map {
		       ref($_) ?
			   (ref($_) eq "ARRAY" ?
			        &_to_text($_, $joins, $brackets, $rec_n+1) :
			        $_->value()) :
			   $_;
		   } @$arr);
    if($rec_n && (@$arr > 1)) {
	$txt = $brackets->[0] . $txt . $brackets->[1];
    }
    return $txt;
}

#line 269

sub get_values{
    my $self = shift;

    return @{$self->{'values'}};
}

#line 288

sub get_all_values{
    my ($self) = @_;

    # we code lazy here and just take advantage of value()
    my $txt = $self->value(-joins => ['@!@'], -brackets => ['','']);
    return split(/\@!\@/, $txt);
}

#line 324

sub add_value{
    my ($self,$index,@values) = @_;

    my $tree = $self->{'values'};
    my $lastidx = pop(@$index);
    foreach my $i (@$index) {
	if($i < 0) {
	    my $subtree = [];
	    push(@$tree, $subtree);
	    $tree = $subtree;
	} elsif((! $tree->[$i]) || (ref($tree->[$i]) eq "ARRAY")) {
	    $tree->[$i] = [] unless ref($tree->[$i]) eq "ARRAY";
	    $tree = $tree->[$i];
	} else {
	    $self->throw("element $i is a scalar but not in last dimension");
	}
    }
    if($lastidx < 0) {
	push(@$tree, @values);
    } elsif(@values < 2) {
	$tree->[$lastidx] = shift(@values);
    } else {
	$tree->[$lastidx] = [@values];
    }
    
}

1;
