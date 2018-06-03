#line 1 "Bio/AnalysisResultI.pm"
#-----------------------------------------------------------------
# $Id: AnalysisResultI.pm,v 1.5 2002/10/22 07:38:24 lapp Exp $
#
# BioPerl module Bio::AnalysisResultI
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# Derived from Bio::Tools::AnalysisResult by Hilmar Lapp <hlapp@gmx.net>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

# POD documentation - main docs before the code

#line 82


# Let the code begin...


package Bio::AnalysisResultI;
use strict;
use vars qw(@ISA);

use Bio::Root::RootI;

@ISA = qw( Bio::Root::RootI );


#line 106

#---------------------
sub analysis_query {
#---------------------
    my ($self) = @_;
    $self->throw_not_implemented;
}


#line 130

#---------------
sub analysis_subject { 
#---------------
    my ($self) = @_; 
    return undef;
}

#line 148

#---------------
sub analysis_subject_version { 
#---------------
    my ($self) = @_; 
    return undef;
}


#line 165

#---------------------
sub analysis_date {
#---------------------
    my ($self) = @_;
    $self->throw_not_implemented;
}

#line 183

#-------------
sub analysis_method { 
#-------------
    my ($self) = @_;  
    $self->throw_not_implemented;
}

#line 200

#---------------------
sub analysis_method_version {
#---------------------
    my ($self) = @_; 
    $self->throw_not_implemented;
}

#line 220

#---------------------
sub next_feature {
#---------------------
    my ($self);
    $self->throw_not_implemented;
}


1;
