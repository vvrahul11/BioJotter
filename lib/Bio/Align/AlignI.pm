#line 1 "Bio/Align/AlignI.pm"
# $Id: AlignI.pm,v 1.7 2002/10/22 07:45:10 lapp Exp $
#
# BioPerl module for Bio::Align::AlignI
#
# Cared for by Jason Stajich <jason@bioperl.org>
#
# Copyright Jason Stajich
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 79


# Let the code begin...


package Bio::Align::AlignI;
use vars qw(@ISA);
use strict;

use Bio::Root::RootI;

@ISA = qw(Bio::Root::RootI);

#line 110

sub add_seq {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 125

sub remove_seq {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 148

sub purge {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 167

sub sort_alphabetically {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 186

sub each_seq {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 206

sub each_alphabetically {
    my($self) = @_;
    $self->throw_not_implemented();
}

#line 226

sub each_seq_with_id {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 246

sub get_seq_by_pos {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 272

sub select {
    my ($self) = @_;
    $self->throw_not_implemented();
}


#line 293

sub select_noncont {
    my ($self) = @_;
    $self->throw_not_implemented();
}
    
#line 316

sub slice {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 346

sub map_chars {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 361

sub uppercase {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 378

sub match_line {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 403

sub match {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 421

sub unmatch {
    my ($self) = @_;
    $self->throw_not_implemented();
}


#line 445

sub id {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 462

sub missing_char {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 477

sub match_char {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 492

sub gap_char {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 507

sub symbol_chars{
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 531

sub consensus_string {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 558

sub consensus_iupac {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 578

sub is_flush {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 594

sub length {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 613

sub maxname_length {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 628

sub no_residues {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 643

sub no_sequences {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 659

sub percentage_identity{
    my ($self) = @_;
    $self->throw_not_implemeneted();
}

#line 675

sub overall_percentage_identity{
    my ($self) = @_;
    $self->throw_not_implemented();
}


#line 692

sub average_percentage_identity{
    my ($self) = @_;
    $self->throw_not_implemented();
}
    
#line 745

sub column_from_residue_number {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 768

sub displayname {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 787

sub set_displayname_count {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 803

sub set_displayname_flat {
    my ($self) = @_;
    $self->throw_not_implemented();
}

#line 818

sub set_displayname_normal {
    my ($self) = @_;
    $self->throw_not_implemented();
}

1;
