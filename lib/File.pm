#line 1 "File.pm"
sub file{
###################################File#############################################

#############################File-Load##############################################

sub fileload
{
#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: getopenfile.pl,v 1.1 2005/08/10 22:59:41 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Tk;
use Cwd;

#$top = new MainWindow;

print
    "Filename: ",
    $fileOpen=$main_window->getOpenFile(-defaultextension => ".pl",
		      -filetypes        =>
		      [['Perl Scripts',     '.pl'            ],
		       ['Text Files',       ['.txt', '.text']],
		       ['C Source Files',   '.c',      'TEXT'],
		       ['GIF Files',        '.gif',          ],
		       ['GIF Files',        '',        'GIFF'],
		       ['All Files',        '*',             ],
		      ],
		      -initialdir       => Cwd::cwd(),
		      -initialfile      => "getopenfile",
		      -title            => "Select the File",
		     ),
    "\n";

open (OPENFILE, "$fileOpen") || die "nahi mil raha hai";
while (<OPENFILE>)
{
$txt->insert('end',"$_");
}
close (OPENFILE);
#__END__
}


##############################################################################################



###############################Save##########################################################

sub filesave
{
#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: getopenfile.pl,v 1.1 2005/08/10 22:59:41 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#

use Tk;
use Cwd;

#$top = new MainWindow;

print
    "Filename: ",
    $fileSave1=$main_window->getSaveFile(-defaultextension => ".pl",
		      -filetypes        =>
		      [['Perl Scripts',     '.pl'            ],
		       ['Text Files',       ['.txt', '.text']],
		       ['C Source Files',   '.c',      'TEXT'],
		       ['GIF Files',        '.gif',          ],
		       ['GIF Files',        '',        'GIFF'],
		       ['All Files',        '*',             ],
		      ],
		      -initialdir       => Cwd::cwd(),
		      -initialfile      => "getSavefile",
		      -title            => "Save the File",
		     ),
    "\n";


  


open (FSAVE, "<abc.txt") || die " Sorry,Not Getting File.Try Again";
open (FSAVE, "$t") || die " Sorry,Not Getting File.Try Again";
open (FFSAVE, ">$fileSave1") || die "Sorry,Not Getting File.Try Again";
while (<FSAVE>)
{
print FFSAVE "$_";
}
Close(FSAVE);
close(FFSAVE);

#__END__


}

############################################################################################################
sub newpage
{
use Tk;

my $mw0;
$mw0=MainWindow->new;

$mw0->configure (-bg=>white);

$mw0->minsize (qw (500 200));

my $paste_text = $mw0->Scrolled('Text',-width => '40', -height => '20', -font => 'fixed',-scrollbars=>"oe",-cursor=>'ibeam',-width=>10,-height=>10,-background => "white",
                                       -foreground => "black") -> pack(-fill=>'both',-expand=>'yes');

}
###############################################################################################
sub print{
use Win32::Printer;

 my $dc = new Win32::Printer(
                                papersize       => A4,
                                dialog          => NOSELECTION,
                                description     => 'Hello, Mars!',
                                unit            => 'mm'
                            );

 my $font = $dc->Font('Arial Bold', 24);
 $dc->Font($font);
 $dc->Color(0, 0, 255);
 $dc->Write("Hello, Mars!", 10, 10);

 $dc->Brush(128, 0, 0);
 $dc->Pen(4, 0, 0, 128);
 $dc->Ellipse(10, 25, 50, 50);

 $dc->Close();}
}
1;