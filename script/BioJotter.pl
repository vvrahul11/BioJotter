use Tk;
use LWP::UserAgent;
use HTTP::Request::Common;
use Tk::Graph;
use Tk::NoteBook;
use Bio::AlignIO;
use Bio::SeqIO;

use Tk::widgets qw(
    Frame
    Text
    Label
);
require Tk::BrowseEntry;
use File::Find;



 {
    package Tk::_Extended_Text;
    
    @Tk::_Extended_Text::ISA = 'Tk::Text';

    Tk::Widget->Construct('_Extended_Text');
    
    my $i = 0;
    
    my @lastranges;
    
    # subroutine: &selectionChanged
    # 
    # argument:   LIST of 'sel' tag ranges
    # 
    # Return TRUE if the ROText selection
    # has changed.
    #
    # Several of the Tk::Text methods generate
    # a lot of noise even when there's no
    # change to the selection, use
    # &selectionChanged to discover if the
    # selection has actually been modified.
    #
    # Call &selectionChanged with the current
    # 'sel' tag range, if the return value is
    # TRUE, the selection was changed,
    # otherwise no change.
    
    sub selectionChanged {
        my @ranges = @_;

        if (@ranges != @lastranges) {
            return 1;
        }

        # each array has same number of elements
        for (my $i = 0; $i < @ranges; $i++) {
            if ($ranges[$i] ne $lastranges[$i]) {
                return 1;
            }
        }
        
        return;
    }


    # override Tk::Text methods:
    # -----------------------------------------------
    # These overrides are simple wrappers that
    # provide a hook for generation of the
    # <<Selection>> event.
    
    sub selectAll {
        my $w = shift;
        $w->SUPER::selectAll(@_);
        $w->eventGenerate('<<Selection>>');
        @lastranges = $w->tagRanges('sel');
        return;
    }

    
    sub unselectAll {
        my $w = shift;
        $w->SUPER::unselectAll(@_);
        if (selectionChanged($w->tagRanges('sel'))) {
            $w->eventGenerate('<<Selection>>');
        }
        @lastranges = $w->tagRanges('sel');
        return;
    }

    
    sub SelectTo {
        my $w = shift;
        $w->SUPER::SelectTo(@_);
        if (selectionChanged($w->tagRanges('sel'))) {
            $w->eventGenerate('<<Selection>>');
        }
        @lastranges = $w->tagRanges('sel');
        return;
    }

    
    sub KeySelect {
        my $w = shift;
        $w->SUPER::KeySelect(@_);
        $w->eventGenerate('<<Selection>>');
        @lastranges = $w->tagRanges('sel');
        return;
    }


    sub FindAll {
        my $w = shift;
        $w->SUPER::FindAll(@_);
        if (selectionChanged($w->tagRanges('sel'))) {
            $w->eventGenerate('<<Selection>>');
        }
        @lastranges = $w->tagRanges('sel');
        return;
     }


    sub FindNext {
        my $w = shift;
        $w->SUPER::FindNext(@_);
        if (selectionChanged($w->tagRanges('sel'))) {
            $w->eventGenerate('<<Selection>>');
        }
        @lastranges = $w->tagRanges('sel');
        return;
     }
}












########################################################################
my $main_window;
$main_window=MainWindow->new;
$main_window->title("Biojotter");

$main_window->configure (-bg=>white);

$main_window->minsize (qw (700 400));


my $menubar=$main_window->Frame (-relief=>'groove',-borderwidth=>2) ->pack (-side=>'top',-fill=>'x');

my $statbar = $main_window->Frame(
    -relief => 'sunken',
)->pack(
    -fill   => 'x',
    -side   => 'bottom',
);
my $selview = $statbar->Label->pack;




my $file=$menubar->Menubutton (-text=>'File',-foreground=>black,) ->pack (-side=>'left');
my $main;
$file->command (-label=>'New',-accelerator=>'ctrl+N',-command=>[\&newpage, 'New']);


$file->command (-label=>'Open',-accelerator=>'ctrl+O',-command=>[\&fileload, 'Open']);
$file->command (-label=>'Save',-accelerator=>'ctrl+S',-command=>[\&filesave, 'Save']);
$file->command (-label=>'Save as',-command=>sub {$main->destroy});
$file->separator();
$file->command (-label=>'Print',-accelerator=>'ctrl+P',-command=>[\&print, 'print']);
$file->command (-label=>"Exit",-command=> [\&exitprogram,'Exit']);
$file->command (-label=>"FileShow",-command=> [\&FileShow,'FileShow']);
$file->separator();

$file=$menubar->Menubutton (-text=>'Edit',-foreground=>black,) ->pack (-side=>'left');

$file->command (-label=>'Cut',-accelerator=>'ctrl+X',-command=>[\&cut, 'cut']);
$file->command (-label=>'Copy',-accelerator=>'ctrl+C',-command=>[\&copy, 'copy']);
$file->command (-label=>'Paste',-accelerator=>'ctrl+V',-command=>[\&paste, 'paste']);
$file->command (-label=>'Delete',-command=>[\&delete, 'delete']);
$file->command (-label=>'Delete All',-command=>[\&DeleteAll, 'Delete All']);
$file->separator();
$file->command (-label=>'Find',-accelerator=>'ctrl+F',-command=>[\&findandreplace, 'findandreplace']);
$file->command (-label=>'Replace',-accelerator=>'ctrl+H',-command=>[\&findandreplace, 'findandreplace']);
$file->command (-label=>'Select All',-accelerator=>'ctrl+A',-command=>[\&selectall, 'selectall']);
$file->separator();
$file->command (-label=>'Time',-accelerator=>'F5',-command=>[\&times,'Exit']);
$file->command (-label=>'Date',-command=>sub {$main->destroy});
$file->command (-label=>'GoTo',-command=>[\&goto,'goto']);
##$file->command (-label=>'Clean',-command=>[\&clean,'clean']);

$file=$menubar->Menubutton (-text=>'Format',-foreground=>black,)->pack(-side=>'left');
my $font_size;
$file->checkbutton(-label=>'Font',-command=>sub {$font_size=font_size()});
my $font_colour;
my $colorall=$file->cascade (-label=>'Color');

my $area=$colorall-> cascade(-label =>'Text Area');
$area-> command(-label =>'Black',-command=>[\&black, 'black']);
$area-> command(-label =>'Skyblue',-command=>[\&skyblue, 'skyblue']);
$area-> command(-label =>'Pink',-command=>[\&pink, 'pink']);
$area-> command(-label =>'Grey',-command=>[\&grey, 'grey']);
$area-> command(-label =>'Brown',-command=>[\&brown, 'brown']);
$area-> command(-label =>'White',-command=>[\&white, 'white']);

$colorall-> command(-label =>'Color All',-command => sub { $font_colour = colour_picker() });
$colorall-> command(-label =>'DNA / RNA /Protein',-command=>[\&pickcolor, 'pickcolor']);


if ($font_colour) {
  $txt->configure( -foreground => $font_colour, -activeforeground => $font_colour );
}


$file->command (-label=>'exit',-command=>sub {$main->destroy});

$file=$menubar->Menubutton (-text=>'Window',-foreground=>black,)->pack(-side=>'left');


$file->command (-label=>'Rough',-command=>[\&Rough,'Rough']);
$file->command (-label=>'Select And Rough',-command=>[\&selectandrough,'selectandrough']);
$file->separator(); 
#$file->command (-label=>'Split Window',-command=>[\&splitwindow]);
#$file->command (-label=>'StatusBar', -accelerator => 'Ctrl+G',-command=>[\&StatusBar]);
$file->command (-label=>'Blast',-command=>[\&blast_n, 'blast_n']);
$file->command (-label=>'genscan',-command=>[\&genscan, 'genscan']);
$file->command (-label=>'Rasmol',-command=>[\&rasmol, 'rasmol']);


$file=$menubar->Menubutton (-text=>'SeqExplore',-foreground=>black)->pack(-side=>'left');
#$file->command (-label=>'Import',-command=>sub {$main->destroy});
#$file->command (-label=>'Export',-command=>sub {$main->destroy});
#$file->separator();
my $comp=$file->cascade (-label=>'Composition');
$comp->command(-label=>'DNA/RNA',-command=>[\&Dpercentage, 'Dpercentage']);
$comp->command (-label=>'Protein',-command=>[\&Ppercentage, 'Ppercentage']);

my $insert = $file -> cascade(-label =>'Translate');

$insert->command(-label=>"DNA to RNA",-command=>[\&translate_RNA, 'translate_RNA']);

$insert->command(-label=>"DNA to protein",-command=>[\&translate_protein, 'translate_protein']);

$file->separator();
$file->command (-label=>'Length',-command=>[\&length, 'length']);
$file->command (-label=>'Reverse',-command=>[\&reverse, 'reverse']);
$file -> command(-label =>'orf region', -command =>[\&orf, 'orf']);
$file -> command(-label =>'Translated ORF', -command =>[\&torf, 'torf']);
my $grap=$file->cascade (-label=>'Graph');
$grap->command(-label=>'DNA/RNA',-command=>[\&graphd, 'Dpercentage']);
$grap->command (-label=>'Protein',-command=>[\&graphp, 'Ppercentage']);
$file->separator();
$file->command (-label=>'Finder',-command=>sub {$main->destroy});

$file->command (-label=>'InsertGap',-command=>[\&insert, 'insert']);





$file=$menubar->Menubutton (-text=>'FormatConverter',-foreground=>black,)->pack(-side=>'left');
$file->command (-label=>'EMBL->Fasta',-command=>[\&embltofastawin, 'embltofastawin']);
$file->command (-label=>'Clustalw-.FASTA',-command=>[\&clustalwtofasta, 'fastagenbank']);
$file->command (-label=>'Clustalw->pfam',-command=>[\&cwtopfam, 'cwtopfam']);
$file->command (-label=>'GenBank->FASTA',-command=>[\&genbanktofasta, 'genbanktofasta']);



$file=$menubar->Menubutton (-text=>'Online Tools',-foreground=>black)->pack(-side=>'left');
$file->command (-label=>'Microarray Analysis',-command=>[\&microarray, 'Web Browser']);
$file->separator();
$file->command (-label=>'Webcutter',-command=>[\&webcutter, 'Manual']);
$file->command (-label=>'Primer detection',-command=>[\&Primer_Dection, 'Manual']);
$file->command (-label=>'Swiss Model',-command=>[\&swissmodel, 'Manual']);
$file->command (-label=>'Genscan',-command=>[\&Genscan, 'Manual']);
$file->separator();
$file->command (-label=>'Tf Sitesscan',-command=>[\&Tfsitescan, 'Manual']);
$file->command (-label=>'Reverse Translate',-command=>[\&Reverse_Translate, 'Manual']);
$file->command (-label=>'tmhmm',-command=>[\&tm, 'Manual']);
$file->separator();
$file->command (-label=>'confunc',-command=>[\&confunc, 'Manual']);
$file->command (-label=>'3dpssm',-command=>[\&dpssm, 'Manual']);

$file->command (-label=>'I-Tasser',-command=>[\&itasser, 'Manual']);
$file->command (-label=>'Autoriksha',-command=>[\&autoriksha, 'Manual']);
$file->command (-label=>'PS2',-command=>[\&ps2, 'Manual']);






$file=$menubar->Menubutton (-text=>'WWW',-foreground=>black,)->pack(-side=>'left');
$file->command (-label=>'Web Browser',-command=>[\&webbrowser, 'Manual']);
$file->separator();
$file->command (-label=>'Prosite',-command=>[\&prosite, 'Manual']);
$file->command (-label=>'ExPASy',-command=>[\&expasy, 'Manual']);
$file->command (-label=>'PHYLIP',-command=>[\&phylip, 'Manual']);
$file->command (-label=>'PubMed',-command=>[\&pubmed, 'Manual']);
$file->command (-label=>'molecular station',-command=>[\&molecular_station, 'Manual']);
$file->command (-label=>'KEGG',-command=>[\&kegg, 'Manual']);
$file->separator();
$file->command (-label=>'DDBJ',-command=>[\&ddbj, 'Manual']);
$file->command (-label=>'EMBL',-command=>[\&memble, 'Manual']);
$file->command (-label=>'NCBI',-command=>[\&ncbiii, 'Manual']);

$file->separator();
$file->command (-label=>'BLAST',-command=>[\&mblaste, 'Manual']);
$file->command (-label=>'FastA',-command=>[\&fastaaa, 'Manual']);
$file->command (-label=>'ClustaW',-command=>[\&clustalw, 'Manual']);
$file->command (-label=>'PDB',-command=>[\&pdb, 'Manual']);
$file->separator();
$file->command (-label=>'SwissProt',-command=>[\&swissprot, 'Manual']);
$file->command (-label=>'GeneCards',-command=>[\&genecards, 'Manual']);
$file->command (-label=>'Dotplot',-command=>[\&dotplot, 'Manual']);

$file=$menubar->Menubutton (-text=>'Help',-foreground=>black)->pack(-side=>'left');
$file->command (-label=>'About',-command=>[\&about, 'about']);
my $grapo=$file->cascade (-label=>'Demo');
$grapo->command(-label=>'DNA',-command=>[\&demodna, 'demodna']);
$grapo->command (-label=>'Protein',-command=>[\&demoprtn, 'demoprtn']);


$main_window->bind("all", "<Control-n>" => \&newpage);  
$main_window->bind("all", "<Control-N>" => \&newpage);          
$main_window->bind("all", "<Control-a>" => \&selectall); 
$main_window->bind("all", "<Control-A>" => \&selectall);  
$main_window->bind("all", "<Control-o>" => \&fileload);
$main_window->bind("all", "<Control-O>" => \&fileload);
$main_window->bind("all", "<Control-s>" => \&filesave); 
$main_window->bind("all", "<Control-S>" => \&filesave); 
$main_window->bind("all", "<Control-p>" => \&print);
$main_window->bind("all", "<Control-P>" => \&print);
$main_window->bind("all", "<Control-c>" => \&copy);  
$main_window->bind("all", "<Control-C>" => \&copy);   
$main_window->bind("all", "<Control-x>" => \&cut); 
$main_window->bind("all", "<Control-x>" => \&cut);   
$main_window->bind("all", "<Control-v>" => \&paste);
$main_window->bind("all", "<Control-V>" => \&paste);    
  
$main_window->bind("all", "<Control-F5>" => \&times);    
$main_window->bind("all", "<Control-h>" => \&replace); 
$main_window->bind("all", "<Control-d>" => \&DeleteAll);    
$main_window->bind("all", "<Control-f>" => \&findandreplace);  
$main_window->bind("all", "<Control-h>" => \&findandreplace);
$main_window->bind("all", "<Control-F5>" => \&times);    
$main_window->bind("all", "<Control-H>" => \&replace); 
$main_window->bind("all", "<Control-D>" => \&DeleteAll);    
$main_window->bind("all", "<Control-F>" => \&findandreplace);  
$main_window->bind("all", "<Control-H>" => \&findandreplace);           
   
    
 




