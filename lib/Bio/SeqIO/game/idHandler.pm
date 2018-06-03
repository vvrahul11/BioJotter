#line 1 "Bio/SeqIO/game/idHandler.pm"
# $Id: idHandler.pm,v 1.8 2001/11/20 02:09:38 lstein Exp $
#
# BioPerl module for Bio::SeqIO::game::idHandler
#
# Cared for by Brad Marshall <bradmars@yahoo.com>
#         
# Copyright Brad Marshall
#
# You may distribute this module under the same terms as perl itself
# _history
# June 25, 2000     written by Brad Marshall
#
# POD documentation - main docs before the code

#line 46

# This template file is in the Public Domain.
# You may do anything you want with this file.
#

package Bio::SeqIO::game::idHandler;
use Bio::Root::Root;

use vars qw{ $AUTOLOAD @ISA };
use strict;
@ISA = qw(Bio::Root::Root);
sub new {
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    
    # initialize ids
    $self->{'ids'} = [];

    return $self;
}

#line 76

# Basic PerlSAX
sub start_document            {
    my ($self, $document) = @_;
}

#line 91

sub end_document              {
    my ($self, $document) = @_;
    return $self->{'ids'};
}

#line 106

sub start_element             {
    my ($self, $element) = @_;

    if ($element->{'Name'} eq 'bx-seq:seq') {
	if ($element->{'Attributes'}->{'bx-seq:id'}) {
	    push @{$self->{'ids'}}, $element->{'Attributes'}->{'bx-seq:id'};
	} else {
	    if ($self->can('warn')) {
		$self->warn('WARNING: Attribute bx-seq:id is required on bx-seq:seq. Sequence will not be parsed.');
	    } else {
		warn('WARNING: Attribute bx-seq:id is required on bx-seq:seq. Sequence will not be parsed.');
	    }
	}
    }
    return 0;
}

#line 133

sub end_element               {
    my ($self, $element) = @_;

}

#line 148

sub characters   {
    my ($self, $text) = @_;
}


#line 163

# Others
sub AUTOLOAD {
    my $self = shift;

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    print "UNRECOGNIZED $method\n";
}

1;

__END__
