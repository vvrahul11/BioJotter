#line 1 "Bio/SeqIO/game/featureHandler.pm"
# $Id: featureHandler.pm,v 1.9 2002/06/04 02:54:48 jason Exp $
#
# BioPerl module for Bio::SeqIO::game::featureHandler
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

package Bio::SeqIO::game::featureHandler;

use Bio::SeqFeature::Generic;
use XML::Handler::Subs;

use vars qw{ $AUTOLOAD @ISA };
use strict;

@ISA = qw(XML::Handler::Subs);

sub new {
    my ($caller,$seq,$length,$type) = @_;
    my $class = ref($caller) || $caller;
    my $self = bless ({
	seq      => $seq,
	type     => $type,
	length   => $length,
	string   => '',
	feat     => {},
	feats    => [],
	comp_id  => 1,
    }, $class);
    return $self;
}

#line 85

# Basic PerlSAX
sub start_document            {
    my ($self, $document) = @_;

    $self->{'Names'} = [];
    $self->{'Nodes'} = [];
    $self->{'feats'} = [];

}

#line 105

sub end_document              {
    my ($self, $document) = @_;

    delete $self->{'Names'};
    return $self->{'feats'};
}

#line 122

sub start_element             {
    my ($self, $element) = @_;

    push @{$self->{'Names'}}, $element->{'Name'};
    $self->{'string'} = '';

    if ($self->in_element('bx-feature:seq_relationship')) {
	if (defined $element->{'Attributes'}->{'bx-feature:seq'} && 
	    defined $self->{'seq'} &&
	    $element->{'Attributes'}->{'bx-feature:seq'} eq $self->{'seq'}) {
	    $self->{'in_current_seq'} = 'true';
	} 
    }


    if ($self->in_element('bx-computation:computation')) {
	$self->{'feat'} = {};
	if (defined $element->{'Attributes'}->{'bx-computation:id'}) {
	    $self->{'feat'}->{'computation_id'} = $element->{'Attributes'}->{'bx-computation:id'};
	}  else {
	    $self->{'feat'}->{'computation_id'} = $self->{'comp_id'};
	    $self->{'comp_id'}++;
	}
    }

    if ($self->in_element('bx-feature:feature')) {
	if (defined $element->{'Attributes'}->{'bx-feature:id'}) {
	    $self->{'feat'}->{'id'} = $element->{'Attributes'}->{'bx-feature:id'};
	}
    }

    if ($self->in_element('bx-annotation:annotation')) {
	$self->{'feat'} = {};
	$self->{'feat'}->{'annotation_id'} = $element->{'Attributes'}->{'bx-annotation:id'};
	$self->{'feat'}->{'annotation_name'} = $element->{'Attributes'}->{'bx-annotation:name'};
    }

    return 0;
}

#line 172

sub end_element               {
    my ($self, $element) = @_;

    if ($self->in_element('bx-computation:program')) {
	$self->{'string'} =~ s/^\s+//g;
	$self->{'string'} =~ s/\s+$//;
	$self->{'string'} =~ s/\n//g;
	$self->{'feat'}->{'source_tag'} = $self->{'string'};
    }

    if ($self->in_element('bx-annotation:author')) {
	$self->{'string'} =~ s/^\s+//g;
	$self->{'string'} =~ s/\s+$//;
	$self->{'string'} =~ s/\n//g;
	$self->{'feat'}->{'source_tag'} = "Annotated by $self->{'string'}.";
    }

    if ($self->in_element('bx-feature:type')) {
	$self->{'string'} =~ s/^\s+//g;
	$self->{'string'} =~ s/\s+$//;
	$self->{'string'} =~ s/\n//g;
	$self->{'feat'}->{'primary_tag'} = $self->{'string'};
    }

    if ($self->in_element('bx-feature:start')) {
	$self->{'string'} =~ s/^\s+//g;
	$self->{'string'} =~ s/\s+$//;
	$self->{'string'} =~ s/\n//g;
	$self->{'feat'}->{'start'} = $self->{'string'};
    }

    if ($self->in_element('bx-feature:end')) {
	$self->{'string'} =~ s/^\s+//g;
	$self->{'string'} =~ s/\s+$//;
	$self->{'string'} =~ s/\n//g;
	$self->{'feat'}->{'end'} = $self->{'string'};
    }

    if ($self->in_element('bx-computation:score')) {
	$self->{'string'} =~ s/^\s+//g;
	$self->{'string'} =~ s/\s+$//;
	$self->{'string'} =~ s/\n//g;
	$self->{'feat'}->{'score'} = $self->{'string'};
    }

    if ($self->in_element('bx-feature:seq_relationship')) {
	
	if ($self->{'feat'}->{'start'} > $self->{'feat'}->{'end'}) {
	    my $new_start = $self->{'feat'}->{'end'};
	    $self->{'feat'}->{'end'} = $self->{'feat'}->{'start'};
	    $self->{'feat'}->{'start'} = $new_start;
	    $self->{'feat'}->{'strand'} = -1;
	} else {
	    $self->{'feat'}->{'strand'} = 1;
	}
	my $new_feat = new Bio::SeqFeature::Generic
	    (
	     -start   => $self->{'feat'}->{'start'},
	     -end     => $self->{'feat'}->{'end'},
	     -strand  => $self->{'feat'}->{'strand'},
	     -source  => $self->{'feat'}->{'source_tag'},
	     -primary => $self->{'feat'}->{'primary_tag'},
	     -score   => $self->{'feat'}->{'score'},
	     );
	
	if (defined $self->{'feat'}->{'computation_id'}) {
	    $new_feat->add_tag_value('computation_id', 
				     $self->{'feat'}->{'computation_id'} );
	} elsif (defined $self->{'feat'}->{'annotation_id'}) {
	    $new_feat->add_tag_value('annotation_id', 
				     $self->{'feat'}->{'annotation_id'} );
	}
	if (defined $self->{'feat'}->{'id'}) {
	    $new_feat->add_tag_value('id', $self->{'feat'}->{'id'} );
	}

	push @{$self->{'feats'}}, $new_feat;
	$self->{'feat'} = { 
	    seqid => $self->{'feat'}->{'curr_seqid'},
	    primary_tag => $self->{'feat'}->{'primary_tag'},
	    source_tag => $self->{'feat'}->{'source_tag'},
	    computation_id => $self->{'feat'}->{'computation_id'},
	    annotation_id => $self->{'feat'}->{'annotation_id'}
	}
    }


    pop @{$self->{'Names'}};
    pop @{$self->{'Nodes'}};

}

#line 274

sub characters   {
    my ($self, $text) = @_;
    $self->{'string'} .= $text->{'Data'};
}

#line 289

sub in_element {
    my ($self, $name) = @_;
    
    return (defined $self->{'Names'}[-1] && 
	    $self->{'Names'}[-1] eq $name);
}

#line 306

sub within_element {
    my ($self, $name) = @_;

    my $count = 0;
    foreach my $el_name (@{$self->{'Names'}}) {
	$count ++ if ($el_name eq $name);
    }

    return $count;
}

#line 327

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
