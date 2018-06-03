#line 1 "Tk/Tree.pm"
# Tree -- TixTree widget
#
# Derived from Tree.tcl in Tix 4.1
#
# Chris Dean <ctdean@cogit.com> 

package Tk::Tree;

use Tk;
use Tk::VTree;
use strict;
use vars qw( @ISA $VERSION );
@ISA = qw( Tk::VTree );

$VERSION = "0.05";

Construct Tk::Widget 'Tree';

sub Tk::Widget::ScrlTree { shift->Scrolled('Tree' => @_) }

sub Populate {
    my( $w, $args ) = @_;

    $w->SUPER::Populate( $args );

    $w->configure( -highlightbackground => "#d9d9d9",
                   -background          => "#c3c3c3",
               qw/ -borderwidth         1       
                   -drawbranch          1
                   -height              10
                   -indicator           1
                   -indent              20
                   -itemtype            imagetext 
                   -padx                3
                   -pady                0
                   -relief              sunken
                   -takefocus           1
                   -wideselection       0
                   -width               20

                   -selectmode          single/ );

}

sub autosetmode {
    my( $w ) = @_;
    $w->SetModes();
}

sub close {
    my( $w, $ent ) = @_;

    my $mode = $w->GetMode( $ent );
    $w->Activate( $ent, $mode ) if( $mode eq "close" );
}

sub open {
    my( $w, $ent ) = @_;

    my $mode = $w->GetMode( $ent );
    $w->Activate( $ent, $mode ) if( $mode eq "open" );
}

sub getmode {
    my( $w, $ent ) = @_;
    return( $w->GetMode( $ent ) );
}

sub setmode {
    my( $w, $ent, $mode ) = @_;
    $w->SetMode( $ent, $mode );
}

sub SetModes {
    my( $w, $ent ) = @_;
    
    my @children;
    if( defined $ent ) {
        @children = $w->infoChildren( $ent );
    } else {
        @children = $w->infoChildren();
    }
 
    my $mode = "none";
    if( @children ) {
        $mode = "close";
        foreach my $c (@children) {
            $mode = "open" if $w->infoHidden( $c );
            $w->SetModes( $c );
	}
    }
    
    $w->SUPER::SetMode( $ent, $mode ) if defined $ent;
}

1;

__END__

#  Copyright (c) 1996, Expert Interface Technologies
#  See the file "license.terms" for information on usage and redistribution
#  of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#  
#  The file man.macros and some of the macros used by this file are
#  copyrighted: (c) 1990 The Regents of the University of California.
#               (c) 1994-1995 Sun Microsystems, Inc.
#  The license terms of the Tcl/Tk distrobution are in the file
#  license.tcl.

#line 416
