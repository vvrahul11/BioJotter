#line 1 "Bio/SeqIO/ace.pm"
# $Id: ace.pm,v 1.15 2002/10/25 16:23:16 jason Exp $
#
# BioPerl module for Bio::SeqIO::ace
#
# Cared for by James Gilbert <jgrg@sanger.ac.uk>
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 66

#'
# Let the code begin...

package Bio::SeqIO::ace;
use strict;
use vars qw(@ISA);

use Bio::SeqIO;
use Bio::Seq;
use Bio::Seq::SeqFactory;

@ISA = qw(Bio::SeqIO);

sub _initialize {
  my($self,@args) = @_;
  $self->SUPER::_initialize(@args);   
  if( ! defined $self->sequence_factory ) {
      $self->sequence_factory(new Bio::Seq::SeqFactory(-verbose => $self->verbose(), -type => 'Bio::PrimarySeq'));      
  }
}

#line 97

{
    my %bio_mol_type = (
        'dna'       => 'dna',
        'peptide'   => 'protein',
    );
    
    sub next_seq {
        my( $self ) = @_;
        local $/ = "";  # Split input on blank lines

        my $fh = $self->_filehandle;
        my( $type, $id );
        while (<$fh>) {
            if (($type, $id) = /^(DNA|Peptide)[\s:]+(.+?)\s*\n/si) {
                s/^.+$//m;  # Remove first line
                s/\s+//g;   # Remove whitespace
                last;
            }
        }
        # Return if there weren't any DNA or peptide objects
        return unless $type;
        
        # Choose the molecule type
        my $mol_type = $bio_mol_type{lc $type}
            or $self->throw("Can't get Bio::Seq molecule type for '$type'");

        # Remove quotes from $id
        $id =~ s/^"|"$//g;
        
        # Un-escape forward slashes, double quotes, percent signs,
        # semi-colons, tabs, and backslashes (if you're mad enough
        # to have any of these as part of object names in your acedb
        # database).
	$id =~ s/\\([\/"%;\t\\])/$1/g;
#"
	# Called as next_seq(), so give back a Bio::Seq
	return $self->sequence_factory->create(
					       -seq        => $_,
					       -primary_id => $id,
					       -display_id => $id,
					       -alphabet    => $mol_type,
					       );        
    }
}

#line 153

sub write_seq {
    my ($self, @seq) = @_;
    
    foreach my $seq (@seq) {
	$self->throw("Did not provide a valid Bio::PrimarySeqI object") 
	    unless defined $seq && ref($seq) && $seq->isa('Bio::PrimarySeqI');
        my $mol_type = $seq->alphabet;
        my $id = $seq->display_id;
        
        # Escape special charachers in id
        $id =~ s/([\/"%;\t\\])/\\$1/g;
#"        
        # Print header for DNA or Protein object
        if ($mol_type eq 'dna') {
            $self->_print( 
                qq{\nSequence : "$id"\nDNA "$id"\n},
                qq{\nDNA : "$id"\n},
            );
        }
        elsif ($mol_type eq 'protein') {
            $self->_print(
                qq{\nProtein : "$id"\nPeptide "$id"\n},
                qq{\nPeptide : "$id"\n},
            );
        }
        else {
            $self->throw("Don't know how to produce ACeDB output for '$mol_type'");
        }

        # Print the sequence
        my $str = $seq->seq;
        my( $formatted_seq );
        while ($str =~ /(.{1,60})/g) {
            $formatted_seq .= "$1\n";
        }
        $self->_print($formatted_seq, "\n");
    }

    $self->flush if $self->_flush_on_write && defined $self->_fh;
    return 1;
}

1;
