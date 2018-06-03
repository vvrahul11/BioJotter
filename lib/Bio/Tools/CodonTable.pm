#line 1 "Bio/Tools/CodonTable.pm"
# $Id: CodonTable.pm,v 1.23 2002/10/22 07:38:45 lapp Exp $
#
# bioperl module for Bio::Tools::CodonTable
#
# Cared for by Heikki Lehvaslaiho <heikki@ebi.ac.uk>
#
# Copyright Heikki Lehvaslaiho
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 159


# Let the code begin...

package Bio::Tools::CodonTable;
use vars qw(@ISA @NAMES @TABLES @STARTS $TRCOL $CODONS %IUPAC_DNA 
	    %IUPAC_AA %THREELETTERSYMBOLS $VALID_PROTEIN $TERMINATOR);
use strict;

# Object preamble - inherits from Bio::Root::Root
use Bio::Root::Root;
use Bio::Tools::IUPAC;
use Bio::SeqUtils;

@ISA = qw(Bio::Root::Root);

# first set internal values for all translation tables

BEGIN { 
    @NAMES =			#id
	(
	 'Standard',		#1
	 'Vertebrate Mitochondrial',#2
	 'Yeast Mitochondrial',# 3
	 'Mold, Protozoan, and CoelenterateMitochondrial and Mycoplasma/Spiroplasma',#4
	 'Invertebrate Mitochondrial',#5
	 'Ciliate, Dasycladacean and Hexamita Nuclear',# 6
	 '', '',
	 'Echinoderm Mitochondrial',#9
	 'Euplotid Nuclear',#10
	 '"Bacterial"',# 11
	 'Alternative Yeast Nuclear',# 12
	 'Ascidian Mitochondrial',# 13
	 'Flatworm Mitochondrial',# 14
	 'Blepharisma Nuclear',# 15
	 'Chlorophycean Mitochondrial',# 16
	 '', '',  '', '',
	 'Trematode Mitochondrial',# 21
	 'Scenedesmus obliquus Mitochondrial', #22
	 'Thraustochytrium Mitochondrial' #23
	 );

    @TABLES =
	qw(
	   FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
	   FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG
	   FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG
	   FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
	   FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG
	   FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
	   '' ''
	   FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG
	   FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
	   FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
	   FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
	   FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG
	   FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG
	   FFLLSSSSYY*QCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
	   FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
	   '' '' '' ''
	   FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG   
	   FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
	   FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
	   );


    @STARTS =
	qw(
	   ---M---------------M---------------M----------------------------
	   --------------------------------MMMM---------------M------------
	   ----------------------------------MM----------------------------
	   --MM---------------M------------MMMM---------------M------------
	   ---M----------------------------MMMM---------------M------------
	   -----------------------------------M----------------------------
	   '' ''
	   -----------------------------------M----------------------------
	   -----------------------------------M----------------------------
	   ---M---------------M------------MMMM---------------M------------
	   -------------------M---------------M----------------------------
	   -----------------------------------M----------------------------
	   -----------------------------------M----------------------------
	   -----------------------------------M----------------------------
	   -----------------------------------M----------------------------
	   '' ''  '' ''
	   -----------------------------------M---------------M------------  
	   -----------------------------------M----------------------------
	   --------------------------------M--M---------------M------------
	   );

    my @nucs = qw(t c a g);
    my $x = 0;
    ($CODONS, $TRCOL) = ({}, {});
    for my $i (@nucs) {
	for my $j (@nucs) {
	    for my $k (@nucs) {
		my $codon = "$i$j$k";
		$CODONS->{$codon} = $x;
		$TRCOL->{$x} = $codon;
		$x++;
	    }
	}
    }
    %IUPAC_DNA = Bio::Tools::IUPAC->iupac_iub();    
    %IUPAC_AA = Bio::Tools::IUPAC->iupac_iup();
    %THREELETTERSYMBOLS = Bio::SeqUtils->valid_aa(2);
    $VALID_PROTEIN = '['.join('',Bio::SeqUtils->valid_aa(0)).']';
    $TERMINATOR = '*';
}

sub new {
    my($class,@args) = @_;
    my $self = $class->SUPER::new(@args);

    my($id) =
	$self->_rearrange([qw(ID
			     )],
			 @args);

    $id = 1 if ( ! $id );
    $id  && $self->id($id);
    return $self; # success - we hope!
}

#line 299

sub id{
   my ($self,$value) = @_;
   if( defined $value) {
       if (  !(defined $TABLES[$value-1]) or $TABLES[$value-1] eq '') {
	   $self->warn("Not a valid codon table ID [$value] ");
	   $value = 0;
       }
       $self->{'id'} = $value;
   }
   return $self->{'id'};
}

#line 323

sub name{
   my ($self) = @_;

   my ($id) = $self->{'id'};
   return $NAMES[$id-1];
}

#line 360

