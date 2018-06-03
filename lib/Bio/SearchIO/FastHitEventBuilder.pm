#line 1 "Bio/SearchIO/FastHitEventBuilder.pm"
# $Id: FastHitEventBuilder.pm,v 1.6 2002/12/05 13:46:35 heikki Exp $
#
# BioPerl module for Bio::SearchIO::FastHitEventBuilder
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 82


# Let the code begin...


package Bio::SearchIO::FastHitEventBuilder;
use vars qw(@ISA %KNOWNEVENTS);
use strict;

use Bio::Root::Root;
use Bio::SearchIO::EventHandlerI;
use Bio::Search::HSP::HSPFactory;
use Bio::Search::Hit::HitFactory;
use Bio::Search::Result::ResultFactory;

@ISA = qw(Bio::Root::Root Bio::SearchIO::EventHandlerI);

#line 111

sub new { 
    my ($class,@args) = @_;
    my $self = $class->SUPER::new(@args);
    my ($hspF,$hitF,$resultF) = $self->_rearrange([qw(HIT_FACTORY
						      RESULT_FACTORY)],@args);
    $self->register_factory('hit', $hitF || Bio::Search::Hit::HitFactory->new());
    $self->register_factory('result', $resultF || Bio::Search::Result::ResultFactory->new());

    return $self;
}

# new comes from the superclass

#line 135

sub will_handle{
   my ($self,$type) = @_;
   # these are the events we recognize
   return ( $type eq 'hit' || $type eq 'result' );
}

#line 145

#line 155

sub start_result {
   my ($self,$type) = @_;
   $self->{'_resulttype'} = $type;
   $self->{'_hits'} = [];
   return;
}

#line 171

sub end_result {
    my ($self,$type,$data) = @_;    
    if( defined $data->{'runid'} &&
	$data->{'runid'} !~ /^\s+$/ ) {	
	
	if( $data->{'runid'} !~ /^lcl\|/) { 
	    $data->{"RESULT-query_name"}= $data->{'runid'};
	} else { 
	    ($data->{"RESULT-query_name"},$data->{"RESULT-query_description"}) = split(/\s+/,$data->{"RESULT-query_description"},2);
	}
	
	if( my @a = split(/\|/,$data->{'RESULT-query_name'}) ) {
	    my $acc = pop @a ; # this is for accession |1234|gb|AAABB1.1|AAABB1
	    # this is for |123|gb|ABC1.1|
	    $acc = pop @a if( ! defined $acc || $acc =~ /^\s+$/);
	    $data->{"RESULT-query_accession"}= $acc;
	}
	delete $data->{'runid'};
    }
    my %args = map { my $v = $data->{$_}; s/RESULT//; ($_ => $v); } 
               grep { /^RESULT/ } keys %{$data};
    
    $args{'-algorithm'} =  uc( $args{'-algorithm_name'} || $type);
    $args{'-hits'}      =  $self->{'_hits'};
    my $result = $self->factory('result')->create(%args);
    $self->{'_hits'} = [];
    return $result;
}

#line 211

sub start_hit{
    my ($self,$type) = @_;
    return;
}


#line 228

sub end_hit{
    my ($self,$type,$data) = @_;   
    my %args = map { my $v = $data->{$_}; s/HIT//; ($_ => $v); } grep { /^HIT/ } keys %{$data};
    $args{'-algorithm'} =  uc( $args{'-algorithm_name'} || $type);
    $args{'-query_len'} =  $data->{'RESULT-query_length'};
    my ($hitrank) = scalar @{$self->{'_hits'}} + 1;
    $args{'-rank'} = $hitrank;
    my $hit = $self->factory('hit')->create(%args);
    push @{$self->{'_hits'}}, $hit;
    $self->{'_hsps'} = [];
    return $hit;
}

#line 245

#line 258

sub register_factory{
   my ($self, $type,$f) = @_;
   if( ! defined $f || ! ref($f) || 
       ! $f->isa('Bio::Factory::ObjectFactoryI') ) { 
       $self->throw("Cannot set factory to value $f".ref($f)."\n");
   }
   $self->{'_factories'}->{lc($type)} = $f;
}


#line 280

sub factory{
   my ($self,$type) = @_;
   return $self->{'_factories'}->{lc($type)} || $self->throw("No factory registered for $type");
}

1;
