#line 1 "Bio/Search/GenericDatabase.pm"
#-----------------------------------------------------------------
# $Id: GenericDatabase.pm,v 1.5 2002/10/22 07:38:38 lapp Exp $
#
# BioPerl module Bio::Search::GenericDatabase
#
# Cared for by Steve Chervitz <sac@bioperl.org>
#
# You may distribute this module under the same terms as perl itself
#-----------------------------------------------------------------

# POD documentation - main docs before the code

#line 71

#line 78

# Let the code begin...

package Bio::Search::GenericDatabase;

use strict;
use Bio::Search::DatabaseI;
use Bio::Root::Root;
use vars qw( @ISA );

@ISA = qw( Bio::Root::Root Bio::Search::DatabaseI);

sub new {
    my ($class, @args) = @_; 
    my $self = $class->SUPER::new(@args);
    my ($name, $date, $length, $ents) = 
        $self->_rearrange( [qw(NAME DATE LENGTH ENTRIES)], @args);

    $name    && $self->name($name);
    $date    && $self->date($date);
    $length  && $self->letters($length);
    $ents    && $self->entries($ents);

    return $self;
}

#line 111

#---------------
sub name {
#---------------
    my $self = shift;
    if(@_) { 
        my $name = shift;
        $name =~ s/(^\s+|\s+$)//g;
        $self->{'_db'} = $name;
    }
    $self->{'_db'};
}

#line 131

#-----------------------
sub date {
#-----------------------
    my $self = shift;
    if(@_) { $self->{'_dbDate'} = shift; }
    $self->{'_dbDate'};
}


#line 148

#----------------------
sub letters {
#----------------------
    my $self = shift;
    if(@_) { $self->{'_dbLetters'} = shift; }
    $self->{'_dbLetters'};
}


#line 165

#------------------
sub entries {
#------------------
    my $self = shift;
    if(@_) { $self->{'_dbEntries'} = shift; }
    $self->{'_dbEntries'};
}

1;
