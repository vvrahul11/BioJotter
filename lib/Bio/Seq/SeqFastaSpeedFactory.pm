#line 1 "Bio/Seq/SeqFastaSpeedFactory.pm"
# $Id: SeqFastaSpeedFactory.pm,v 1.3 2002/11/07 23:54:23 lapp Exp $
#
# BioPerl module for Bio::Seq::SeqFactory
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 70


# Let the code begin...


package Bio::Seq::SeqFastaSpeedFactory;
use vars qw(@ISA);
use strict;

use Bio::Root::Root;
use Bio::Factory::SequenceFactoryI;
use Bio::Seq;
use Bio::PrimarySeq;

@ISA = qw(Bio::Root::Root Bio::Factory::SequenceFactoryI);

#line 96

sub new {
  my($class,@args) = @_;
  my $self = $class->SUPER::new(@args);
  return $self;
}


#line 118

sub create {
    my ($self,%param) = @_;

    my $sequence = $param{'-seq'}  || $param{'-SEQ'};
    my $fulldesc = $param{'-desc'} || $param{'-DESC'};
    my $id       = $param{'-id'}   || $param{'-ID'} ||
	           $param{'-primary_id'}   || $param{'-PRIMARY_ID'};

    my $seq = bless {}, "Bio::Seq";
    my $t_pseq = $seq->{'primary_seq'} = bless {}, "Bio::PrimarySeq";
    $t_pseq->{'seq'}  = $sequence;
    $t_pseq->{'desc'} = $fulldesc;
    $t_pseq->{'display_id'} = $id;
    $t_pseq->{'primary_id'} = $id;
    $seq->{'primary_id'} = $id; # currently Bio::Seq does not delegate this
    if( $sequence ) {
	$t_pseq->_guess_alphabet();
    }

    return $seq;
}

1;

