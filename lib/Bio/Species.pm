#line 1 "Bio/Species.pm"
# $Id: Species.pm,v 1.24 2002/12/05 13:46:30 heikki Exp $
#
# BioPerl module for Bio::Species
#
# Cared for by James Gilbert <jgrg@sanger.ac.uk>
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 59


#' Let the code begin...


package Bio::Species;
use vars qw(@ISA);
use strict;

# Object preamble - inherits from Bio::Root::Object

use Bio::Root::Root;


@ISA = qw(Bio::Root::Root);

sub new {
  my($class,@args) = @_;

  my $self = $class->SUPER::new(@args);

  $self->{'classification'} = [];
  $self->{'common_name'} = undef;
  my ($classification) = $self->_rearrange([qw(CLASSIFICATION)], @args);
  if( defined $classification &&
      (ref($classification) eq "ARRAY") ) {
      $self->classification(@$classification);
  }
  return $self;
}

#line 112


sub classification {
    my ($self,@args) = @_;

    if (@args) {

	my ($classif,$force);
	if(ref($args[0])) {
	    $classif = shift(@args);
	    $force = shift(@args);
	} else {
	    $classif = \@args;
	}
	
        # Check the names supplied in the classification string
	# Species should be in lower case
	if(! $force) {
	    $self->validate_species_name($classif->[0]);
	    # All other names must be in title case
	    foreach  (@$classif) {
		$self->validate_name( $_ );
	    }
	}
        # Store classification
        $self->{'classification'} = $classif;
    }
    return @{$self->{'classification'}};
}

#line 153

sub common_name{
    my $self = shift;

    return $self->{'common_name'} = shift if @_;
    return $self->{'common_name'};
}

#line 173

sub variant{
    my $self = shift;

    return $self->{'variant'} = shift if @_;
    return $self->{'variant'};
}

#line 192

sub organelle {
    my($self, $name) = @_;

    if ($name) {
        $self->{'organelle'} = $name;
    } else {
        return $self->{'organelle'}
    }
}

#line 215


sub species {
    my($self, $species) = @_;

    if ($species) {
        $self->validate_species_name( $species );
        $self->{'classification'}[0] = $species;
    }
    return $self->{'classification'}[0];
}

#line 239


sub genus {
    my($self, $genus) = @_;

    if ($genus) {
        $self->validate_name( $genus );
        $self->{'classification'}[1] = $genus;
    }
    return $self->{'classification'}[1];
}

#line 261

sub sub_species {
    my( $self, $sub ) = @_;

    if ($sub) {
        $self->{'_sub_species'} = $sub;
    }
    return $self->{'_sub_species'};
}

#line 282


sub binomial {
    my( $self, $full ) = @_;

    my( $species, $genus ) = $self->classification();
    unless( defined $species) {
	$species = 'sp.';
	$self->warn("classification was not set");
    }
    $genus = ''   unless( defined $genus);
    my $bi = "$genus $species";
    if (defined($full) && ((uc $full) eq 'FULL')) {
	my $ssp = $self->sub_species;
        $bi .= " $ssp" if $ssp;
    }
    return $bi;
}

sub validate_species_name {
    my( $self, $string ) = @_;

    return 1 if $string eq "sp.";
    return 1 if $string =~ /^[a-z][\w\s]+$/i;
    $self->throw("Invalid species name '$string'");
}

sub validate_name {
    return 1; # checking is disabled as there is really not much we can
              # enforce HL 2002/10/03
#     my( $self, $string ) = @_;

#     return 1 if $string =~ /^[\w\s\-\,\.]+$/ or
#         $self->throw("Invalid name '$string'");
}

#line 328

sub ncbi_taxid {
    my $self = shift;

    return $self->{'_ncbi_taxid'} = shift if @_;
    return $self->{'_ncbi_taxid'};
}

1;

__END__
