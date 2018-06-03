#line 1 "Bio/Search/Result/ResultI.pm"
#-----------------------------------------------------------------
# $Id: ResultI.pm,v 1.16 2002/11/13 11:23:11 sac Exp $
#
# BioPerl module Bio::Search::Result::ResultI
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# Originally created by Aaron Mackey <amackey@virginia.edu>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

# POD documentation - main docs before the code

#line 102

#'
# Let the code begin...


package Bio::Search::Result::ResultI;

use strict;
use vars qw(@ISA);

use Bio::AnalysisResultI;

@ISA = qw( Bio::AnalysisResultI );


#line 128

sub next_hit {
    my ($self,@args) = @_;
    $self->throw_not_implemented;
}

#line 144

sub query_name {
    my ($self,@args) = @_;
    $self->throw_not_implemented;
}

#line 159

sub query_accession {
    my ($self,@args) = @_;
    $self->throw_not_implemented;
}


#line 176

sub query_length {
    my ($self,@args) = @_;
    $self->throw_not_implemented;
}

#line 192

sub query_description {
    my ($self,@args) = @_;
    $self->throw_not_implemented;
}


#line 209

sub database_name {
    my ($self,@args) = @_;

    $self->throw_not_implemented;
}

#line 228

sub database_letters {
    my ($self,@args) = @_;
    $self->throw_not_implemented();
}

#line 245

sub database_entries {
    my ($self,@args) = @_;

    $self->throw_not_implemented();
}

#line 262

sub get_parameter{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

#line 277

sub available_parameters{
   my ($self) = @_;
   $self->throw_not_implemented();
}

#line 293

sub get_statistic{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

#line 308

sub available_statistics{
   my ($self) = @_;
   $self->throw_not_implemented();
}

#line 323

sub algorithm{
   my ($self) = @_;
   $self->throw_not_implemented();
}

#line 338

sub algorithm_version{
   my ($self) = @_;
   $self->throw_not_implemented();
}


#line 357

sub algorithm_reference{
   my ($self) = @_;
   return '';
}

#line 373

sub num_hits{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

#line 389

sub hits{
   my ($self,@args) = @_;
   $self->throw_not_implemented();
}

#line 415

#-----------
sub no_hits_found { shift->throw_not_implemented }



#line 430

sub set_no_hits_found { shift->throw_not_implemented }


#line 443

sub iterations { shift->throw_not_implemented }


#line 456

sub psiblast { shift->throw_not_implemented }

1;


