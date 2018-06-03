#line 1 "Bio/Search/Hit/HitI.pm"
#-----------------------------------------------------------------
# $Id: HitI.pm,v 1.17 2002/11/13 11:16:37 sac Exp $
#
# BioPerl module Bio::Search::Hit::HitI
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# Originally created by Aaron Mackey <amackey@virginia.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

# POD documentation - main docs before the code

#line 90

# Let the code begin...

package Bio::Search::Hit::HitI;

use Bio::Root::RootI;

use vars qw(@ISA);
use strict;

@ISA = qw( Bio::Root::RootI );


#line 112

sub name {
    my ($self,@args) = @_;
    $self->throw_not_implemented;
}

#line 127

sub description {
    my ($self,@args) = @_;
    $self->throw_not_implemented;
}

#line 142

sub accession {
    my ($self,@args) = @_;
    $self->throw_not_implemented;
}

#line 157

sub locus {
    my ($self,@args) = @_;
    $self->throw_not_implemented;
}

#line 172

sub length {
   my ($self,@args) = @_;
   $self->throw_not_implemented;
}


#line 192

sub algorithm {
    my ($self,@args) = @_;
    $self->throw_not_implemented;
}

#line 209

sub raw_score {
    $_[0]->throw_not_implemented;
}

#line 226

sub significance {
    $_[0]->throw_not_implemented;
}

#line 243

#---------
sub bits { 
#---------
    $_[0]->throw_not_implemented();
}

#line 260

sub next_hsp {
    my ($self,@args) = @_;
    $self->throw_not_implemented;
}


#line 283

#---------
sub hsps {
#---------
    my $self = shift;

    $self->throw_not_implemented();
}



#line 306

#-------------
sub num_hsps {
#-------------
    shift->throw_not_implemented();
}


#line 338

#-------------
sub seq_inds {
#-------------
    my ($self, $seqType, $class, $collapse) = @_;

    $seqType  ||= 'query';
    $class ||= 'identical';
    $collapse ||= 0;

    $seqType = 'sbjct' if $seqType eq 'hit';

    my (@inds, $hsp);    
    foreach $hsp ($self->hsps) {
	# This will merge data for all HSPs together.
	push @inds, $hsp->seq_inds($seqType, $class);
    }
    
    # Need to remove duplicates and sort the merged positions.
    if(@inds) {
	my %tmp = map { $_, 1 } @inds;
	@inds = sort {$a <=> $b} keys %tmp;
    }

    $collapse ?  &Bio::Search::BlastUtils::collapse_nums(@inds) : @inds; 
}

#line 375

sub rewind{
   my ($self) = @_;
   $self->throw_not_implemented();
}


#line 396

#----------------
sub iteration { shift->throw_not_implemented }
#----------------

#line 424

#----------------
sub found_again { shift->throw_not_implemented }
#----------------


#line 447

#-------------
sub overlap { shift->throw_not_implemented }


#line 473

#-----
sub n { shift->throw_not_implemented }

#line 503

#--------
sub p { shift->throw_not_implemented() }

#line 525

#----------
sub hsp { shift->throw_not_implemented }

#line 549

#--------------------
sub logical_length { shift->throw_not_implemented() }


#line 565

sub rank{
   my ($self,$value) = @_;
   $self->throw_not_implemented();
}

#line 583

sub each_accession_number{
   my ($self,$value) = @_;
   $self->throw_not_implemented();
}


#line 604

sub tiled_hsps { shift->throw_not_implemented }


#line 647

#---------'
sub strand { shift->throw_not_implemented }


#line 669

#---------'
sub frame { shift->throw_not_implemented }


#line 704

sub matches { shift->throw_not_implemented }

1;




