#line 1 "Bio/Tools/IUPAC.pm"
# $Id: IUPAC.pm,v 1.19 2002/11/30 15:39:53 jason Exp $
#
# BioPerl module for IUPAC
#
# Cared for by Aaron Mackey <amackey@virginia.edu>
#
# Copyright Aaron Mackey
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 127


# Let the code begin...

package Bio::Tools::IUPAC;

use strict;
use vars qw(@ISA %IUP %IUB $AUTOLOAD);

BEGIN {
    %IUB = ( A => [qw(A)],
	     C => [qw(C)],
	     G => [qw(G)],
	     T => [qw(T)],
	     U => [qw(U)],
	     M => [qw(A C)],
	     R => [qw(A G)],
	     W => [qw(A T)],
	     S => [qw(C G)],
	     Y => [qw(C T)],
	     K => [qw(G T)],
	     V => [qw(A C G)],
	     H => [qw(A C T)],
	     D => [qw(A G T)],
	     B => [qw(C G T)],
	     X => [qw(G A T C)],
	     N => [qw(G A T C)]
	     );

    %IUP = (A => [qw(A)],
	    B => [qw(D N)],
	    C => [qw(C)],
	    D => [qw(D)],
	    E => [qw(E)],
	    F => [qw(F)],
	    G => [qw(G)],
	    H => [qw(H)],
	    I => [qw(I)],
	    K => [qw(K)],
	    L => [qw(L)],
	    M => [qw(M)],
	    N => [qw(N)],
	    P => [qw(P)],
	    Q => [qw(Q)],
	    R => [qw(R)],
	    S => [qw(S)],
	    T => [qw(T)],
	    U => [qw(U)],
	    V => [qw(V)],
	    W => [qw(W)],
	    X => [qw(X)],
	    Y => [qw(Y)],
	    Z => [qw(E Q)],
	    '*' => ['*']
	    );
    
}
use Bio::Root::Root;
@ISA = qw(Bio::Root::Root);

#line 198


sub new {
    my($class,@args) = @_;
    my $self = $class->SUPER::new(@args);    

    my ($seq) = $self->_rearrange([qw(SEQ)],@args);
    if((! defined($seq)) && @args && ref($args[0])) {
	# parameter not passed as named parameter?
	$seq = $args[0];
    }
    $seq->isa('Bio::Seq') or 
	$self->throw("Must supply a Seq.pm object to IUPAC!");
    $self->{'_SeqObj'} = $seq;
    if ($self->{'_SeqObj'}->alphabet() =~ m/^[dr]na$/i ) { 
        # nucleotide seq object
	$self->{'_alpha'} = [ map { $IUB{uc($_)} } 
			      split('', $self->{'_SeqObj'}->seq()) ];
    } elsif ($self->{'_SeqObj'}->alphabet() =~ m/^protein$/i ) { 
        # amino acid seq object
	$self->{'_alpha'} = [ map { $IUP{uc($_)} } 
			      split('', $self->{'_SeqObj'}->seq()) ];
    } else { # unknown type: we could make a guess, but let's not.
	$self->throw("You must specify the 'type' of sequence provided to IUPAC");
    }
    $self->{'_string'} = [(0) x length($self->{'_SeqObj'}->seq())];
    scalar @{$self->{'_string'}} or $self->throw("Sequence has zero-length!");
    $self->{'_string'}->[0] = -1;
    return $self;
}

#line 239

sub next_seq{
    my ($self) = @_;

    for my $i ( 0 .. $#{$self->{'_string'}} ) {
	next unless $self->{'_string'}->[$i] || @{$self->{'_alpha'}->[$i]} > 1;
	if ( $self->{'_string'}->[$i] == $#{$self->{'_alpha'}->[$i]} ) { # rollover
	    if ( $i == $#{$self->{'_string'}} ) { # end of possibilities
		return undef;
	    } else {
		$self->{'_string'}->[$i] = 0;
		next;
	    }
	} else {
	    $self->{'_string'}->[$i]++;
	    my $j = -1;
	    $self->{'_SeqObj'}->seq(join('', map { $j++; $self->{'_alpha'}->[$j]->[$_]; } @{$self->{'_string'}}));
	    my $desc = $self->{'_SeqObj'}->desc();
	    if ( !defined $desc ) { $desc = ""; }

	    $self->{'_num'}++;
	    1 while $self->{'_num'} =~ s/(\d)(\d\d\d)(?!\d)/$1,$2/;
	    $desc =~ s/( \[Bio::Tools::IUPAC-generated\sunique sequence # [^\]]*\])|$/ \[Bio::Tools::IUPAC-generated unique sequence # $self->{'_num'}\]/;
	    $self->{'_SeqObj'}->desc($desc);
	    $self->{'_num'} =~ s/,//g;
	    return $self->{'_SeqObj'};
	}
    }
}

#line 278

sub iupac_iup{
   return %IUP;

}

#line 293

sub iupac_iub{
   return %IUB;
}

sub AUTOLOAD {

    my $self = shift @_;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return $self->{'_SeqObj'}->$method(@_)
	unless $method eq 'DESTROY';
}

1;

