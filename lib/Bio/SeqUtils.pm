#line 1 "Bio/SeqUtils.pm"
# $Id: SeqUtils.pm,v 1.11.2.1 2003/08/11 20:11:17 jason Exp $
#
# BioPerl module for Bio::SeqUtils
#
# Cared for by Heikki Lehvaslaiho <heikki@ebi.ac.uk>
#
# Copyright Heikki Lehvaslaiho
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 88


# Let the code begin...


package Bio::SeqUtils;
use vars qw(@ISA %ONECODE %THREECODE);
use strict;
use Carp;

@ISA = qw(Bio::Root::Root);
# new inherited from RootI

BEGIN {

    %ONECODE =
    ('Ala' => 'A', 'Asx' => 'B', 'Cys' => 'C', 'Asp' => 'D',
     'Glu' => 'E', 'Phe' => 'F', 'Gly' => 'G', 'His' => 'H',
     'Ile' => 'I', 'Lys' => 'K', 'Leu' => 'L', 'Met' => 'M',
     'Asn' => 'N', 'Pro' => 'P', 'Gln' => 'Q', 'Arg' => 'R',
     'Ser' => 'S', 'Thr' => 'T', 'Val' => 'V', 'Trp' => 'W',
     'Xaa' => 'X', 'Tyr' => 'Y', 'Glx' => 'Z', 'Ter' => '*',
     'Sec' => 'U'
     );

    %THREECODE =
    ('A' => 'Ala', 'B' => 'Asx', 'C' => 'Cys', 'D' => 'Asp',
     'E' => 'Glu', 'F' => 'Phe', 'G' => 'Gly', 'H' => 'His',
     'I' => 'Ile', 'K' => 'Lys', 'L' => 'Leu', 'M' => 'Met',
     'N' => 'Asn', 'P' => 'Pro', 'Q' => 'Gln', 'R' => 'Arg',
     'S' => 'Ser', 'T' => 'Thr', 'V' => 'Val', 'W' => 'Trp',
     'Y' => 'Tyr', 'Z' => 'Glx', 'X' => 'Xaa', '*' => 'Ter',
     'U' => 'Sec'
     );
}

#line 143

sub seq3 {
   my ($self, $seq, $stop, $sep ) = @_;

   $seq->isa('Bio::PrimarySeqI') ||
       $self->throw('Not a Bio::PrimarySeqI object but [$self]');
   $seq->alphabet eq 'protein' ||
       $self->throw('Not a protein sequence');

   if (defined $stop) {
       length $stop != 1 and $self->throw('One character stop needed, not [$stop]');
       $THREECODE{$stop} = "Ter";
   }
   $sep ||= '';

   my $aa3s;
   foreach my $aa  (split //, uc $seq->seq) {
       $THREECODE{$aa} and $aa3s .= $THREECODE{$aa}. $sep, next;
       $aa3s .= 'Xaa'. $sep;
   }
   $sep and substr($aa3s, -(length $sep), length $sep) = '' ;
   return $aa3s;
}

#line 186

sub seq3in {
   my ($self, $seq, $string, $stop, $unknown) = @_;

   $seq->isa('Bio::PrimarySeqI') ||
       $self->throw('Not a Bio::PrimarySeqI object but [$self]');
   $seq->alphabet eq 'protein' ||
       $self->throw('Not a protein sequence');

   if (defined $stop) {
       length $stop != 1 and $self->throw('One character stop needed, not [$stop]');
       $ONECODE{'Ter'} = $stop;
   }
   if (defined $unknown) {
       length $unknown != 1 and $self->throw('One character stop needed, not [$unknown]');
       $ONECODE{'Xaa'} = $unknown;
   }

   my ($aas, $aa3);
   my $length = (length $string) - 2;
   for (my $i = 0 ; $i < $length ; $i += 3)  {
       $aa3 = substr($string, $i, 3);
       $ONECODE{$aa3} and $aas .= $ONECODE{$aa3}, next;
       $aas .= 'X';
   }
   $seq->seq($aas);
   return $seq;
}

#line 226

sub translate_3frames {
    my ($self, $seq, @args ) = @_;
    
    $self->throw('Object [$seq] '. 'of class ['. ref($seq).  ']  can not be translated.')
	unless $seq->can('translate');

    my ($stop, $unknown, $frame, $tableid, $fullCDS, $throw) = @args;
    my @seqs;
    my $f = 0;
    while ($f != 3) {
        my $translation = $seq->translate($stop, $unknown,$f,$tableid, $fullCDS, $throw );
	$translation->id($seq->id. "-". $f. "F");
	push @seqs, $translation;
	$f++;
    }

    return @seqs;
}

#line 258

sub translate_6frames {
    my ($self, $seq, @args ) = @_;
    
    my @seqs = $self->translate_3frames($seq, @args);
    $seq->seq($seq->revcom->seq);
    my @seqs2 = $self->translate_3frames($seq, @args);
    foreach my $seq2 (@seqs2) {
	my ($tmp) = $seq2->id;
	$tmp =~ s/F$/R/g;
	$seq2->id($tmp);
    }
    return @seqs, @seqs2;
}


#line 287

sub valid_aa{
   my ($self,$code) = @_;

   if( ! $code ) { 
       my @codes;
       foreach my $c ( sort values %ONECODE ) {
	   push @codes, $c unless ( $c =~ /[BZX\*]/ );
       }
       push @codes, qw(B Z X *); # so they are in correct order ?
       return @codes;
  }
   elsif( $code == 1 ) { 
       my @codes;
       foreach my $c ( sort keys %ONECODE ) {
	   push @codes, $c unless ( $c =~ /(Asx|Glx|Xaa|Ter)/ );
       }
       push @codes, ('Asx', 'Glx', 'Xaa', 'Ter' );
       return @codes;
   }
   elsif( $code == 2 ) { 
       my %codes = %ONECODE;
       foreach my $c ( keys %ONECODE ) {
	   my $aa = $ONECODE{$c};
	   $codes{$aa} = $c;
       }
       return %codes;
   } else {
       $self->warn("unrecognized code in ".ref($self)." method valid_aa()");
       return ();
   }
}

1;