################################################################################################################
### allocate an extended Tk::Text widget object:
##
my $txt = $main_window->Scrolled(_Extended_Text,-scrollbars=>"oe", -selectbackground =>pink,-selectforeground =>red,-selectborderwidth =>1,-font=>red)->pack(-fill=>'both',-expand =>'yes');



my $i = 0;

$txt->bind(
    '<<Selection>>',
    sub {
        print "<<Selection>> event $i";
        $i++;
        my @r = $txt->tagRanges('sel');
        if (@r) {
            my $len = length $txt->get(@r);
           $selview->configure(-text => "+  Length $len      :begin $r[0]  :  end $r[1]  ");
        }
        else {
            $selview->configure(-text => 'no selection');
        }
    },
);

$main_window->bind('<Control-q>', sub { $main_window->destroy });

$selview->configure(-text => 'Ctrl-q to exit.');


$main_window->after(
    2500,
    sub {
        $selview->configure(
            -text => 'Select text with mouse or keyboard.',
        );
    },
);


$txt->focus;





MainLoop ();






#######################################################################################

sub exitprogram {
 	
	my $response=$main_window->messageBox(-message=>"Do you want to close this window ?", -type=>'yesno',-icon=>'question');
	
if ($response eq 'Yes')
		{
		exit();
		}
	else
		{
		$main_window->messageBox(-type=>"ok", -message=>"I know you like this application! :)");
		}

}

#######################################################################################

###################################File#############################################
sub FileShow
{
#!/usr/bin/perl -w
# -*- perl -*-

#
# $Id: fileselectdir.pl,v 1.1 2005/08/10 22:59:41 eserte Exp $
# Author: Slaven Rezic
#
# Copyright (C) 2000 Slaven Rezic. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: eserte@cs.tu-berlin.de
# WWW:  http://user.cs.tu-berlin.de/~eserte/
#


use Tk::FileSelect;
use Cwd;

$top = new MainWindow;

$fs = $top->FileSelect(-verify => [qw/-d/]);
print $fs->Show;
print "\n";


}
###########################newpage################################################
sub newpage{

my $rrresponse=$main_window->messageBox(-message=>"Welcome to BioJotter,This option is not included in this version");}
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




###############################################################################################
###place for menu


##############################WWW#####################################################################

##################################World Wide Web #####################################################

#######################################################################################################

###################################Web Browser#########################################################

###################################Prosite#########################################################
sub prosite
{
use Win32::WebBrowser;
        
        open_browser('http://www.expasy.ch/prosite/' );
}

########################################################################################################

###################################Expasy#########################################################
sub expasy
{
use Win32::WebBrowser;
        
        open_browser( ' http://www.expasy.ch/');
}

########################################################################################################

###################################phylip#########################################################
sub phylip
{
use Win32::WebBrowser;
        
        open_browser('http://evolution.genetics.washington.edu/phylip.html' );
}

########################################################################################################

###################################PubMed#########################################################
sub pubmed
{
use Win32::WebBrowser;
        
        open_browser('http://www.ncbi.nlm.nih.gov/pubmed/' );
}

########################################################################################################

###################################DDBJ#########################################################

sub ddbj
{
use Win32::WebBrowser;
        
      open_browser('http://www.ddbj.nig.ac.jp/' );

}
########################################################################################################

###################################EMBL#########################################################
sub memble
{
use Win32::WebBrowser;
        
        open_browser('http://www.ebi.ac.uk/embl/' );
}

########################################################################################################

###################################NCBI#########################################################
sub ncbiii
{
use Win32::WebBrowser;
        
        open_browser('http://www.ncbi.nlm.nih.gov/' );
}

########################################################################################################

###################################
#########################################################
sub mblaste
{
use Win32::WebBrowser;
        
        open_browser('http://blast.ncbi.nlm.nih.gov/Blast.cgi' );
}

########################################################################################################

###################################FastA#########################################################
sub fastaaa
{
use Win32::WebBrowser;
        
       open_browser('http://www.ebi.ac.uk/Tools/fasta33/index.html' );
}

########################################################################################################

########################################################################################################

###################################ClustalW#########################################################
sub clustalw
{
use Win32::WebBrowser;
        
        open_browser('http://www.ebi.ac.uk/Tools/clustalw2/index.html' );
}

########################################################################################################

###################################PDB#########################################################
sub pdb
{
use Win32::WebBrowser;
        
        open_browser('http://www.rcsb.org/pdb/home/home.do' );
}

########################################################################################################

###################################SwissProt#########################################################
sub swissprot
{
use Win32::WebBrowser;
        
        open_browser('http://www.expasy.ch/sprot/' );
}

###################################molecular stations#########################################################
sub molecular_station
{
use Win32::WebBrowser;
        
        open_browser('http://www.molecularstation.com/bioinformatics/link/' );
}


################################transcriptome#######################
sub microarray
{
use win32::webBrowser;
   open_browser('http://molbiol-tools.ca/Transcriptome.htm');
}

##################################webcutter#########################
sub webcutter
{
use win32::webBrowser;
  open_browser('http://www.firstmarket.com/cutter/cut2.html');
}

##################################Genscsan##########################
sub Genscan
{
use win32::webBrowser;
    open_browser('http://genes.mit.edu/GENSCAN.html');
}

###################################Primer Detection####################################
sub Primer_Dection
{
use win32::webBrowser;
  open_browser('http://biotools.umassmed.edu/bioapps/primer3_www.c');
}

#################################Reverse Translate###################################
sub Reverse_Translate
{
use win32::webBrowser;
  open_browser('http://www.bioinformatics.org/sms2/rev_trans.html');
}

##############################Tfsitescan#############################################
sub Tfsitescan
{
use win32::webBrowser;
    open_browser('http://www.ifti.org/cgi-bin/ifti/Tfsitescan.pl');
}

###############################SwissModel#############################################
sub swissmodel
{
use win32::webBrowser;
     open_browser('http://swissmodel.expasy.org/');
}

#################################CONFUNC################################################

sub confunc
{
use win32::webBrowser;
     open_browser('www.sbg.bio.ic.ac.uk/confunc');
}

###################################Web Browser#########################################################

sub webbrowser
{
use Win32::WebBrowser;
        
        open_browser( 'www.google.com');
}
########################################################################################################


#################################3dpssm################################################

sub dpssm
{
use win32::webBrowser;
open_browser('http://www.sbg.bio.ic.ac.uk/~3dpssm/index2.html');
}

#################################TMHMM################################################

sub tm
{
use win32::webBrowser;
    open_browser('http://www.cbs.dtu.dk/services/TMHMM/');
}

###################################################################################################################
sub itasser
{
use win32::webBrowser;
    open_browser('http://zhanglab.ccmb.med.umich.edu/I-TASSER/');
}
####################################################################################################
sub ps2
{
use win32::webBrowser;
    open_browser('http://ps2.life.nctu.edu.tw/');
}
####################################################################################################
sub autoriksha
{
use win32::webBrowser;
    open_browser('http://webapps.embl-hamburg.de/lresult/S_v0N63wY/LOG/viewlog/result.html');
}
####################################################################################################

  sub splitwindow
  {

 my $txt = $main_window -> Scrolled('Text',-scrollbars=>"oe",-cursor=>'ibeam',-width=>100,-height=>25) -> pack(-fill=>'both',-expand=>'yes');


}
###################################################################################################

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


###############################################################################################
 sub delete
{

 $txt->deleteSelected();

}
################################################################################################
  sub DeleteAll
  {

  $txt->delete('0.0', 'end');
   


}
################################################################################################
  sub selectall
  {

  $txt->selectAll;

 #$txt->unselectAll;
 

}
################################################################################################
 sub copy
{

my $s2 = $txt->getSelected( ); 

}
################################################################################################
sub cut
{
 $sc = $txt->getSelected( ); 
 $txt->deleteSelected( );
 
}
################################################################################################
sub paste
{

$txt->insert('insert', $sc);
}
####################################################################################################


sub length
  {

my $copied_tex = $txt->get('0.0','end');
chomp ($copied_tex);
 
use Tk;

 
my $mw5;
$mw5=MainWindow->new;

$mw5->configure (-bg=>white);

$mw5->minsize (qw (500 200));


my $paste_text = $mw5->Scrolled('Text',-width => '40', -height => '20', -font => 'fixed',-scrollbars=>"oe",-cursor=>'ibeam',-width=>10,-height=>10,-background => "white",
                                       -foreground => "black") -> pack(-fill=>'both',-expand=>'yes');

$paste_text -> insert('end',length($copied_tex));
}


####################################################################################################
sub reverse
  {

my $copied_tex = $txt->get('0.0','end');
chomp ($copied_tex);
 my $rev=reverse($copied_tex);
use Tk;

 
my $mw6;
$mw6=MainWindow->new;

$mw6->configure (-bg=>white);

$mw6->minsize (qw (500 200));


my $paste_text = $mw6->Scrolled('Text',-width => '40', -height => '20', -font => 'fixed',-scrollbars=>"oe",-cursor=>'ibeam',-background => "white",
                                       -foreground => "black") -> pack(-fill=>'both',-expand=>'yes');

$paste_text -> insert('end',$rev);
}


####################################################################################################

sub Rough
  {

my $copied_tex = $txt->get('0.0','end');
 chomp ($copied_tex);
use Tk;

 
my $mw7;
$mw7=MainWindow->new;

$mw7->configure (-bg=>white);

$mw7->minsize (qw (500 200));


my $paste_text = $mw7->Scrolled('Text',-width => '40', -height => '20', -font => 'fixed',-scrollbars=>"oe",-cursor=>'ibeam',-background => "white",
                                       -foreground => "black") -> pack(-fill=>'both',-expand=>'yes');

$paste_text -> insert('end',$copied_tex);

}



####################################################################################################

sub colour_picker {
   
  my $colour = $txt->chooseColor( -title => 'Color Picker', -initialcolor => '#000000' );

  $txt->configure( -foreground => $colour, -activeforeground => $colour );
  return $colour;

}



#################################composition DNA###################################################################


sub Dpercentage {



my $copied_tex = $txt->get('0.0','end');
chomp ($copied_tex);

$d=length($copied_tex);
chomp($d);

@copied_tex=split('',$copied_tex);


$a=$g=$c=$t=$u=$f=0;
for($i=0;$i<$d;$i++)
{

if(
($copied_tex[$i] eq '~') ||($copied_tex[$i] eq '`')||($copied_tex[$i] eq '1')||($copied_tex[$i] eq '2')||($copied_tex[$i] eq '3')||($copied_tex[$i] eq '4')||($copied_tex[$i] eq '5')||($copied_tex[$i] eq '6')||($copied_tex[$i] eq '7')||($copied_tex[$i] eq '8')||($copied_tex[$i] eq '9')||($copied_tex[$i] eq '!')||($copied_tex[$i] eq '@')||($copied_tex[$i] eq '#')||($copied_tex[$i] eq '$')||($copied_tex[$i] eq '%')||($copied_tex[$i] eq '^')||($copied_tex[$i] eq '&')||($copied_tex[$i] eq '*')||($copied_tex[$i] eq '(')||($copied_tex[$i] eq ')')||($copied_tex[$i] eq '_')||($copied_tex[$i] eq '-')||($copied_tex[$i] eq '+')||($copied_tex[$i] eq '=')||($copied_tex[$i] eq '}')||($copied_tex[$i] eq '{')||($copied_tex[$i] eq '[')||($copied_tex[$i] eq ']')||($copied_tex[$i] eq '.')||($copied_tex[$i] eq '%')||($copied_tex[$i] eq '/')||($copied_tex[$i] eq '&')||($copied_tex[$i] eq '*')||($copied_tex[$i] eq ',')||($copied_tex[$i] eq '.')||($copied_tex[$i] eq '/')||($copied_tex[$i] eq '<')||($copied_tex[$i] eq '>')||($copied_tex[$i] eq ';')||($copied_tex[$i] eq 'B')||($copied_tex[$i] eq 'D')||($copied_tex[$i] eq 'E')||($copied_tex[$i] eq 'F')||($copied_tex[$i] eq 'H')||($copied_tex[$i] eq 'I')||($copied_tex[$i] eq 'J')||($copied_tex[$i] eq 'K')||($copied_tex[$i] eq 'L')||($copied_tex[$i] eq 'M')||($copied_tex[$i] eq 'N')||($copied_tex[$i] eq 'O')||($copied_tex[$i] eq 'P')||($copied_tex[$i] eq 'Q')||($copied_tex[$i] eq 'R')||($copied_tex[$i] eq 'S')||($copied_tex[$i] eq 'V')||($copied_tex[$i] eq 'W')||($copied_tex[$i] eq 'X')||($copied_tex[$i] eq 'Y')||($copied_tex[$i] eq 'Z')||($copied_tex[$i] eq 'b')||($copied_tex[$i] eq 'd')||($copied_tex[$i] eq 'e')||($copied_tex[$i] eq 'f')||($copied_tex[$i] eq 'h')||($copied_tex[$i] eq 'i')||($copied_tex[$i] eq 'j')||($copied_tex[$i] eq 'k')||($copied_tex[$i] eq 'l')||($copied_tex[$i] eq 'm')||($copied_tex[$i] eq 'n')||($copied_tex[$i] eq 'o')||($copied_tex[$i] eq 'p')||($copied_tex[$i] eq 'q')||($copied_tex[$i] eq 'r')||($copied_tex[$i] eq 's')||($copied_tex[$i] eq 'v')||($copied_tex[$i] eq 'w')||($copied_tex[$i] eq 'x')||($copied_tex[$i] eq 'y')||($copied_tex[$i] eq 'z'))
{
my $msgbox=$main_window->messageBox(-message=>" There is some error in the sequence", -type=>'ok');
$f=1;
last;
}
}

if($f==0){
for($i=0;$i<$d;$i++)
{

if(($copied_tex[$i] eq 'A') ||($copied_tex[$i] eq 'a'))
{
$a=$a+1;
}
elsif(($copied_tex[$i] eq 'G') ||($copied_tex[$i] eq 'g'))
{

$g=$g+1;
}
elsif(($copied_tex[$i] eq 'C') ||($copied_tex[$i] eq 'c'))

{

$c=$c+1;
}
elsif(($copied_tex[$i] eq 'T') ||($copied_tex[$i] eq 't'))
{
$t=$t+1;
}
elsif(($copied_tex[$i] eq 'U') ||($copied_tex[$i] eq 'u'))
{
$u=$u+1;
}

}

$total=$a+$g+$t+$c+$u;

if ($t eq 0)
{
  $v=0;
}
else
{
$v=$a+$t;
}
$q=$g+$c;

$GC=($q/$total)*100;
$AT=($v/$total)*100;

my $mwg = MainWindow->new;
$mwg->geometry( "900x600" );

   my $data = {
        'A%'   =>$a,'G%'  => $g,'C%'   => $c,'T%'    => $t,'U%'   => $u,'GC%'   => $GC,'AT%'  => $AT};

   my $ca = $mwg->Graph(
                -type  => 'Bars',
        )->pack(
                -expand => 1,
                -fill => 'both',
        );

$ca->configure(-variable => $data);     # bind to data

   # or ...   

   $ca->set($data);        # set data

 

my $msgbox=$main_window->messageBox(-message=>" The GC% of the given nucleotide sequence is $GC\n The AT% of the given nucleotide sequence is $AT ", -type=>'ok');
}
}
 