sub translate {
    my ($self, $seq) = @_;
    $self->throw("Calling translate without a seq argument!") unless defined $seq;
    return '' unless $seq;

    my $id = $self->id;
    my ($partial) = 0;
    $partial = 2 if length($seq) % 3 == 2;
    
    $seq = lc $seq; 
    $seq =~ tr/u/t/;
    my $protein = "";
    if ($seq =~ /[^actg]/ ) { #ambiguous chars
        for (my $i = 0; $i < (length($seq) - 2 ); $i+=3) {
            my $triplet = substr($seq, $i, 3);
	    if (exists $CODONS->{$triplet}) {
		$protein .= substr($TABLES[$id-1], 
				   $CODONS->{$triplet},1);
	    } else {
		$protein .= $self->_translate_ambiguous_codon($triplet);
	    }
	}
    } else { # simple, strict translation
	for (my $i = 0; $i < (length($seq) - 2 ); $i+=3) {
            my $triplet = substr($seq, $i, 3); 
            if (exists $CODONS->{$triplet}) {
                $protein .= substr($TABLES[$id-1], $CODONS->{$triplet}, 1);
	    } else {
                $protein .= 'X';
            }
        }
    }
    if ($partial == 2) { # 2 overhanging nucleotides
	my $triplet = substr($seq, ($partial -4)). "n";
	if (exists $CODONS->{$triplet}) {
	    my $aa = substr($TABLES[$id-1], $CODONS->{$triplet},1);       
	    $protein .= $aa;
	} else {
	    $protein .= $self->_translate_ambiguous_codon($triplet, $partial);
	}
    }
    return $protein;
}

sub _translate_ambiguous_codon {
    my ($self, $triplet, $partial) = @_;
    $partial ||= 0;
    my $id = $self->id;
    my $aa;
    my @codons = _unambiquous_codons($triplet);
    my %aas =();
    foreach my $codon (@codons) {
	$aas{substr($TABLES[$id-1],$CODONS->{$codon},1)} = 1;
    }
    my $count = scalar keys %aas;
    if ( $count == 1 ) {
	$aa = (keys %aas)[0];
    }
    elsif ( $count == 2 ) {
	if ($aas{'D'} and $aas{'N'}) {
	    $aa = 'B';
	}
	elsif ($aas{'E'} and $aas{'Q'}) {
	    $aa = 'Z';
	} else {
	    $partial ? ($aa = '') : ($aa = 'X');
	}
    } else {
	$partial ? ($aa = '') :  ($aa = 'X');
    }
    return $aa;
}

#line 454

sub translate_strict{
   my ($self, $value) = @_;
   my ($id) = $self->{'id'};

   $value  = lc $value;
   $value  =~ tr/u/t/;

   if (length $value != 3 ) {
       return '';
   }
   elsif (!(defined $CODONS->{$value}))  {
       return 'X';
   }
   else {
       return substr($TABLES[$id-1],$CODONS->{$value},1);
   }
}

#line 494

sub revtranslate {
    my ($self, $value, $coding) = @_;
    my ($id) = $self->{'id'};
    my (@aas,  $p);
    my (@codons) = ();

    if (length($value) == 3 ) {
	$value = lc $value;
	$value = ucfirst $value;
	$value = $THREELETTERSYMBOLS{$value};
    }
    if ( defined $value and $value =~ /$VALID_PROTEIN/ 
	 and length($value) == 1 ) {
	$value = uc $value;
	@aas = @{$IUPAC_AA{$value}};	
	foreach my $aa (@aas) {
	    #print $aa, " -2\n";
	    $aa = '\*' if $aa eq '*';
	    while ($TABLES[$id-1] =~ m/$aa/g) {
		$p = pos $TABLES[$id-1];
		push (@codons, $TRCOL->{--$p});
	    }
	}
    }

    if ($coding and uc ($coding) eq 'RNA') {
	for my $i (0..$#codons)  {
	    $codons[$i] =~ tr/t/u/;
	}
    }

    return @codons;
}

#line 541

sub is_start_codon{
   my ($self, $value) = @_;
   my ($id) = $self->{'id'};

   $value  = lc $value;
   $value  =~ tr/u/t/;

   if (length $value != 3  )  {
       return 0;
   }
   else {
       my $result = 1;
       my @ms = map { substr($STARTS[$id-1],$CODONS->{$_},1) } _unambiquous_codons($value);
       foreach my $c (@ms) {
	   $result = 0 if $c ne 'M';
       }
       return $result;
   }
}



#line 576

sub is_ter_codon{
   my ($self, $value) = @_;
   my ($id) = $self->{'id'};

   $value  = lc $value;
   $value  =~ tr/u/t/;

   if (length $value != 3  )  {
       return 0;
   }
   else {
       my $result = 1;
       my @ms = map { substr($TABLES[$id-1],$CODONS->{$_},1) } _unambiquous_codons($value);
       foreach my $c (@ms) {
	   $result = 0 if $c ne $TERMINATOR;
       }
       return $result;
   }
}

#line 609

sub is_unknown_codon{
   my ($self, $value) = @_;
   my ($id) = $self->{'id'};

   $value  = lc $value;
   $value  =~ tr/u/t/;

   if (length $value != 3  )  {
       return 1;
   }
   else {
       my $result = 0;
       my @cs = map { substr($TABLES[$id-1],$CODONS->{$_},1) } _unambiquous_codons($value);
       $result = 1 if scalar @cs == 0;
       return $result;
   }
}

#line 638

sub _unambiquous_codons{
    my ($value) = @_;
    my @nts = ();
    my @codons = ();
    my ($i, $j, $k);
    @nts = map { $IUPAC_DNA{uc $_} }  split(//, $value);
    for my $i (@{$nts[0]}) {
	for my $j (@{$nts[1]}) {
	    for my $k (@{$nts[2]}) {
		push @codons, lc "$i$j$k";
	    }
	}
    }
    return @codons;
}

1;
