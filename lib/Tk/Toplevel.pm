#line 1 "Tk/Toplevel.pm"
# Copyright (c) 1995-2003 Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
package Tk::Toplevel;
use AutoLoader;

use vars qw($VERSION);
$VERSION = '4.006'; # $Id: //depot/Tkutf8/Tk/Toplevel.pm#6 $

use base  qw(Tk::Wm Tk::Frame);

Construct Tk::Widget 'Toplevel';

sub Tk_cmd { \&Tk::toplevel }

sub CreateOptions
{
 return (shift->SUPER::CreateOptions,'-screen','-use')
}

sub Populate
{
 my ($cw,$arg) = @_;
 $cw->SUPER::Populate($arg);
 $cw->ConfigSpecs('-title',['METHOD',undef,undef,$cw->class]);
}

sub Icon
{
 my ($top,%args) = @_;
 my $icon  = $top->iconwindow;
 my $state = $top->state;
 if ($state ne 'withdrawn')
  {
   $top->withdraw;
   $top->update;    # Let attributes propogate
  }
 unless (defined $icon)
  {
   $icon  = Tk::Toplevel->new($top,'-borderwidth' => 0,'-class'=>'Icon');
   $icon->withdraw;
   # Fake Populate
   my $lab  = $icon->Component('Label' => 'icon');
   $lab->pack('-expand'=>1,'-fill' => 'both');
   $icon->ConfigSpecs(DEFAULT => ['DESCENDANTS']);
   # Now do tail of InitObject
   $icon->ConfigDefault(\%args);
   # And configure that new would have done
   $top->iconwindow($icon);
   $top->update;
   $lab->DisableButtonEvents;
   $lab->update;
  }
 $top->iconimage($args{'-image'}) if (exists $args{'-image'});
 $icon->configure(%args);
 $icon->idletasks; # Let size request propogate
 $icon->geometry($icon->ReqWidth . 'x' . $icon->ReqHeight);
 $icon->update;    # Let attributes propogate
 $top->deiconify if ($state eq 'normal');
 $top->iconify   if ($state eq 'iconic');
}

sub menu
{
 my $w = shift;
 my $menu;
 $menu = $w->cget('-menu');
 unless (defined $menu)
  {
   $w->configure(-menu => ($menu = $w->SUPER::menu))
  }
 $menu->configure(@_) if @_;
 return $menu;
}


1;
__END__

#----------------------------------------------------------------------
#
#			Focus Group
#
# Focus groups are used to handle the user's focusing actions inside a
# toplevel.
#
# One example of using focus groups is: when the user focuses on an
# entry, the text in the entry is highlighted and the cursor is put to
# the end of the text. When the user changes focus to another widget,
# the text in the previously focused entry is validated.
#

#----------------------------------------------------------------------
# tkFocusGroup_Create --
#
#	Create a focus group. All the widgets in a focus group must be
#	within the same focus toplevel. Each toplevel can have only
#	one focus group, which is identified by the name of the
#	toplevel widget.
#
sub FG_Create {
    my $t = shift;
    unless (exists $t->{'_fg'}) {
	$t->{'_fg'} = 1;
	$t->bind('<FocusIn>', sub {
		     my $w = shift;
		     my $Ev = $w->XEvent;
		     $t->FG_In($w, $Ev->d);
		 }
		);
	$t->bind('<FocusOut>', sub {
		     my $w = shift;
		     my $Ev = $w->XEvent;
		     $t->FG_Out($w, $Ev->d);
		 }
		);
	$t->bind('<Destroy>', sub {
		     my $w = shift;
		     my $Ev = $w->XEvent;
		     $t->FG_Destroy($w);
		 }
		);
	# <Destroy> is not sufficient to break loops if never mapped.
	$t->OnDestroy([$t,'FG_Destroy']);
    }
}

# tkFocusGroup_BindIn --
#
# Add a widget into the "FocusIn" list of the focus group. The $cmd will be
# called when the widget is focused on by the user.
#
sub FG_BindIn {
    my($t, $w, $cmd) = @_;
    $t->Error("focus group \"$t\" doesn't exist") unless (exists $t->{'_fg'});
    $t->{'_FocusIn'}{$w} = Tk::Callback->new($cmd);
}

# tkFocusGroup_BindOut --
#
#	Add a widget into the "FocusOut" list of the focus group. The
#	$cmd will be called when the widget loses the focus (User
#	types Tab or click on another widget).
#
sub FG_BindOut {
    my($t, $w, $cmd) = @_;
    $t->Error("focus group \"$t\" doesn't exist") unless (exists $t->{'_fg'});
    $t->{'_FocusOut'}{$w} = Tk::Callback->new($cmd);
}

# tkFocusGroup_Destroy --
#
#	Cleans up when members of the focus group is deleted, or when the
#	toplevel itself gets deleted.
#
sub FG_Destroy {
    my($t, $w) = @_;
    if (!defined($w) || $t == $w) {
	delete $t->{'_fg'};
	delete $t->{'_focus'};
	delete $t->{'_FocusOut'};
	delete $t->{'_FocusIn'};
    } else {
	if (exists $t->{'_focus'}) {
	    delete $t->{'_focus'} if ($t->{'_focus'} == $w);
	}
	delete $t->{'_FocusIn'}{$w};
	delete $t->{'_FocusOut'}{$w};
    }
}

# tkFocusGroup_In --
#
#	Handles the <FocusIn> event. Calls the FocusIn command for the newly
#	focused widget in the focus group.
#
sub FG_In {
    my($t, $w, $detail) = @_;
    if (defined $t->{'_focus'} and $t->{'_focus'} eq $w) {
	# This is already in focus
	return;
    } else {
	$t->{'_focus'} = $w;
        $t->{'_FocusIn'}{$w}->Call if exists $t->{'_FocusIn'}{$w};
    }
}

# tkFocusGroup_Out --
#
#	Handles the <FocusOut> event. Checks if this is really a lose
#	focus event, not one generated by the mouse moving out of the
#	toplevel window.  Calls the FocusOut command for the widget
#	who loses its focus.
#
sub FG_Out {
    my($t, $w, $detail) = @_;
    if ($detail ne 'NotifyNonlinear' and $detail ne 'NotifyNonlinearVirtual') {
	# This is caused by mouse moving out of the window
	return;
    }
    unless (exists $t->{'_FocusOut'}{$w}) {
	return;
    } else {
	$t->{'_FocusOut'}{$w}->Call;
	delete $t->{'_focus'};
    }
}

1;

__END__