##############################composition protein####################################################################
sub Ppercentage {
  
my $copied_tex = $txt->get('0.0','end');
chomp ($copied_tex);

$dd=length($copied_tex);


@copied_tex=split('',$copied_tex);


  $a= $c= $d= $e= $f= $g= $h= $i=$j= $k= $l= $m= $n= $o= $p= $q= $r= $s= $t= $u= $v= $w= $y=$ff=0;


for($z=0;$z<$dd;$z++)
{

if(
($copied_tex[$z] eq '~') ||($copied_tex[$z] eq '`')||($copied_tex[$z] eq '1')||($copied_tex[$z] eq '2')||($copied_tex[$z] eq '3')||($copied_tex[$z] eq '4')||($copied_tex[$z] eq '5')||($copied_tex[$z] eq '6')||($copied_tex[$z] eq '7')||($copied_tex[$z] eq '8')||($copied_tex[$z] eq '9')||($copied_tex[$z] eq '!')||($copied_tex[$z] eq '@')||($copied_tex[$z] eq '#')||($copied_tex[$z] eq '$')||($copied_tex[$z] eq '%')||($copied_tex[$z] eq '^')||($copied_tex[$z] eq '&')||($copied_tex[$z] eq '*')||($copied_tex[$z] eq '(')||($copied_tex[$z] eq ')')||($copied_tex[$z] eq '_')||($copied_tex[$z] eq '-')||($copied_tex[$z] eq '+')||($copied_tex[$z] eq '=')||($copied_tex[$z] eq '}')||($copied_tex[$z] eq '{')||($copied_tex[$z] eq '[')||($copied_tex[$z] eq ']')||($copied_tex[$z] eq '.')||($copied_tex[$z] eq '%')||($copied_tex[$z] eq '/')||($copied_tex[$z] eq '&')||($copied_tex[$z] eq '*')||($copied_tex[$z] eq ',')||($copied_tex[$z] eq '.')||($copied_tex[$z] eq '/')||($copied_tex[$z] eq '<')||($copied_tex[$z] eq '>')||($copied_tex[$z] eq ';')||($copied_tex[$z] eq 'B')||($copied_tex[$z] eq 'F')||($copied_tex[$z] eq 'J')||($copied_tex[$z] eq 'X')||($copied_tex[$z] eq 'Z'))
{
my $msgbox=$main_window->messageBox(-message=>" There is some error in the sequence", -type=>'ok');
$ff=1;
last;
}
}

if($ff==0){
for($z=0;$z<$dd;$z++)
{
if($copied_tex[$z] eq 'A')
{
$a=$a+1;
}
elsif($copied_tex[$z] eq 'C')
{
$c=$c+1;
}
elsif($copied_tex[$z] eq 'D')
{
$d=$d+1;
}
elsif($copied_tex[$z] eq 'E')
{
$e=$e+1;
}
elsif($copied_tex[$z] eq 'F')
{
$f=$f+1;
}
elsif($copied_tex[$z] eq 'G')
{
$g=$g+1;
}
elsif($copied_tex[$z] eq 'H')
{
$h=$h+1;
}
elsif($copied_tex[$z] eq 'I')
{
$i=$i+1;
}
elsif($copied_tex[$z] eq 'K')
{
$k=$k+1;
}
elsif($copied_tex[$z] eq 'L')
{
$l=$l+1;
}
elsif($copied_tex[$z] eq 'M')
{
$m=$m+1;
}
elsif($copied_tex[$z] eq 'N')
{
$n=$n+1;
}
elsif($copied_tex[$z] eq 'O')
{
$o=$o+1;
}
elsif($copied_tex[$z] eq 'P')
{
$p=$p+1;
}
elsif($copied_tex[$z] eq 'Q')
{
$q=$q+1;
}
elsif($copied_tex[$z] eq 'R')
{
$r=$r+1;
}
elsif($copied_tex[$z] eq 'S')
{
$s=$s+1;
}
elsif($copied_tex[$z] eq 'T')
{
$t=$t+1;
}
elsif($copied_tex[$z] eq 'U')
{
$u=$u+1;
}
elsif($copied_tex[$z] eq 'V')
{
$v=$v+1;
}
elsif($copied_tex[$z] eq 'W')
{
$w=$w+1;
}
elsif($copied_tex[$z] eq 'Y')
{
$y=$y+1;

}
else
{
my $msgbox=$main_window->messageBox(-message=>" There is some error in the sequence", -type=>'ok');


}
}


 $MM=$a+$c+$d+$e+$f+$g+$h+$i+$k+$l+$m+$n+$o+$p+$q+$r+$s+$t+$u+$v+$w+$y;

$ap=($a/$MM)*100;
$cp=($c/$MM)*100;
$dp=($d/$MM)*100;
$ep=($e/$MM)*100;
$fp=($f/$MM)*100;
$gp=($g/$MM)*100;
$hp=($h/$MM)*100;
$ip=($i/$MM)*100;
$kp=($k/$MM)*100; 
$lp=($l/$MM)*100;
$mp=($m/$MM)*100;
$np=($n/$MM)*100;
$op=($o/$MM)*100;
$pp=($p/$MM)*100;
$qp=($q/$MM)*100;
$rp=($r/$MM)*100;
$sp=($s/$MM)*100;
$tp=($t/$MM)*100;
$up=($u/$MM)*100;
$vp=($v/$MM)*100;
$wp=($w/$MM)*100;
$yp=($y/$MM)*100;

#######hydrophobic nd hydrophilic####


$count=0; 
  for($i=0;$i<$dd;$i++)
  {
     if (($copied_tex[$i] eq 'G') ||($copied_tex[$i] eq 'A') ||($copied_tex[$i] eq 'V')||($copied_tex[$i] eq 'L')||  ($copied_tex[$i] eq 'I')||($copied_tex[$i] eq 'P')||($copied_tex[$i] eq 'M')||($copied_tex[$i] eq 'F')||($copied_tex[$i] eq 'Y')||($copied_tex[$i] eq 'C'))
    
       {
                    $count = $count + 1;
       }
  }

$seq=($dd-$count);
print"Hydrophobic Sequence:$count \n";
print"Hydrophilic Sequence :$seq\n";

$perhydrophobic=($count/$dd)*100;
$perhydrophilic=($seq/$dd)*100;
print"$perhydrophobic\n";
print"$perhydrophilic";

#######graph inside composition###
my $mwg = MainWindow->new;
$mwg->geometry( "900x600" );

my $frame1  = $mwg->Frame(-borderwidth => 2,
-relief => 'groove')->grid(-row => 1,
                    -column => 1,
                    -sticky => 'nw')->pack(
-fill => 'both',
-expand => yes);
my $frame2  = $mwg->Frame(-relief => 'groove')->grid(-row => 2,
                    -column => 1)->pack();


my $selview = $frame2->Label->pack;

 $selview->configure(-text => "Percentage of Hydrophobic aminoacid:$perhydrophobic  \n         Percentage of hydrophilic aminoacid:$perhydrophilic  ");


   my $data = {
        'A%'   =>$ap,'C%'  => $cp,'D%'   => $dp,'E%'    => $ep,'F%'    => $fp,'G%'   => $gp,'H%'  => $hp,
        'I%'   =>$ip,'K%'  => $kp,'L%'   => $lp,'M%'    => $mp,'N%'   => $np,'O%'  => $op,
        'P%'   =>$pp,'Q%'  => $qp,'R%'   => $rp,'S%'    => $sp,'T%'   => $tp,'U%'  => $up,
        'V%'   =>$vp,'W%'  => $wp,'Y%'   => $yp};


   my $ca =$frame1->Graph(
                -type  => 'Bars',
        )->pack(
                -expand => yes,
                -fill => 'both',
        );

$ca->configure(-variable => $data);     # bind to data

   # or ...   

   $ca->set($data);        # set data


my $msgbox=$main_window->messageBox(-message=>" percentage of Alanine(A)\t=$ap\n
 percentage of Cysteine(C)\t=$cp\n
 percentage of Aspartic Acid(D)=$dp\n 
 percentage of Glutamic Acid(E)=$ep\n
 percentage of Glycine(G)\t=$gp\n
 percentage of Histidine(H)\t=$hp\n
 percentage of Isoleucine(I)\t=$ip\n
 percentage of Lysine (K)\t=$kp\n
 percentage of Leucine(L)\t=$lp\n
 percentage of Methionine(M)\t=$mp\n
 percentage of Asparagine(N)\t=$np\n
 percentage of Pyrrolysine(O)\t=$op\n
 percentage of Proline(P)\t=$pp\n
 percentage of Glutamine(Q)\t=$qp\n
 percentage of Arginine(R)\t=$rp\n
 percentage of Serine(S)\t=$sp\n
 percentage of Threonine(T)\t=$tp\n
 percentage of Selenocysteine(U)=$up\n
 percentage of Valine (V)\t=$vp\n
 percentage of Tryptophan(W)=$wp\n
 percentage of Tyrosine(Y)\t=$yp\n
", -type=>'ok');

}
}
########################################################################################################################

sub selectandrough{

my $s2 = $txt->getSelected( );
 my $mw10;
$mw10=MainWindow->new;
$mw10->configure (-bg=>white);
$mw10->minsize (qw (500 200));
my $menubar=$mw10->Frame (-relief=>'groove',-borderwidth=>2) ->pack (-side=>'top',-fill=>'x');






my $file=$mw10->Menubutton (-text=>'File',-foreground=>black,) ->pack (-side=>'left');
my $main;
$file->command (-label=>'New',-accelerator=>'ctrl+N',-command=>[\&newpage, 'New']);

my $paste_text = $mw10->Scrolled('Text',-font=>'fixed',-scrollbars=>"oe",-cursor=>'ibeam',-width=>10,-height=>10,-background => "white",                                       -foreground => "black") -> pack(-fill=>'both',-expand=>'yes');
$paste_text -> insert('end',$s2);MainLoop;
                    }


#############################################################################################################


sub insert
{

 $txt->insert('insert', " ");
#$main_window->waitVisibility;

}
#############################################################################################################

sub font_size
{
 
my $mw11;
$mw11=MainWindow->new;
my $f = $mw11->Frame->pack(-side => 'bottom');

my $family = 'Courier';
my $be = $f->BrowseEntry(-label => 'Family:', -variable => \$family,
  -browsecmd => \&apply_font)->pack(-fill => 'x', -side => 'left');
$be->insert('end', sort $mw11->fontFamilies);

my $size = 24;
my $bentry = $f->BrowseEntry(-label => 'Size:', -variable => \$size, 
  -browsecmd => \&apply_font)->pack(-side => 'left');
$bentry->insert('end', (3 .. 32));

my $weight = 'normal';
$f->Checkbutton(-onvalue => 'bold', -offvalue => 'normal', 
  -text => 'Weight', -variable => \$weight, 
  -command => \&apply_font)->pack(-side => 'left');

my $slant = 'roman';
$f->Checkbutton(-onvalue => 'italic', -offvalue => 'roman', 
  -text => 'Slant', -variable => \$slant, 
  -command => \&apply_font)->pack(-side => 'left');

my $underline = 0;
$f->Checkbutton(-text => 'Underline', -variable => \$underline, 
  -command => \&apply_font)->pack(-side => 'left');

my $overstrike = 0; 
$f->Checkbutton(-text => 'Overstrike', -variable => \$overstrike, 
  -command => \&apply_font)->pack(-side => 'left');








&apply_font;



sub apply_font
{
#use Tk;
$txt->configure(-font => 
    [-family => $family,
     -size => $size,
     -weight => $weight,
     -slant => $slant,
     -underline => $underline,
     -overstrike => $overstrike]);
MainLoop;
}

}
##############################################################################################################


####################################################################################################

sub colour_picker1 {
   
  my $colour = $txt->chooseColor( -title => 'Color Picker', -initialcolor => '#000000' );

  $buttonp20->configure( -background => $colour, -activebackground => $colour );
  return $colour;
1;
} 

####################################################################################################
sub graphd{



my $copied_tex = $txt->get('0.0','end');
chomp ($copied_tex);

$d=length($copied_tex);
chomp($d);

@copied_tex=split('',$copied_tex);


$a=$g=$c=$t=$u=0;

for($i=0;$i<$d;$i++)
{

if($copied_tex[$i] eq 'A')
{

$a=$a+1;
}
elsif($copied_tex[$i] eq 'G')
{

$g=$g+1;
}
elsif($copied_tex[$i] eq 'C')

{

$c=$c+1;
}
elsif($copied_tex[$i] eq 'T')
{
$t=$t+1;
}
elsif($copied_tex[$i] eq 'U')
{
$u=$u+1;
}

}

$total=$a+$g+$t+$c+$u;

if ($t eq 0)
{
  $v=0;
}
else
{
$v=$a+$t;
}
$q=$g+$c;

$GC=($q/$total)*100;
$AT=($v/$total)*100;

my $mwg = MainWindow->new;
$mwg->geometry( "900x600" );

   my $data = {
        'A%'   =>$a,'G%'  => $g,'C%'   => $c,'T%'    => $t,'U%'   => $u,'GC%'   => $GC,'AT%'  => $AT};

   my $ca = $mwg->Graph(
                -type  => 'Bars',
        )->pack(
                -expand => 1,
                -fill => 'both',
        );

$ca->configure(-variable => $data);     # bind to data

   # or ...   

   $ca->set($data);        # set data


}
##########################################################################################################################################################
sub graphp {
  
my $copied_tex = $txt->get('0.0','end');
chomp ($copied_tex);

$dd=length($copied_tex);


@copied_tex=split('',$copied_tex);


  $a= $c= $d= $e= $f= $g= $h= $i=$j= $k= $l= $m= $n= $o= $p= $q= $r= $s= $t= $u= $v= $w= $y=0;

for($z=0;$z<$dd;$z++)
{
if($copied_tex[$z] eq 'A')
{
$a=$a+1;
}
elsif($copied_tex[$z] eq 'C')
{
$c=$c+1;
}
elsif($copied_tex[$z] eq 'D')
{
$d=$d+1;
}
elsif($copied_tex[$z] eq 'E')
{
$e=$e+1;
}
elsif($copied_tex[$z] eq 'F')
{
$f=$f+1;
}
elsif($copied_tex[$z] eq 'G')
{
$g=$g+1;
}
elsif($copied_tex[$z] eq 'H')
{
$h=$h+1;
}
elsif($copied_tex[$z] eq 'I')
{
$i=$i+1;
}
elsif($copied_tex[$z] eq 'K')
{
$k=$k+1;
}
elsif($copied_tex[$z] eq 'L')
{
$l=$l+1;
}
elsif($copied_tex[$z] eq 'M')
{
$m=$m+1;
}
elsif($copied_tex[$z] eq 'N')
{
$n=$n+1;
}
elsif($copied_tex[$z] eq 'O')
{
$o=$o+1;
}
elsif($copied_tex[$z] eq 'P')
{
$p=$p+1;
}
elsif($copied_tex[$z] eq 'Q')
{
$q=$q+1;
}
elsif($copied_tex[$z] eq 'R')
{
$r=$r+1;
}
elsif($copied_tex[$z] eq 'S')
{
$s=$s+1;
}
elsif($copied_tex[$z] eq 'T')
{
$t=$t+1;
}
elsif($copied_tex[$z] eq 'U')
{
$u=$u+1;
}
elsif($copied_tex[$z] eq 'V')
{
$v=$v+1;
}
elsif($copied_tex[$z] eq 'W')
{
$w=$w+1;
}
elsif($copied_tex[$z] eq 'Y')
{
$y=$y+1;

}
}

$MM=$a+$c+$d+$e+$f+$g+$h+$i+$k+$l+$m+$n+$o+$p+$q+$r+$s+$t+$u+$v+$w+$y;

$ap=($a/$MM)*100;
$cp=($c/$MM)*100;
$dp=($d/$MM)*100;
$ep=($e/$MM)*100;
$fp=($f/$MM)*100;
$gp=($g/$MM)*100;
$hp=($h/$MM)*100;
$ip=($i/$MM)*100;
$kp=($k/$MM)*100; 
$lp=($l/$MM)*100;
$mp=($m/$MM)*100;
$np=($n/$MM)*100;
$op=($o/$MM)*100;
$pp=($p/$MM)*100;
$qp=($q/$MM)*100;
$rp=($r/$MM)*100;
$sp=($s/$MM)*100;
$tp=($t/$MM)*100;
$up=($u/$MM)*100;
$vp=($v/$MM)*100;
$wp=($w/$MM)*100;
$yp=($y/$MM)*100;


my $mwg = MainWindow->new;
$mwg->geometry( "900x600" );
   my $data = {
        'A%'   =>$ap,'C%'  => $cp,'D%'   => $dp,'E%'    => $ep,'F%'    => $fp,'G%'   => $gp,'H%'  => $hp,
        'I%'   =>$ip,'K%'  => $kp,'L%'   => $lp,'M%'    => $mp,'N%'   => $np,'O%'  => $op,
        'P%'   =>$pp,'Q%'  => $qp,'R%'   => $rp,'S%'    => $sp,'T%'   => $tp,'U%'  => $up,
        'V%'   =>$vp,'W%'  => $wp,'Y%'   => $yp};


   my $ca = $mwg->Graph(
                -type  => 'Bars',
        )->pack(
                -expand => yes,
                -fill => 'both',
        );

$ca->configure(-variable => $data);     # bind to data

   # or ...   

   $ca->set($data);        # set data
}
###########################################################################################################################################################
sub translate_RNA{


my $copied_tex = $txt->get('0.0','end');
chomp ($copied_tex);
 
my $mwd;
$mwd=MainWindow->new;

$mwd->configure (-bg=>white);

$mwd->minsize (qw (500 200));


        my $rna = "";
       
        $len = length($copied_tex);
        $i = 0;
        while($i <= $len)
        	{
                        $n = substr($copied_tex,$i,1);
                        if ($n eq "A")
                        {
                                $rna .= "U";
                        }
                        elsif ($n eq "T")
                        {
                                $rna .= "A";
                        }
                        elsif ($n eq "G")
                        {
                                $rna .= "C";
                        }
                        elsif ($n eq "C")
                        {
                                $rna .= "G";
                        }
                        $i++;
                }
		
my $paste_text = $mwd->Scrolled('Text',-width => '40', -height => '20', -font => 'fixed',-scrollbars=>"oe",-cursor=>'ibeam',-width=>10,-height=>10,-background => "white",
                                       -foreground => "black") -> pack(-fill=>'both',-expand=>'yes');

                
                $paste_text ->delete('0.0','end');
          	$paste_text ->insert('end',"\nThe RNA sequence will be - ");
                $paste_text ->insert('end',"\n$rna");
       
    }

######################################################################################################################

sub translate_protein
	{

my $copied_tex = $txt->get('0.0','end');
chomp ($copied_tex);
 
my $mwd;
$mwd=MainWindow->new;

$mwd->configure (-bg=>white);

$mwd->minsize (qw (500 200));
        
        $len = length($copied_tex);
	%genecode = ("TTT" => "F",
			"TTC" => "F",
			"TTA" => "L",
			"TG" => "L",
			"TCT" => "S",
			"TCC" => "S",
			"TCA" => "S",
			"TCG" => "S",
			"TAT" => "Y",
			"TAC" => "Y",
			"TAA" => "Ochre (Stop)",
			"TAG" => "Amber (Stop)",
			"TGT" => "C",
			"TGC" => "C",
			"TGA" => "Opal (Stop)",
			"TGG" => "W",
			"CTT" => "L",
			"CTC" => "L",
			"CTA" => "L",
			"CTG" => "L",
			"CCT" => "P",
			"CCC" => "P",
			"CCA" => "P",
			"CCG" => "P",
			"CAT" => "H",
			"CAC" => "H",
			"CAA" => "Q",
			"CAG" => "Q",
			"CGT" => "R",
			"CGC" => "R",
			"CGA" => "R",
			"CGG" => "R",
			"ATT" => "I",
			"ATC" => "I",
			"ATA" => "I",
			"ATG" => "M",
			"ACT" => "T",
			"ACC" => "T",
			"ACA" => "T",
			"ACG" => "T",
			"AAT" => "N",
			"AAC" => "N",
			"AAA" => "K",
			"AAG" => "K",
			"AGT" => "S",
			"AGC" => "S",
			"AGA" => "R",
			"AGG" => "R",
			"GTT" => "V",
			"GTC" => "V",
			"GTA" => "V",
			"GTG" => "V",
			"GCT" => "A",
			"GCC" => "A",
			"GCA" => "A",
			"GCG" => "A",
			"GAT" => "D",
			"GAC" => "D",
			"GAA" => "E",
			"GAG" => "E",
			"GGT" => "G",
			"GGC" => "G",
			"GGA" => "G",
			"GGG" => "G");

		my $i = 0;
               
		
my $paste_text = $mwd->Scrolled('Text',-width => '40', -height => '20', -font => 'fixed',-scrollbars=>"oe",-cursor=>'ibeam',-width=>10,-height=>10,-background => "white",
                                       -foreground => "black") -> pack(-fill=>'both',-expand=>'yes');

 $paste_text ->delete('1.0','end');
 $paste_text ->insert('end',"\nThe corressponding amino acid sequence is -\n\n");
		while ($i < $len-2)
		{
			my $n = substr($copied_tex,$i,3);
			$paste_text ->insert('end',"$genecode{$n}");
			$i = $i+3;
		}
}
##################################text area color###################################################################

sub black{

$txt->configure(-background=>black,-foreground=>'white');

}
##          ###          ###
sub skyblue{

$txt->configure(-background=>skyblue,-foreground=>'black');

}
##          ###          ###
sub brown{

$txt->configure(-background=>brown,-foreground=>'white');

}
##          ###          ###
sub grey{

$txt->configure(-background=>grey,-foreground=>'black');

}
##          ###          ###
sub white{

$txt->configure(-background=>white,-foreground=>'black');

}
sub pink{

$txt->configure(-background=>pink,-foreground=>'black');

}
###################################### TIME  ##################################################################


sub times{

$mwn = MainWindow->new();
$mwn->geometry( "400x100" );
$book = $mwn->NoteBook()->pack( -fill=>'both');

$tab1 = $book->add( "Sheet 1", -label=>"Started At", -createcmd=>\&getStartTime );
$tab2 = $book->add( "Sheet 2", -label=>"current Time", -raisecmd=>\&getCurrentTime );
$tab3 = $book->add( "Sheet 3", -label=>"End", -state=>'disabled' );

$tab1->Label( -textvariable=>\$starttime )->pack();
$tab2->Label( -textvariable=>\$raisetime )->pack();
$tab3->Button( -text=>'Quit', -command=>sub{ exit; } )->pack();

}
############################               #####         ####
sub getStartTime {
  $starttime = "Started at " . localtime;
}

sub getCurrentTime {
  $raisetime = " Current Time " . localtime;
  $book->pageconfigure( "Sheet 3", -state=>'normal' );
}
    
################################About##########################################################
sub about {
    
    my $mwref = shift;
    my $mw = $$mwref;

    my $helpwin = MainWindow->new(-title=>"About");
    $helpwin->minsize (qw (700 400));


    $helpwin->focusForce;


    my $hf = $helpwin->Frame()->pack(-fill=>'both',
				     -expand=>1,
				     );

    my $hn = $hf->NoteBook()->pack(-fill=>'both',
				   -expand=>1,
				   );
    my $overview = $hn->add("overview",
			 -label=>"Manual",
			 );

    my $files = $hn->add("files",
			 -label=>"About",
			 );

    my $options = $hn->add("options",
			   -label=>"Contact",
			   );

    my $ov_t = $overview->Scrolled('ROText',-width => '40', -height => '20', -font => 'fixed',
				   -wrap=>'word',
				   -scrollbars=>'osoe',
				   )->pack(-fill=>'both',
					   -expand=>1,
					   );
    my $file_t = $files->Scrolled('ROText',-width => '40', -height => '20', -font => 'fixed',
				  -wrap=>'word',
				  -scrollbars=>'osoe',
				  )->pack(-fill=>'both',
					  -expand=>1,
					  );
    my $opt_t = $options->Scrolled('ROText',-width => '40', -height => '20', -font => 'fixed',
				   -wrap=>'word',
				   -scrollbars=>'osoe',
				   )->pack(-fill=>'both',
					   -expand=>1,
					   );
     my $ov_data = <<EOF;
1. DESCRIPTION 
 The Bionotepad is a intuitive biotext editor  for  biomolecules. By using the Bionotepad you will have more functions to manipulate the biological problems, easy-to-use and easy to understand interface. The main difference and advantage of this program is its universality. It is not a tool for Analysis only but this bionotepad is necessary for everyone, who are in the bioinformatics field as well as common users.
Features of the Bionotepad :

File : This submenu allows normal notepad manipulations including New, Open, Save, Save as, Print and Exit .            

Edit : The Edit option helps  in Undo, Redo, Cut, Copy, Paste, Delete, Find, Replace, Select All, Time, Date and Go to.
The Time and date option  allows the user to see the time and date in another window, instead of coming in the same window as comparing to the Microsoft notepad.

Format : Format  option helps in  word wrap and  changing  the font.


Window : This is an additional feature  of  bionotepad which  will make the work more easier and interesting . I  have added  options  like  Statistics, Rough work  and   Split Window.The Rough work option will open an additional work space.The Split window will  split the  window into two. Hopes you will enjoy it.

SeqExplore : This is a separate and additional menu option for Sequence Manipulation. It helps in   Importing  and Exporting  sequence,Calculating the  Length, GC% and ATCG%, Translating the entire sequence into DNA, RNA or Protein, Reversing the sequence,Plotting  Graph, Mutating the sequence, Inserting gaps or Making Dotplot.
	Users can produce  BLAST and FASTA outputs with the sequence or can align multiple sequence for  phylogentic analysis by using ClustalW.There are options to view the structure of the sequence by using PDB or can explore the  annotated details of the protein from SwissProt Database.

FormatConverter : Format of the sequence can be changed from one  to another.The format converting options include  Fasta->Genbank, Genbank->Fasta, ClustalW->Phylip, Aln->Phylip, EMBL->Genbank, DDBJ->Genbank, Genbank->EMBL

Tools : This section helps  the user for Microarray Analysis ,along with online access to web tools like Web cutter, Primer detection, Graph align, Genscan, Tf sitesscan and Reverse Translate.

EOF

my $file_data = <<EOF;



                                                 BioNotepad Version-B1
                                                 Version B1 Year :- 2010



                                Website  :- http://bioinformaticsonline.com/bionotepad.html

EOF

my $opt_data = <<EOF;


                                     BioNotepad  Version-b1



   1) Mr.RAHUL V V                       email:- vvrahul11[at]gmail.com

   2)Miss.NEETHU JABALIA            email:- njabalia[at]gmail.com
   
   3)Mr.ASHISH GUPTA                    email:- ashish.200721[at]gmail.com

   4) Mr.JITENDRA NARAYAN        email:- jnarayan[at]amity.edu

   

