#line 1 "Bio/SeqIO/game/seqHandler.pm"
# $Id: seqHandler.pm,v 1.15 2002/06/24 04:29:31 jason Exp $
#
# BioPerl module for Bio::SeqIO::game::seqHandler
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

package Bio::SeqIO::game::seqHandler;
use vars qw{ $AUTOLOAD @ISA };

use XML::Handler::Subs;
use Bio::Root::Root;
use Bio::Seq::SeqFactory;

@ISA = qw(Bio::Root::Root XML::Handler::Subs);

sub new {
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    my ($seq,$sb) = $self->_rearrange([qw(SEQ SEQBUILDER)], @args);
    $self->{'string'} = '';
    $self->{'seq'} = $seq;
    $self->sequence_factory($sb || new Bio::Seq::SeqFactory(-type => 'Bio::Seq'));
    return $self;
}

#line 80

sub sequence_factory{
   my ($self,$obj) = @_;   
   if( defined $obj ) {
       if( ! ref($obj) || ! $obj->isa('Bio::Factory::SequenceFactoryI') ) {
	   $self->throw("Must provide a valid Bio::Factory::SequenceFactoryI object to ".ref($self)." sequence_factory()");
       }
       $self->{'_seqio_seqfactory'} = $obj;
   }
   if( ! defined $self->{'_seqio_seqfactory'} ) {
       $self->throw("No SequenceBuilder defined for SeqIO::game::seqHandler object");
   }

   return $self->{'_seqio_seqfactory'};
}

#line 105

# Basic PerlSAX
sub start_document            {
    my ($self, $document) = @_;
    $self->{'in_current_seq'} = 'false';    
    $self->{'Names'} = [];
    $self->{'string'} = '';
}

#line 123

sub end_document     {
    my ($self, $document) = @_;
    delete $self->{'Names'};
    return  $self->sequence_factory->create
	( -seq => $self->{'residues'},
	  -alphabet => $self->{'alphabet'},
	  -id => $self->{'seq'},
	  -accession => $self->{'accession'},
	  -desc => $self->{'desc'},
	  -length => $self->{'length'},
	  );
}


#line 147

sub start_element             {
    my ($self, $element) = @_;

    push @{$self->{'Names'}}, $element->{'Name'};
    $self->{'string'} = '';

    if ($element->{'Name'} eq 'bx-seq:seq') {
	if ($element->{'Attributes'}->{'bx-seq:id'} eq $self->{'seq'}) {
	    $self->{'in_current_seq'} = 'true';
	    $self->{'alphabet'} = $element->{'Attributes'}->{'bx-seq:type'};
	    $self->{'length'} =  $element->{'Attributes'}->{'bx-seq:length'};
	} else {
	    #This is not the sequence we want to import, but that's ok
	}
    }
    return 0;
}

#line 175

sub end_element               {
    my ($self, $element) = @_;

    if ($self->{'in_current_seq'} eq 'true') {      
	if ($self->in_element('bx-seq:residues')) {
	    while ($self->{'string'} =~ s/\s+//) {};
	    $self->{'residues'} = $self->{'string'};
	}


	if ($self->in_element('bx-seq:name')) {
	    $self->{'string'} =~ s/^\s+//g;
	    $self->{'string'} =~ s/\s+$//;
	    $self->{'string'} =~ s/\n//g;
	    $self->{'name'} = $self->{'string'};
	}


	if ($self->in_element('bx-link:id')  && $self->within_element('bx-link:dbxref')) {
	    $self->{'string'} =~ s/^\s+//g;
	    $self->{'string'} =~ s/\s+$//;
	    $self->{'string'} =~ s/\n//g;
	    $self->{'accession'} = $self->{'string'};
	}

	if ($self->in_element('bx-seq:description')) {
	    $self->{'desc'} = $self->{'string'};
	}

	if ($self->in_element('bx-seq:seq')) {
	    $self->{'in_current_seq'} = 'false';
	}
    }

    pop @{$self->{'Names'}};

}

#line 223

sub characters   {
    my ($self, $text) = @_;
    $self->{'string'} .= $text->{'Data'};
}

#line 238

sub in_element {
    my ($self, $name) = @_;

    return ($self->{'Names'}[-1] eq $name);
}

#line 254

sub within_element {
    my ($self, $name) = @_;

    my $count = 0;
    foreach my $el_name (@{$self->{'Names'}}) {
	$count ++ if ($el_name eq $name);
    }

    return $count;
}

#line 275

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