For More Details And Downloads :- http://bioinformaticsonline.com/bionotepad.html

  
    

EOF

 

 


    $ov_t->insert('end',$ov_data);
    $file_t->insert('end',$file_data);
    $opt_t->insert('end',$opt_data);
    $stat_t->insert('end',$stat_data);
    $warn_t->insert('end',$warn_data);
    $add_t->insert('end',$add_data);
}
##############################################################################################
sub demodna
{

  
$txt->delete('0.0', 'end');
$txt-> insert('end',"
TATAAATAGTATAGTAACCCCTATAAACAATAAAAGGAATATATAAACAAAATTCATAAACAATCCCTTT
TCAATGTTTGGTTTATTTATAGTAAAGATTTAATATCCTCGTATTATTCTACACCCCATTTTCAATAATC
CTAACCCACTCATGAGATATTATTTTCTTAATTAATTTGTTTATTTCTTTATCACCTTTTATTGATTCAT
AAACTTCATTAATTGTTTTTAGATTTTCTTCCTCTAATTGTTTTAATTCCTCTTCCTCTTCTTCTGTTAA
ATCGCCTTCTAACAGCTTTTTCCAATACAATTCAGCCCATCTATCATAATTTATTGGTTTTAAGTGCTTT
GAAATTGTTTCTAATAGATGTTCTTCATCCCCACTGTATAATTTTGTTTGGAGCGGAGCTTTTAAGGAAC
TTGGTTAATTAAAGAAATCCCAGTTTATTAAGTATATCTTTTTCAAGAATCTCAAGGATTTCTAAGACAT
CTCGACCTTTTGTAATTGGTCTGATAATCCAATATTCTGCATTTTTCTGTTTTAAGTCATCATGTTCTCC
ATAGTTTTCTAAGTCATCAAATGTGCAACCCCCTACAAAATAAACTTTTACGTTATTTTTAAAATAATCC
AGAGCTTTATTTTTTTCCTGTTTAAAAGCATTTTCTAATCTTTTGTTATATTCCCATTTTTTTAAGTGAG
GATTATATCCATAATCTCCTGGATTGTGAAATATTATTCTAAAATAATAATCTTTATTATGTTCTTTCGA
CTTATAAGATGTAGTGTATGAACCCAATATATCAAAATCTTTATTTAAAATGTCATTTAAGTCATATTTA
GTGGCTATTGATGACCTAATCTCTATTGTAATTATCTCATCATTTGAAAGATGAATTTCTATGTCATTGT
GGGATTCATAGTTAAAATTTTCATTGCTTACATTTGCACCTTTGATTTCAATGTAATCTTTTATTAACAT
TAATTTTTCAGTAATTAATTGTTTTACAACTTTTTCTGCAATAAGTCCGCAAAATGATGACAATAATTTT
CTTTCTTCTGTTCTTATATCTCCACTTGGATTCTTTTCACAAACATCTTCTGCTAATTTTTTAGCTTCAT
CATGGATATTATTTAATTCATTATCATCTAATTCTACTTTTATTACTACAAAAATATTTTTTTGTGATAT
AGGGGTTATTTTGCTTCCATTATATTTATTTATAGGATGTCTATAGTATTTTTCAAATATAAATTTCATA
CAATCACCTTAATTTTTATTCCGTATCTTACGCACCAATTCATTTGTATTTATGGTATTTAGTAATTTAA
TAATATTTTGGCAGTATTTTAAGCAGTCTATGGATTTTTCGTCATACTTTTTTATGATGCCATTAATTTC
ATTGCAGATTTCGTTTAATTCCTCTTTTGGTATTAAGTCTTGGAAGTAAATCCCATAAACTAATGAATCT
ATTATATTTTCTAAAAATATTCTGTCATTTTCATTTAATTTATCGTTTAATTCGAACCTCAATTTACTTA
ACTGTGTTAAAGCGTTTATTATGTTTTTATTTTTGGGGATTACTATAGGTAACTCTCTTAATTCTTCTAA
GGTAGTCTGCCTAAAATCATCTTTTAATGCTATTGCCGACTTTCCAATGTATATATAAGATATTAACTCA
CTATTTAGTATTCCTAATAAATAGAAGTAATTAATAGGAGTATCTGGCTTTAAAACAAACACATACAAAT
CCTTTTTTACAACTCCTTCAATATTTCCATAAGATGCCATAATTCTATCTTGTCTATTAACGATTCTCCG
TATAAAGATTTTCTCGGGAGACATAAATAGATTAATAAGCTTTTCGTTGTTTTTATGTTTTGAGAAATCA
ACATAATTTTTTAATTTTAATTTAGTTTCATACCTATACACATTACCTTCTAAATATGGCAAATAATATT
CGTTTTCTTTTTTATCTGAAAATTTATATTTTGAAGCTAAAATTCCTATTGTAGATTCTGTTAAATCTTC
CAAGTAAGTTAGTGATTCTCTACAATTTTGTTTAATTTTATCTAATATTATGTAGATTTCGGGACTTTTT
GGGAATATTCGACACTTTGGGTCATTTAATATTTTTGAATATTCTATGAAAAGGTCATTTTTAAACTCAA
ATGAGATTTTTTTAGTTTTTTTAGGGAATGCATATATCAAAACCAAATCTTCTGATTTTGGAGGTTTTTT
ATGCAGTATTATTATACAATTATCAACATACGCTCCTGAAAATACATCAAAAGGTAGATAGATTAATTTT
TTCAGACACATTTTTGTAAATAACTCTTTTCTAAGATTTGAATATCTCACACCCGTTCCAAAACTTGATG
GGATTATAAATCCTAAATACCCCTCATTTTTCAATAATTTACTACTATGCACTATAAATGTTACAAAAAT
GTCAAATTCAGGAGTATCTCTACGTTTCATAATTTCTTTTTCAGTAGGAGATAGCAAATTCCCATAAGGT
GGATTTCCAATAATTACATCAAAACCTTCCTCTTTAATAATCCATCCGAAGTCAATCTTCCAATGGAAGG
GTTTTAATTTTTCAAATTCCTCAACACGTGGTCTATTCTTTTTACTTTTTTTACCATTATTCTTTTTGTT
ATTTCCATTTTGGTAAATCTCAGCGAAATATGCTGGAGTTACACTCTCATATATTGAATCTCTAATTTCA
TCTAATAATTCTTTTAACAGATTGGCTTTAAGTCCGTGGCTTGTTCTATATACTTCATAAAGGAGATGAT
ACGCTTCCACATAATTGTCTAATACATATCCATCTCTTTTTTCAAGCAATTCTTTAGCTTTTTTCAGTTT
TTTTCTCTCTTCAGAATTGTGAGCGTTGATAATTAAACCTTCAAGAACACACATTATACGCACATTATCG
CATAGGTAGGAGATGGAAAGCTGTTTTAAATTTTCATCAATCCATCCAACTAAACTGTTACCACATCTTA
CATTATACTCAATATTTGGCAGTAAAACTTCTCCTCTTTTTAAAGCCTCAACGTCTAAATTCTCAATAAG
AGCAAGCCACAACCTAAGTTTTGCTATTTCAACAGCAATATCATCAATATCAACACCATAAAGATTGTTT
AGTATAATACCTAACTTTTCTTTGTAAATGTCCATCTCTTCTCTAAGTAAATAATAAATCCTTTTCTTAA
TTTGGAGCAATTCCTTTAATGCAGATATTAAGAAATGACCACTTCCAACTGCGGGGTCTAAAATTCTTAT
TTTATCCAATTCATCAAGAAAAGCTCTTAAAATATGTTTATTTTCAGCTATTTTACTATCTTCATTAAGA
ATTTCATCTAATGTTGAGAAATTAATGTCATTTATTTTCCAATTTTTAATAATCTCTTTAAACCTCTCTA
CAACAATCGGCTCTATTGTATTTTTGGCAATATAGCTTGTAATCTCATCTGGAGTATAATAAGCACCCAG
TCCTTTCTGCCCTTTTTCTGCCAAAATATTAATTAACTTTTCATAAACATACCCAAGAATATCTGGATTT
AATTCAACTTCTTCTGAACCTTCAGATGTAGATAGAGTGAATTTATACCTTTCTAAAAAATTAATAACCT
CTCCAATAATTTCATTATCTTTTATAGTAAATGATAGTTCGTTAGGAACATTATTACTCCTGAATAATCC
ACCATTTAAGTAAGGGATGTCTTTATAGTAAGGATTAGTTCTAATATTTTCTTTTCTTTCATCTTCTGGA
GTATTAAGCACTTCATAGAATAATGGTTTAAGATAAGCATCATAATAATTTATTAAAACGTTAGATTTTT
TGTAATCTTCATAAGTTCTTCTAAGCAAATCTCTTGGGACTATTCCCTTGTCCTCAAGGAATTTTATAAA
TATTAACCTGTTCATTAACAATACTGCAAATTTTTTCTTGTCCAATTCTGATGTATTGGGTGGAGCTTCA
ATACAATTGTATAAGCATTTTTTAGTGCCTTTATCTTTTTCTGAACTACTTTTATCTTTTTTCTTAACAT
");
}
###########################################################################################
sub demoprtn
{

  
$txt->delete('0.0', 'end');
$txt-> insert('end',"
GSLDIAVYWGQSFDERSLEATCDSGNYAYVIIGFLNTFGGGQTPALDISGHSPKGLEPQIKHCQSKNVKVLLSIGGPAGPYSLDSRNDANDLAVYLHKNFLLPPAGTSESRPFGNAVLDGIDFHIEHGGPSQYQLLANILSSFRLSGSEFALTAAPQCVYPDPNLGTVINSATFDAIWVQFYNNPQCSYSASNASALMNAWKEWSMKARTDKVFLGFPAHPDAAGSGYMPPTKVKFSVFPNAQDSTKFGGIMLWDSYWDTVSQFSNKILGKGV
GSLDIAVYWGQSFDERSLEATCDSGNYAYVIIGFLNTFGGGQTPALDISGHSPKGLEPQIKHCQSKNVKVLLSIGGPAGPYSLDSRNDANDLAVYLHKNFLLPPAGTSESRPFGNAVLDGIDFHIEHGGPSQYQLLANILSSFRLSGSEFALTAAPQCVYPDPNLGTVINSATFDAIWVQFYNNPQCSYSASNASALMNAWKEWSMKARTDKVFLGFPAHPDAAGSGYMPPTKVKFSVFPNAQDSTKFGGIMLWDSYWDTVSQFSNKILGKTALPLLCAGAWLLSAGATAELTVNAIEKFHFTSWMKQHQKTYSSREYSHRLQVFANNWRKIQAHNQRNHTFKMGLNQFSDMSFAEIKHKYLWSEPQNCSATKSNYLRGTGPYPSSMDWRKKGNVVSPVKNQGACGSCWTFSTTGALESAVAIASGKMMTLAEQQLVDCAQNFNNHGCQGGLPSQAFEYILYNKGIMGEDSYPYIGKNGQCKFNPEKAVAFVKNVVNITLNDEAAMVEAVALYNPVSFAFEVTEDFMMYKSGVYSSNSCHKTPDKVNHAVLAVGYGEQNGLLYWIVKNSWGSNWGNNGYFLIERGKNMCGLAACASYPIPQVMNPTLILAAFCLGIASATLTFDHSLEAQWTKWKAMHNRLYGMNEEGWRRAVWEKNMKMIELHNQEYREGKHSFTMAMNAFGDMTSEEFRQVMNGFQNRKPRKGKVFQEPLFYEAPRSVDWREKGYVTPVKNQGQCGSCWA
FSATGALEGQMFRKTGRLISLSEQNLVDCSGPQGNEGCNGGLMDYAFQYVQDNGGLDSEESYPYEATEESCKYNPKYSVANDTGFVDIPKQEKALMKAVATVGPISVAIDAGHESFLFYKEGIYFEPDCSSEDMDHGVLVVGYGFESTESDNNKYWLVKNSWGEEWGMGGYVKMAKDRRNHCGIASAASYPTV");
}

################################################################################################     
sub orf {
	
         
my $sequenceEntry = $txt->get('0.0','end');
chomp ($sequenceEntry);
my $mwf;
$mwf=MainWindow->new;

$mwf->configure (-bg=>white);

$mwf->minsize (qw (500 200));

				
my $paste_text = $mwf->Scrolled('Text',-width => '40', -height => '20', -font => 'fixed',-scrollbars=>"oe",-cursor=>'ibeam',-width=>10,-height=>10,-background => "white",
                                       -foreground => "black") -> pack(-fill=>'both',-expand=>'yes');


$paste_text ->delete('1.0','end');
         


$sequenceEntry =~ s/>[^\n]+//;


$sequenceEntry =~ tr/GATCN/gatcn/;

$sequenceEntry =~ s/[^gatcn]//g;


my @arrayOfORFs = ();


my @startsRF1 =();
my @startsRF2 =();
my @startsRF3 =();
my @stopsRF1 = ();
my @stopsRF2 = ();
my @stopsRF3 = ();


while ($sequenceEntry =~ m/atg/gi){
    my $matchPosition = pos($sequenceEntry) - 3;

   
    if (($matchPosition % 3) == 0) {
	push (@startsRF1, $matchPosition);
    }

   
    elsif ((($matchPosition + 2) % 3) == 0) {
	push (@startsRF2, $matchPosition);
    }
    
    else {
	push (@startsRF3, $matchPosition);
    }
}


while ($sequenceEntry =~ m/tag|taa|tga/gi){
    my $matchPosition = pos($sequenceEntry);
    if (($matchPosition % 3) == 0) {
	push (@stopsRF1, $matchPosition);
    }
    elsif ((($matchPosition + 2) % 3) == 0) {
	push (@stopsRF2, $matchPosition);
    }
    else {
	push (@stopsRF3, $matchPosition);
    }
}


my $codonRange = "";
my $startPosition = 0;
my $stopPosition = 0;


@startsRF1 = reverse(@startsRF1);
@stopsRF1 = reverse(@stopsRF1);


while (scalar(@startsRF1) > 0) {
    $codonRange = "";
    
    
    $startPosition = pop(@startsRF1);

   
    if ($startPosition < $stopPosition) {
	next;
    }
  
   
    while (scalar(@stopsRF1) > 0) {
	$stopPosition = pop(@stopsRF1);
	if ($stopPosition > $startPosition) {
	    last;
	}
    }

  
    if ($stopPosition <= $startPosition) {

	
	$stopPosition = length($sequenceEntry) - (length($sequenceEntry) % 3);

	$codonRange = "+1 " . $startPosition . ".." . $stopPosition;
	push (@arrayOfORFs, $codonRange);
	last;
    }


    else {

	$codonRange = "+1 " . $startPosition . ".." . $stopPosition;
	push (@arrayOfORFs, $codonRange);
    }
}


$stopPosition = 0;
@startsRF2 = reverse(@startsRF2);
@stopsRF2 = reverse(@stopsRF2);
while (scalar(@startsRF2) > 0) {
    $codonRange = "";
    $startPosition = pop(@startsRF2);
    if ($startPosition < $stopPosition) {
	next;
    }
    while (scalar(@stopsRF2) > 0) {
	$stopPosition = pop(@stopsRF2);
	if ($stopPosition > $startPosition) {
	    last;
	}
    }
    if ($stopPosition <= $startPosition) {

	
	$stopPosition = length($sequenceEntry) - ((length($sequenceEntry) + 2) % 3);
	$codonRange = "+2 " . $startPosition . ".." . $stopPosition;
	push (@arrayOfORFs, $codonRange);
	last;
    }
    else {
	$codonRange = "+2 " . $startPosition . ".." . $stopPosition;
	push (@arrayOfORFs, $codonRange);
    }
}


$stopPosition = 0;
@startsRF3 = reverse(@startsRF3);
@stopsRF3 = reverse(@stopsRF3);
while (scalar(@startsRF3) > 0) {
    $codonRange = "";
    $startPosition = pop(@startsRF3);
    if ($startPosition < $stopPosition) {
	next;
    }
    while (scalar(@stopsRF3) > 0) {
	$stopPosition = pop(@stopsRF3);
	if ($stopPosition > $startPosition) {
	    last;
	}
    }
    if ($stopPosition <= $startPosition) {

	
	$stopPosition = length($sequenceEntry) - ((length($sequenceEntry) + 1) % 3);
	$codonRange = "+3 " . $startPosition . ".." . $stopPosition;
	push (@arrayOfORFs, $codonRange);
	last;
    }
    else {
	$codonRange = "+3 " . $startPosition . ".." . $stopPosition;
	push (@arrayOfORFs, $codonRange);
    }
}



foreach(@arrayOfORFs) {
    
   
    $_ =~ m/([\+\-]\d)\s(\d+)\.\.(\d+)/;

    

$paste_text -> insert ('end', "Reading frame $1 " . ($2 + 1) . " to " . $3. ", Length: " . ($3 - $2) . ".\n" ); 


}
    	
    	
}
#####################################translated orf###########################################################################################################

sub torf{

my $MINORF = 102;


my %translationHash = 
    (gca => "A", gcg => "A", gct => "A", gcc => "A", gcn => "A",
     tgc => "C", tgt => "C",
     gat => "D", gac => "D",
     gaa => "E", gag => "E",
     ttt => "F", ttc => "F",
     gga => "G", ggg => "G", ggc => "G", ggt => "G", ggn => "G",
     cat => "H", cac => "H",
     ata => "I", att => "I", atc => "I",
     aaa => "K", aag => "K",
     cta => "L", ctg => "L", ctt => "L", ctc => "L", ctn => "L", tta => "L", ttg => "L",
     atg => "M",
     aat => "N", aac => "N",
     cca => "P", cct => "P", ccg => "P", ccc => "P", ccn => "P",
     caa => "Q", cag => "Q",
     cga => "R", cgg => "R", cgc => "R", cgt => "R", cgn => "R",
     aga => "R", agg => "R",
     tca => "S", tcg => "S", tcc => "S", tct => "S", tcn => "S",
     agc => "S", agt => "S",
     aca => "T", acg => "T", acc => "T", act => "T", acn => "T",
     gta => "V", gtg => "V", gtc => "V", gtt => "V", gtn => "V",
     tgg => "W",
     tat => "Y", tac => "Y",
     tag => "*", taa => "*", tga => "*");




         
my $directStrand = $txt->get('0.0','end');
chomp ($directStrand);
my $mwf;
$mwf=MainWindow->new;

$mwf->configure (-bg=>white);

$mwf->minsize (qw (500 200));

				
my $paste_text = $mwf->Scrolled('Text',-width => '40', -height => '20', -font => 'fixed',-scrollbars=>"oe",-cursor=>'ibeam',-width=>10,-height=>10,-background => "white",
                                       -foreground => "black") -> pack(-fill=>'both',-expand=>'yes');


$paste_text ->delete('1.0','end');




$directStrand =~ s/>[^\n]+//;
$directStrand =~ tr/GATCN/gatcn/;
$directStrand =~ s/[^gatcn]//g;


my $reverseComplement = $directStrand;
$reverseComplement =~ tr/gatcn/ctagn/;
my @arrayOfBases = split(/\B/, $reverseComplement);
my @reversedArray = reverse(@arrayOfBases);
$reverseComplement = join("",@reversedArray);


my @arrayOfORFs = ();

my @arrayOfTranslations = ();


for (my $i = 0; $i < 2; $i = $i + 1) {
    my $sequenceEntry = "";
    my $strand = "";
    if ($i == 0) {
	
	$sequenceEntry = $directStrand;
	$strand = "+";
    }
    else {
	
	$sequenceEntry = $reverseComplement;
	$strand = "-";
    }

    my @startsRF1 =();
    my @startsRF2 =();
    my @startsRF3 =();
    my @stopsRF1 = ();
    my @stopsRF2 = ();
    my @stopsRF3 = ();

    while ($sequenceEntry =~ m/atg/gi){
	my $matchPosition = pos($sequenceEntry) - 3;
	if (($matchPosition % 3) == 0) {
	    push (@startsRF1, $matchPosition);
	}
	elsif ((($matchPosition + 2) % 3) == 0) {
	    push (@startsRF2, $matchPosition);
	}
	else {
	    push (@startsRF3, $matchPosition);
	}
    }

    while ($sequenceEntry =~ m/tag|taa|tga/gi){
	my $matchPosition = pos($sequenceEntry);
	if (($matchPosition % 3) == 0) {
	    push (@stopsRF1, $matchPosition);
	}
	elsif ((($matchPosition + 2) % 3) == 0) {
	    push (@stopsRF2, $matchPosition);
	}
	else {
	    push (@stopsRF3, $matchPosition);
	}
    }

    my $codonRange = "";
    my $startPosition = 0;
    my $stopPosition = 0;

    @startsRF1 = reverse(@startsRF1);
    @stopsRF1 = reverse(@stopsRF1);
    while (scalar(@startsRF1) > 0) {
	$codonRange = "";
	$startPosition = pop(@startsRF1);
	if ($startPosition < $stopPosition) {
	    next;
	}
	while (scalar(@stopsRF1) > 0) {
	    $stopPosition = pop(@stopsRF1);
	    if ($stopPosition > $startPosition) {
		last;
	    }
	}
	if ($stopPosition <= $startPosition) {
	    $stopPosition = length($sequenceEntry) - (length($sequenceEntry) % 3);
	    $codonRange = $strand . "1 " . $startPosition . ".." . $stopPosition;
	    push (@arrayOfORFs, $codonRange);
	    last;
	}
	else {
	    $codonRange = $strand . "1 " . $startPosition . ".." . $stopPosition;
	    push (@arrayOfORFs, $codonRange);
	}
    }

    $stopPosition = 0;
    @startsRF2 = reverse(@startsRF2);
    @stopsRF2 = reverse(@stopsRF2);
    while (scalar(@startsRF2) > 0) {
	$codonRange = "";
	$startPosition = pop(@startsRF2);
	if ($startPosition < $stopPosition) {
	    next;
	}
	while (scalar(@stopsRF2) > 0) {
	    $stopPosition = pop(@stopsRF2);
	    if ($stopPosition > $startPosition) {
		last;
	    }
	}
	if ($stopPosition <= $startPosition) {
	    $stopPosition = length($sequenceEntry) - ((length($sequenceEntry) + 2) % 3);
	    $codonRange = $strand . "2 " . $startPosition . ".." . $stopPosition;
	    push (@arrayOfORFs, $codonRange);
	    last;
	}
	else {
	    $codonRange = $strand . "2 " . $startPosition . ".." . $stopPosition;
	    push (@arrayOfORFs, $codonRange);
	}
    }

    $stopPosition = 0;
    @startsRF3 = reverse(@startsRF3);
    @stopsRF3 = reverse(@stopsRF3);
    while (scalar(@startsRF3) > 0) {
	$codonRange = "";
	$startPosition = pop(@startsRF3);
	if ($startPosition < $stopPosition) {
	    next;
	}
	while (scalar(@stopsRF3) > 0) {
	    $stopPosition = pop(@stopsRF3);
	    if ($stopPosition > $startPosition) {
		last;
	    }
	}
	if ($stopPosition <= $startPosition) {
	    $stopPosition = length($sequenceEntry) - ((length($sequenceEntry) + 1) % 3);
	    $codonRange = $strand . "3 " . $startPosition . ".." . $stopPosition;
	    push (@arrayOfORFs, $codonRange);
	    last;
	}
	else {
	    $codonRange = $strand . "3 " . $startPosition . ".." . $stopPosition;
	    push (@arrayOfORFs, $codonRange);
	}
    }
}


foreach(@arrayOfORFs) {
    

    $_ =~ m/([\+\-])(\d)\s(\d+)\.\.(\d+)/;

    #Skip ORFs that are smaller than $MINORF
    if (($4 - $3) < $MINORF) {
	next;
    }

   
    my $ORFsequence = "";

   
    if ($1 eq "+") {
	$ORFsequence = substr($directStrand, $3, $4 - $3);
    }
    else {
	$ORFsequence = substr($reverseComplement, $3, $4 - $3);
    }


    my @growingProtein = ();
    for (my $i = 0; $i <= (length($ORFsequence) - 3); $i = $i + 3) {
	my $codon = substr($ORFsequence, $i, 3);
	if (exists( $translationHash{$codon} )){
	    push (@growingProtein, $translationHash{$codon});
	}
	else {
	    push (@growingProtein, "X");
	}
    }

  
    my $joinedAminoAcids = join("",@growingProtein);

   
    if ($1 eq "+") {
	$joinedAminoAcids = ">" . "ORF rf " . $1 . $2 . ", from " . ($3 + 1) .
	    " to " . $4 . ", " . ($4 - $3) . " bases.\n" . $joinedAminoAcids;
    }
    else {
	$joinedAminoAcids = ">" . "ORF rf " . $1 . $2 . ", from " . 
	(length($directStrand) - $4 + 1) . " to " . (length($directStrand) - $3) . 
	    ", " . ($4 - $3) . " bases.\n" . $joinedAminoAcids;
    }

    push (@arrayOfTranslations, $joinedAminoAcids);
}



$paste_text -> insert ('end', "Translated ORFs for $sequenceTitle, length = " . length($directStrand) . " bp.,minimum ORF size kept = " . $MINORF . " bases.\n\n" ); 




foreach(@arrayOfTranslations) {
$paste_text -> insert ('end', "$_ \n\n" ); 


    print "$_ \n\n";
}


}
#################################################################################################################################################3




##############  find  and  replace###########################################################################################################
sub findandreplace{

$txt->FindAndReplacePopUp;

}

################ go to line number ##############################################################################################################################
sub goto{
$txt->GotoLineNumberPopUp(line_number)
 
}

############################################################################################################

sub pickcolor{

#add colors
$txt->tagConfigure( 'tag1', -foreground => 'red',-background=>'yellow' );
$txt->tagConfigure( 'tag2', -foreground => 'blue',-background=>'grey' );
$txt->tagConfigure( 'tag3', -foreground => 'brown',-background=>'skyblue');
$txt->tagConfigure( 'tag4', -foreground => 'pink',-background=>'purple');
$txt->tagConfigure( 'tag17', -foreground => 'black');
$txt->tagConfigure( 'tag5', -foreground => 'yellow' );
$txt->tagConfigure( 'tag6', -foreground => 'skyblue' );
$txt->tagConfigure( 'tag7', -foreground => 'orange');
$txt->tagConfigure( 'tag8', -foreground => 'purple' );
$txt->tagConfigure( 'tag9', -foreground => 'grey' );
$txt->tagConfigure( 'tag10', -foreground => 'green');

#$txt->tagConfigure( 'tag11', -foreground => 'red' );
#$txt->tagConfigure( 'tag12', -foreground => 'violet' );
#$txt->tagConfigure( 'tag13', -foreground => 'grey');
#$txt->tagConfigure( 'tag14', -foreground => 'red' );
#$txt->tagConfigure( 'tag15', -foreground => 'blue' );
#$txt->tagConfigure( 'tag16', -foreground => 'green' );
#$txt->tagConfigure( 'tag18', -foreground => 'red' );
#$txt->tagConfigure( 'tag19', -foreground => 'red' );
#$txt->tagConfigure( 'tag20', -foreground => 'red' );





  
my $copied_tex = $txt->get('0.0','end');
chomp ($copied_tex);

$dd=length($copied_tex);
$txt->delete('0.0', 'end');


@copied_tex=split('',$copied_tex);

for($z=0;$z<$dd;$z++)
{
if($copied_tex[$z] eq 'A')
{
$txt->insert('end',"$copied_tex[$z]",'tag1');
}
elsif($copied_tex[$z] eq 'C')
{
$txt->insert('end',"$copied_tex[$z]",'tag2');
}
elsif($copied_tex[$z] eq 'D')
{
$txt->insert('end',"$copied_tex[$z]",'tag3');
}
elsif($copied_tex[$z] eq 'E')
{
$txt->insert('end',"$copied_tex[$z]",'tag4');
}
elsif($copied_tex[$z] eq 'F')
{
$txt->insert('end',"$copied_tex[$z]",'tag5');
}
elsif($copied_tex[$z] eq 'G')
{
$txt->insert('end',"$copied_tex[$z]",'tag6');
}
elsif($copied_tex[$z] eq 'H')
{
$txt->insert('end',"$copied_tex[$z]",'tag7');
}
elsif($copied_tex[$z] eq 'I')
{
$txt->insert('end',"$copied_tex[$z]",'tag8');
}
elsif($copied_tex[$z] eq 'K')
{
$txt->insert('end',"$copied_tex[$z]",'tag9');
}
elsif($copied_tex[$z] eq 'L')
{
$txt->insert('end',"$copied_tex[$z]",'tag10');
}
elsif($copied_tex[$z] eq 'M')
{
$txt->insert('end',"$copied_tex[$z]",'tag11');
}
elsif($copied_tex[$z] eq 'N')
{
$txt->insert('end',"$copied_tex[$z]",'tag12');
}

elsif($copied_tex[$z] eq 'P')
{
$txt->insert('end',"$copied_tex[$z]",'tag13');
}
elsif($copied_tex[$z] eq 'Q')
{
$txt->insert('end',"$copied_tex[$z]",'tag14');
}
elsif($copied_tex[$z] eq 'R')
{
$txt->insert('end',"$copied_tex[$z]",'tag15');
}
elsif($copied_tex[$z] eq 'S')
{
$txt->insert('end',"$copied_tex[$z]",'tag16');
}
elsif($copied_tex[$z] eq 'T')
{
$txt->insert('end',"$copied_tex[$z]",'tag17');
}
elsif($copied_tex[$z] eq 'V')
{
$txt->insert('end',"$copied_tex[$z]",'tag18');
}
elsif($copied_tex[$z] eq 'W')
{
$txt->insert('end',"$copied_tex[$z]",'tag19');
}
elsif($copied_tex[$z] eq 'Y')
{
$txt->insert('end',"$copied_tex[$z]",'tag20');

}
elsif($copied_tex[$z] eq ' ')
{
$txt->insert('insert', " ");
}
elsif($copied_tex[$z] eq "\n")
{
$txt->insert('end', "\n");
}
}

}


####################################################
sub uuuuuuuuuu{
  my $father = $Wmain;
  my $w1 = $father->Toplevel(-title => "Save selected residues");

  my $outfile = "";
  my $flag = 0;


  my $save_what = "all";
  my $fm = $w1->Frame()->pack(-fill => 'x', -padx => 14, -pady => 8);

  my $row = 0;
  my $lab1 = $fm->Label(-text => "Save all or selected ?")->pack();
  $lab1->grid(-row => $row, -column => 0);
  my $rad1 = $fm->Radiobutton(-text => "all", -variable => \$save_what,
                              -value => "all")->pack();
  $rad1->grid(-row => $row, -column => 1);
  my $rad2 = $fm->Radiobutton(-text => "selected", -variable => \$save_what,
                              -value => "selected")->pack();
  $rad2->grid(-row => $row, -column => 2);

  $row++;

  my $lab2 = $fm->Label(-text => "Output file name ")->pack();
  $lab2->grid(-row => $row, -column => 0);
  my $ent1 = $fm->Entry(qw/-relief sunken -width 26/)->pack();
  $ent1->grid(-row => $row, -column => 1);
  my $but1 = $fm->Button(-text => 'Browse ...')->pack();
  $but1->grid(-row => $row, -column => 2);
  $but1->configure(-command => sub {$ent1->delete(0,'end');
                                    $ent1->insert(0, $w1->getOpenFile()); });

  my ($f0, $b1, $b2) = add_action_button($w1, "Ok", "Cancel");
  $b1->configure( -command => sub{$flag = 1; $outfile = $ent1->get();
                                  $w1->destroy(); } );
  $b2->configure( -command => sub{$w1->destroy(); } );
  $w1->waitWindow();

  if ($flag) { #if press ok
    $outfile =~ s/\s+//g; 
    return unless ($outfile);
    my ($i, $j, $k);

    open(TMP_GI, "> $outfile") || return;
    for ($i=0; $i<$mysite->{protein_no}; $i++) {
      my $p = $mysite->{protein}->[$i];
      next if ( $p->{mask} & $IS_deleted);
      if (  $save_what eq "all" or 
           ($save_what eq "selected" and $p->{mask} & $IS_selected ) ) {
        
        my $des  = $p->{des};
        my $seq1 = "";

        my $len = $mysite->{alignment_len};

        for ($j=0; $j<$len; $j++) {
          next unless ($mysite->{select_flag}->[$j]);
          $seq1 .= substr($p->{aln},$j,1);
        }
        $seq1 =~ s/(.{70})/$1\n/g;
        print TMP_GI "$des\n$seq1\n";
      }
    }
    close(TMP_GI);
  }
}
###############################getting blast result directly####################################################################################
sub blast_n
{

my $mwb;
$mwb=MainWindow->new;
$mwb->geometry( "800x300" );
$mwb->resizable(0,0);


my $frameb= $mwb->Frame () ->pack(
-fill => 'x',
-expand => 1);


$frameb->Label( -text => "This feature helps to read multiple DNA or Protein sequences(FASTA format) from a file and returns the blast result into a file",-font=>'fixed')->pack();
$frameb->Label(-text => "Input file name -")->pack();

my $inputseqb =  $frameb->Entry(-textvariable => \$file1)->pack();

          $frameb->Button(-text => "Browse",
				-bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$file1 =  $frameb->getOpenFile();
                              })->pack(-padx => 20);

         $frameb->Label( -bg => 'grey' , -text => "Output file name -")->pack;
	my $outputseqb = $frameb->Entry(-textvariable => \$file2)->pack();
       $frameb->Button(-text => "Browse",
				-bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$file2 =  $frameb->getOpenFile();
                             })->pack(-padx => 20);
 $frameb->Label( -text => "Type of Blast -")->pack;
my $be = $frameb->BrowseEntry( -variable => \$family)->pack(-padx => 20);
$be->insert('end',blastn);
$be->insert('end',blastp);




 $frameb->Button(-text => "Submit",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => \&submit)->pack;


        
sub submit{



my $selview =  $frameb->Label->pack;

my $selview1 =  $frameb->Label->pack;




my $fileToRead =  $inputseqb->get();
chomp($fileToRead);
my $outfile1=$outputseqb->get();

open (PROTEINFILE, $fileToRead) or die( "Cannot open file : $!" );
$/ = ">";


#Read each FASTA entry and add the sequence titles to @arrayOfNames and the sequences
#to @arrayOfSequences.
my @arrayOfNames = ();
my @arrayOfSequences = ();
while (my $sequenceEntry = <PROTEINFILE>) {
    if ($sequenceEntry eq ">"){
	next;
    }
    my $sequenceTitle = "";
    if ($sequenceEntry =~ m/([^\n]+)/){
	$sequenceTitle = $1;
    }
    else {
	$sequenceTitle = "No title was found!";
    }
    $sequenceEntry =~ s/[^\n]+//;
    push (@arrayOfNames, $sequenceTitle);
    $sequenceEntry =~ s/[^ACDEFGHIKLMNPQRSTVWY]//ig;
    push (@arrayOfSequences, $sequenceEntry);
}
close (PROTEINFILE) or die( "Cannot close file : $!");

#Store the BLAST URL we will be using in $url.
my $url = "http://www.ncbi.nlm.nih.gov/blast/Blast.cgi";

#Create a user agent object of class LWP::UserAgent. The user agent object acts
#like a web browser, and we can use it to send requests for resources on the web.
#The user agent object returns the results of these requests to us in the form
#of a response object.
#In the following statement we are creating the user agent object using the 
#"LWP::UserAgent->new()". We refer to this object using $browser. Thus we have 
#created a virtual web browser that we can access using a name we gave it--$browser.  

my $browser = LWP::UserAgent->new();

#Our virtual web browser has many attributes we can adjust. A list of these attributes
#is available at http://search.cpan.org/author/GAAS/libwww-perl/lib/LWP/UserAgent.pm
#We will change the timeout value of our browser, which is how long the browser
#will wait for a response before timing out (i.e., canceling the request).
#We will set it to 30 seconds.
$browser->timeout(30);

#We have our virtual browser that we want to use to submit BLAST queries. NCBI
#provides information on how to communicate with their BLAST server at
#http://www.ncbi.nlm.nih.gov/BLAST/Doc/urlapi.html
#Briefly, a sequence is sent using our browser, and the BLAST server sends
#back a RID (Request Identifier) and a RTOE (Request Time of Execution). The
#RID is a number that we can use to obtain the BLAST results once the search
#is finished. The RTOE is the predicted number of seconds it will take the
#BLAST server to complete the BLAST search.
#The RID and RTOE are sent as part of a web page to our virtual browser. They
#are formatted as in the following example:
#    <!--QBlastInfoBegin
#        RID = 954517067-8610-1647
#        RTOE = 207
#    QBlastInfoEnd
#    -->
#We can use the matching operator to store the RID and RTOE in variables.

#The next section of code sends sequences to the BLAST server and stores
#the RID and RTOE values in the arrays @arrayOfRID and @arrayOfRTOE.
#The values in these arrays are later used to obtain the results of the BLAST
#searches.


#For each protein sequence send a request to BLAST. The request
#first request sends a request id (RID), which we will store.
my @arrayOfRID = ();
my @arrayOfRTOE = ();
for (my $i = 0; $i < scalar(@arrayOfSequences); $i = $i + 1) {


  print "Sending RID request for sequence " . ($i + 1) . ".\n";
   
    
    #Send a request to the BLAST server. A request contains the information that a normal
    #web browser sends to a server when it makes a request for a particular page. This
    #information includes the URL of the page. In our case we also need to submit the
    #information that the BLAST server expects.
    #The following statement causes our virtual browser to send a request. The results
    #of the request, the response, is stored in $response.
    #The part of the request that the BLAST server sees is the list of attributes and values,
    #starting with DATABASE = > "nr", and ending with CMD => "Put". There are many
    #other options that can be specified. These are described at:
    #http://www.ncbi.nlm.nih.gov/BLAST/Doc/urlapi.html. The most important are: PROGRAM,
    #which we set to "blastp" because we are searching with a protein; QUERY, which
    #we set to $arrayOfSequences[$i]; and CMD, which we set to "Put", which tells 
    #the server we are submitting a search.
    #The HTTP::Request::Common module's POST method takes $url and the list of attributes
    #and values, and makes a request object that is sent using $browser's request method.
    # my $response = $browser->request(POST ($url, [DATABASE => "nr", HITLIST_SIZE => "10",
    my $response = $browser->request(POST ($url, [DATABASE => "pdb", HITLIST_SIZE => "10",
    FILTER => "L", PROGRAM  => "$family", QUERY => $arrayOfSequences[$i], CMD => "Put"]));
    
    #$response is an object, which means it is a collection of values and methods. The different
    #values it contains are described in the Perl documentation:
    #http://search.cpan.org/author/GAAS/libwww-perl/lib/HTTP/Response.pm
    #We will use the "is_success()" method, which returns true if a response was received
    #from the BLAST server.
    if ($response->is_success()) {
	
	#The "as_string()" method returns the contents of the response (the web page)
	#as a string. We will use the matching operator to find the RID and RTOE in this
	#string, and we will store these values in an array.
	my $result = $response->as_string();
	if ($result =~ m/QBlastInfoBegin\s*RID\s=\s([^\s]+)\s*RTOE\s=\s(\d+)\s*QBlastInfoEnd/) {
            
	    print "A RID was received for sequence " . ($i + 1) . ".\n";
	    push (@arrayOfRID, $1);
	    push (@arrayOfRTOE, $2);
            my $minutes=$2/60;
            
 
            print "Estimated time of completion is $2 seconds or $minutes minutes.\n";
	}
	else {
	    #if for some reason we cannot find the RID and RTOE values we will store an error
	    #message instead.
            
	    print "The response received for sequence " . ($i + 1) . " was not understood.\n";
	    push (@arrayOfRID, "The response received for $arrayOfNames[$i] was not understood.");
	    push (@arrayOfRTOE, "The response received for $arrayOfNames[$i] was not understood.");
	}
    }
    else {
	#If no response was received from the BLAST server we will print a message on the
	#screen and store error messages instead of the RID and RTOE.
       
	print "No response was received for sequence " . ($i + 1) . ".\n";
	push (@arrayOfRID, "No response was received for $arrayOfNames[$i].");
	push (@arrayOfRTOE, "No response was received for $arrayOfNames[$i].");
    }
    #If sequences are submitted very rapidly to the BLAST server, NCBI may block the submitting
    #site. The "sleep" statement stops execution for the specified number of seconds. After the
    #pause, the next sequence is submitted.
    
    print "Pausing after submission.\n";
    sleep(5);
}

#We have submitted the sequences to BLAST and have received RIDs and RTOEs, or error 
#messages. Now we need to ask the BLAST server for the formatted results of the
#BLAST searches we submitted.
#To do this we will go through the RID and RTOE values obtained for each sequence.
#The script will sleep for the number of seconds specified by the RTOE value, since
#the results probably won't be ready until the RTOE time has elapsed. We will use
#$totalTimeSlept to store how much time has been spent sleeping in total. If 
#$totalTimeSlept is greater than the RTOE, the script pauses for 3 seconds.

open(OUTFILE, ">$outfile1") or die ("Cannot open file : $!");
print(OUTFILE "Results of automated BLAST query.\n");
print(OUTFILE "---------------------------------\n");
my $totalTimeSlept = 0;
my $resultFound = 0;
for (my $i = 0; $i < scalar(@arrayOfRID); $i = $i + 1) {
    
    #Recall that if we had a problem obtaining the RID or RTOE from the BLAST server
    #we added a message to @arrayOfRID and @arrayOfRTOE in place of the numbers.
    #first make sure that the RTOE value isn't an error message. We can use
    #the regular expression ^\d+$ which only matches entries that contain
    #all digits. If the entry only contains numbers, execution continues with 
    #the else statement, otherwise the message in $arrayOfRTOE is written
    #to our results file.  
    if (!($arrayOfRTOE[$i] =~ m/^\d+$/)) {
	print(OUTFILE "Results for $arrayOfNames[$i].\n" . 
	      $arrayOfRTOE[$i] . "\n" . "---------------------------------\n");
    }
    else {
	if ($arrayOfRTOE[$i] > $totalTimeSlept) {
	    print "Pausing before requesting results.\n";
	    sleep($arrayOfRTOE[$i] - $totalTimeSlept);
	    $totalTimeSlept = $totalTimeSlept + ($arrayOfRTOE[$i] - $totalTimeSlept);
	}
	else {
            
	    print "Pausing before requesting results.\n";
	    sleep(3);
	}
	
	#Now the results should be ready. To request the results using the RID, we need
	#to send two values to the BLAST server in the list of attributes and values.
	#RID => $arrayOfRID[$i] sends the RID number to the server, and CMD => "Get"
	#tells the server that we are requesting the results for this RID. Many other
	#options can be passed to the server to control what information is returned.
	#See http://www.ncbi.nlm.nih.gov/BLAST/Doc/urlapi.html
	#When the BLAST server receives the request with CMD => "Get", it checks to 
	#see if the results are ready. If they are not, the server sends a page 
	#containing the following text:
        #  <!--QBlastInfoBegin
        #       Status=WAITING
        #      QBlastInfoEnd
        #  -->
	#
	#If the results are ready, they are sent along with the following text:
	#    <!--QBlastInfoBegin
        #        Status=READY
        #        QBlastInfoEnd
        #    -->
	#When the WAITING message is in the response, the script pauses for 10 seconds
	#and then asks for the results again using the while loop. When the
	#READY message is received in the response, the response is added to a file,
	#and $resultFound is set to 1 so that the while loop exited.
	while ($resultFound == 0) {
             
	    print "Requesting results for sequence " . ($i + 1) . ".\n";
	    my $response = $browser->request(POST ($url, [RID => $arrayOfRID[$i], FORMAT_TYPE => "Text",
	       CMD => "Get"]));
	    if ($response->is_success()) {
		my $result = $response->as_string();
		if ($result =~ m/QBlastInfoBegin\s*Status=READY\s*QBlastInfoEnd/) {
                    
		    print "The results were received for sequence " . ($i + 1) . ".\n";

                     
                    $selview1 -> configure(-text => "Writing the results to $outfile1\n"); 
		    print "Writing the results to $outfile1\n";
		    print(OUTFILE "Results for $arrayOfNames[$i].\n" . 
			  $result . "\n" . "---------------------------------\n");
		    
		    $resultFound = 1;
		}
		elsif ($result =~ m/QBlastInfoBegin\s*Status=WAITING\s*QBlastInfoEnd/) {
                     
		    print "The results are not ready for sequence " . ($i + 1) . ".\n";
                     
		    print "Pausing before requesting again.\n";
		    sleep(10);
		}
	    }
	    else {
                
		print "No response received when requesting results for sequence " . ($i + 1) . ".\n";
               
		print(OUTFILE "No result was obtained for $arrayOfNames[$i].\n" . 
		     "The RID for the results is $arrayOfRID[$i].\n" .
		      "---------------------------------\n");
		$resultFound = 1;
	    }
	} #end of while loop
    }
    $resultFound = 0;
}}
	
#Close the filehandle.    
close(OUTFILE) or die ("Cannot close file : $!");

print "Open $variable to view the results.\n";
my $msgbox=$mwb->messageBox(-message=>" Check out the notepad", -type=>'ok');
}



########################################################################################################


###########################################################################################################################################
sub genscan{

my $mwg;
$mwg=MainWindow->new;
$mwg->geometry( "600x300" );
$mwg->resizable(0,0);

my $frameb= $mwg->Frame () ->pack(
-fill => 'x',
-expand => 1);
$frameb->Label( -text => "This feature helps to read genomic sequence and returns the resulting genes into a file",-width=>90,-font=>'fixed')->pack();
$frameb->Label(-text => "Input file name -",-bg => 'grey')->pack();

my $inputseqg =  $frameb->Entry(-textvariable => \$file12)->pack();

          $frameb->Button(-text => "Browse",
				-bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$file12 =  $frameb->getOpenFile();
                              })->pack(-padx => 20);

         $frameb->Label( -bg => 'grey' , -text => "Output file name 1-")->pack;
	my $outputseqg = $frameb->Entry(-textvariable => \$fileg)->pack();
       $frameb->Button(-text => "Browse",
				-bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$fileg =  $frameb->getOpenFile();
                             })->pack(-padx => 20);
 $frameb->Label( -bg => 'grey' , -text => "Output file name 2-")->pack;
	my $outputseqg2 = $frameb->Entry(-textvariable => \$fileg2)->pack();
       $frameb->Button(-text => "Browse",
				-bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$fileg2 =  $frameb->getOpenFile();
                             })->pack(-padx => 20);
        $frameb->Button(-text => "Submit",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => \&submit2)->pack;

        
sub submit2{



my $selview1 =  $frameb->Label->pack;
my $selview2 =  $frameb->Label->pack;
my $selview3 =  $frameb->Label->pack;

my $fileToRead =  $inputseqg->get();
my $outfileg=$outputseqg->get();
my $outfileg2=$outputseqg2->get();
$selview1 -> configure(-text => "Please wait...The programme is running\n"); 


open (DNAFILE, $fileToRead) or die( "Cannot open file : $!" );
$/ = undef;

my $directStrand = <DNAFILE>;
my $sequenceTitle = "";
if ($directStrand =~ m/(>[^\n]+)/){
    $sequenceTitle = $1;
    $sequenceTitle =~ s/>//;
}
else {
    die( "A FASTA sequence title was not found." );
} 

#Once you are done with a file, close the filehandle.
close (DNAFILE) or die( "Cannot close file : $!"); 

#Store the Genscan URL we will be using in $url.
my $url = "http://genes.mit.edu/cgi-bin/genscanw_py.cgi";

#First declare some variables for using Genscan.
my $organism = "Arabidopsis";
my $suboptimalExonCutoff = "1.00";
my $printOptions = "Predicted CDS and peptides";
my $email = ""; #an email address is not required. 

#Create a user agent object of class LWP::UserAgent. The user agent object acts
#like a web browser, and we can use it to send requests for resources on the web.
#The user agent object returns the results of these requests to us in the form
#of a response object.
#In the following statement we are creating the user agent object using the
#"LWP::UserAgent->new()". We refer to this object using $browser. Thus we have
#created a virtual web browser that we can access using a name we gave it--$browser. 
my $browser = LWP::UserAgent->new(); 

#Our virtual web browser has many attributes we can adjust. A list of these attributes
#is available at http://search.cpan.org/author/GAAS/libwww-perl/lib/LWP/UserAgent.pm
#We will change the timeout value of our browser, which is how long the browser
#will wait for a response before timing out (i.e., cancelling the request).
#We will set it to 30 seconds.
$browser->timeout(30); 

#Send a request to the Genscan server. A request contains the information that a normal
#web browser sends to a server when it makes a request for a particular page. This
#information includes the URL of the page. In our case we also need to submit the
#information that the Genscan server expects.
#The following statement causes our virtual browser to send a request. The results
#of the request, the response, is stored in $response.
#The part of the request that the Genscan server sees is the list of attributes and values,
#starting with -o = > $organism, and ending with -a => $email. These attributes were
#identified by reading the page source of the Genscan web site at
#http://genes.mit.edu/oldGENSCAN.html
#The HTTP::Request::Common module's POST method takes $url and the list of attributes
#and values, and makes a request object that is sent using $browser's request method.
print "Sending a request to the Genscan server.\n";
my $response = $browser->request(POST ($url, [-o => $organism, -e => $suboptimalExonCutoff,
    -n => $sequenceTitle, -p => $printOptions, -s => $directStrand, -a => $email])); 

#$response is an object, which means it is a collection of values and methods. The different
#values it contains are described in the Perl documentation:
#http://search.cpan.org/author/GAAS/libwww-perl/lib/HTTP/Response.pm
#We will use the "is_success()" method, which returns true if a response was received
#from the Genscan server. #The "as_string()" method returns the contents of the response (the web page) as a string.
my $result = "";
if ($response->is_success()) {
    print "A response was received from the Genscan server.\n";
    $result = $response->as_string();
}
else {
    die ("A response was not received from the Genscan server.\n");
} 

#Now parse the results and store each entry in @arrayOfTranslations. If you examine
#the output of Genscan in a web browser you will se that each predicted translation
#begins with a FASTA title like the following:
#>gi|GENSCAN_predicted_peptide_1|519_aa
#We can use the matching operator to separate the predicted translations from the
#rest of the html output.
my @arrayOfTranslations = ();
while ($result =~ m/(>.*?\|GENSCAN_predicted_peptide_[^>]+)/g) {	
    my $entry = $1; 

    #get rid of extra blank spaces
    $entry =~ s/\n\n/\n/g;
    $entry = $entry . "\n";
    push (@arrayOfTranslations, $entry);
} 

#Write the results to a file.
$selview2 -> configure(-text => "Writing results to $outfileg\n"); 
print "Writing results to $outfileg\n";
open(OUTFILE, ">$outfileg") or die ("Cannot open file : $!");
print (OUTFILE "Genscan results for \"$sequenceTitle\".\n");
print (OUTFILE "Length = " . length($directStrand) . " bp.\n");

if (scalar(@arrayOfTranslations != 0)) {
    print (OUTFILE "Genscan returned " . scalar(@arrayOfTranslations) . " translations:\n");
}
else {
    print (OUTFILE "Genscan returned no translations.\n");
}
foreach (@arrayOfTranslations) {
    print (OUTFILE "$_\n");
} 

#Close the filehandle.   
close(OUTFILE) or die ("Cannot close file : $!"); 

#ALTERNATE (BETTER??) OUTPUT CODE
#Now parse the results and store each entry in @arrayOfTranslations. If you examine
#the output of Genscan in a web browser you will see that each predicted translation
#begins with a FASTA title like the following:
#>gi|GENSCAN_predicted_peptide_1|519_aa
#We can use the matching operator to separate the predicted translations from the
#rest of the html output.
my @arrayOfTranslations = ();
while ($result =~ m/(GENSCAN_predicted_peptide_[^>]+)/g) {
  my $entry = $1;
  $entry =~ s/\n\n/\n/g;
  $entry = $entry . "\n";
  push(@arrayOfTranslations, $entry);
} 
$selview3 -> configure(-text => "Writing results to $outfileg2\n"); 
print "Writing results to $outfileg2\n";
open(OUTFILE, ">$outfileg2") or die("Could not open output file: $outfileg2");
print (OUTFILE "Genscan results for \"$sequenceTitle\".\n");
print (OUTFILE "Length = " . length($directStrand) . " bp.\n");

if (scalar(@arrayOfTranslations) != 0) {
  print (OUTFILE "Genscan returned " . scalar(@arrayOfTranslations) . " translations.\n");
  for (my $i = 0; $i < scalar(@arrayOfTranslations); $i += 1) {
    print (OUTFILE ">$arrayOfTranslations[$i]\n");
  }
}
else {
  print (OUTFILE "Genscan returned no translations.\n");
}}


#Close the filehandle.   
close(OUTFILE) or die ("Cannot close file : $!"); 
}
###############################################################################################################################


###############################################################################################################

sub embltofastawin
{
	my $tl = $main_window->Toplevel(-bg => 'grey');
        $tl->title("EMBL to FASTA");
        $tl->geometry("350x250");
        $tl->raise();
        $tl->Label( -bg => 'grey' , -text => "EMBL to FASTA accepts a EMBL file as
input and returns the entire DNA sequence
in FASTA format. Use this program when you
wish to quickly remove all of the non-DNA
sequence information from a EMBL file.")->pack;
        $tl->Label( -bg => 'grey' , -text => "Input file name -")->pack;
        my $inputseqwin = $tl->Entry(-textvariable => \$filewin)->pack();
        $tl->Button(-text => "Browse",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$filewin = $tl->getOpenFile();
                              })->pack(-padx => 20);
        $tl->Label( -bg => 'grey' , -text => "Output file name -")->pack;
	my $outputseqwin = $tl->Entry(-textvariable => \$file2win)->pack();
        $tl->Button(-text => "Browse",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$file2win = $tl->getSaveFile();
                              })->pack(-padx => 20);
        $tl->Button(-text => "Submit",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => \&convertwin)->pack;
        $tl->Button(-text => "Close",
				 -bg => 'grey',
				 -foreground => 'black',
                -command => sub { $tl->withdraw })->pack;
	sub convertwin
	{
	 my $tl2 = $tl->Toplevel(-bg => 'grey');
         $tl2->geometry("300x150");

         my $infilewin = $inputseqwin->get();

         my $outfilewin = $outputseqwin->get();

         # create one SeqIO object to read in,and another to write out
         my $seq_in = Bio::SeqIO->new('-file' => "<$infilewin",
                                      '-format' => embl);
         my $seq_out = Bio::SeqIO->new('-file' => ">$outfilewin",
                                       '-format' => fasta);

         # write each entry in the input file to the output file
         while (my $inseq = $seq_in->next_seq) {
              $seq_out->write_seq($inseq);}

	 $tl2->Label( -bg => 'grey' , -text=>"Output sequence saved in $outfilewin")->pack();
         $tl2->Button(-text => "Close",
				 -bg => 'brown',
				 -foreground => 'black',
                -command => sub { $tl2->withdraw })->pack;
	}


}
####################################################################################
sub clustalwtofasta
{
	my $tl = $main_window->Toplevel(-bg => 'grey');
        $tl->title("EMBL to FASTA");
        $tl->geometry("350x250");
        $tl->raise();
        $tl->Label( -bg => 'grey' , -text => "FASTA to Pfam accepts an alignment file in Fasta format
as input and returns the entire alignment in Pfam format.")->pack;
        $tl->Label( -bg => 'grey' , -text => "Input file name -")->pack;
        my $inputseqwin = $tl->Entry(-textvariable => \$filewin)->pack();
        $tl->Button(-text => "Browse",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$filewin = $tl->getOpenFile();
                              })->pack(-padx => 20);
        $tl->Label( -bg => 'grey' , -text => "Output file name -")->pack;
	my $outputseqwin = $tl->Entry(-textvariable => \$file2win)->pack();
        $tl->Button(-text => "Browse",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$file2win = $tl->getSaveFile();
                              })->pack(-padx => 20);
        $tl->Button(-text => "Submit",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => \&convertwin1)->pack;
        $tl->Button(-text => "Close",
				 -bg => 'grey',
				 -foreground => 'black',
                -command => sub { $tl->withdraw })->pack;
	sub convertwin1
	{
	 my $tl2 = $tl->Toplevel(-bg => 'grey');
         $tl2->geometry("300x150");

         my $infilewin = $inputseqwin->get();

         my $outfilewin = $outputseqwin->get();

         # create one SeqIO object to read in,and another to write out
         my $seq_in = Bio::SeqIO->new('-file' => "<$infilewin",
                                      '-format' => clustalw);
         my $seq_out = Bio::SeqIO->new('-file' => ">$outfilewin",
                                       '-format' => msf);

         # write each entry in the input file to the output file
         while (my $inseq = $seq_in->next_seq) {
              $seq_out->write_seq($inseq);}

	 $tl2->Label( -bg => 'grey' , -text=>"Output sequence saved in $outfilewin")->pack();
         $tl2->Button(-text => "Close",
				 -bg => 'brown',
				 -foreground => 'black',
                -command => sub { $tl2->withdraw })->pack;
	}


}
###########################################################################################
sub cwtopfam
{
	my $tl = $main_window->Toplevel(-bg => 'grey');
        $tl->title("EMBL to FASTA");
        $tl->geometry("350x250");
        $tl->raise();
        $tl->Label( -bg => 'grey' , -text => "FASTA to Pfam accepts an alignment file in Fasta format
as input and returns the entire alignment in Pfam format.")->pack;
        $tl->Label( -bg => 'grey' , -text => "Input file name -")->pack;
        my $inputseqwin = $tl->Entry(-textvariable => \$filewin)->pack();
        $tl->Button(-text => "Browse",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$filewin = $tl->getOpenFile();
                              })->pack(-padx => 20);
        $tl->Label( -bg => 'grey' , -text => "Output file name -")->pack;
	my $outputseqwin = $tl->Entry(-textvariable => \$file2win)->pack();
        $tl->Button(-text => "Browse",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$file2win = $tl->getSaveFile();
                              })->pack(-padx => 20);
        $tl->Button(-text => "Submit",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => \&convertwin2)->pack;
        $tl->Button(-text => "Close",
				 -bg => 'grey',
				 -foreground => 'black',
                -command => sub { $tl->withdraw })->pack;
	sub convertwin2
	{
	 my $tl2 = $tl->Toplevel(-bg => 'grey');
         $tl2->geometry("300x150");

         my $infilewin = $inputseqwin->get();

         my $outfilewin = $outputseqwin->get();

         # create one SeqIO object to read in,and another to write out
         my $seq_in = Bio::SeqIO->new('-file' => "<$infilewin",
                                      '-format' => clustalw);
         my $seq_out = Bio::SeqIO->new('-file' => ">$outfilewin",
                                       '-format' => pfam);

         # write each entry in the input file to the output file
         while (my $inseq = $seq_in->next_seq) {
              $seq_out->write_seq($inseq);}

	 $tl2->Label( -bg => 'grey' , -text=>"Output sequence saved in $outfilewin")->pack();
         $tl2->Button(-text => "Close",
				 -bg => 'brown',
				 -foreground => 'black',
                -command => sub { $tl2->withdraw })->pack;
	}


}
###################################################################################
sub genbanktofasta
{
	my $tl = $main_window->Toplevel(-bg => 'grey');
        $tl->title("EMBL to FASTA");
        $tl->geometry("350x250");
        $tl->raise();
        $tl->Label( -bg => 'grey' , -text => "GenBank to FASTA accepts a GenBank file as
input and returns the entire DNA sequence
in FASTA format. Use this program when you
wish to quickly remove all of the non-DNA
sequence information from a GenBank file.")->pack;
        $tl->Label( -bg => 'grey' , -text => "Input file name -")->pack;
        my $inputseqwin = $tl->Entry(-textvariable => \$filewin)->pack();
        $tl->Button(-text => "Browse",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$filewin = $tl->getOpenFile();
                              })->pack(-padx => 20);
        $tl->Label( -bg => 'grey' , -text => "Output file name -")->pack;
	my $outputseqwin = $tl->Entry(-textvariable => \$file2win)->pack();
        $tl->Button(-text => "Browse",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => sub{$file2win = $tl->getSaveFile();
                              })->pack(-padx => 20);
        $tl->Button(-text => "Submit",
				 -bg => 'grey',
				 -foreground => 'black',
        		-command => \&convertwin3)->pack;
        $tl->Button(-text => "Close",
				 -bg => 'grey',
				 -foreground => 'black',
                -command => sub { $tl->withdraw })->pack;
	sub convertwin3
	{
	 my $tl2 = $tl->Toplevel(-bg => 'grey');
         $tl2->geometry("300x150");

         my $infilewin = $inputseqwin->get();

         my $outfilewin = $outputseqwin->get();

         # create one SeqIO object to read in,and another to write out
         my $seq_in = Bio::SeqIO->new('-file' => "<$infilewin",
                                      '-format' => genbank);
         my $seq_out = Bio::SeqIO->new('-file' => ">$outfilewin",
                                       '-format' => fasta);

         # write each entry in the input file to the output file
         while (my $inseq = $seq_in->next_seq) {
              $seq_out->write_seq($inseq);}

	 $tl2->Label( -bg => 'grey' , -text=>"Output sequence saved in $outfilewin")->pack();
         $tl2->Button(-text => "Close",
				 -bg => 'brown',
				 -foreground => 'black',
                -command => sub { $tl2->withdraw })->pack;
	}


}


###########################Rasmol######################################
#######################################################################

sub rasmol
{

my $rresponse=$main_window->messageBox(-message=>"Sorry, Not Included in trial version");

}

