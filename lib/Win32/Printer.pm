#line 1 "Win32/Printer.pm"
#------------------------------------------------------------------------------#
# Win32::Printer                                                               #
# V 0.9.1 (2008-04-28)                                                         #
# Copyright (C) 2003-2005 Edgars Binans                                        #
#------------------------------------------------------------------------------#

package Win32::Printer;

use 5.006;
use strict;
use warnings;

use Carp;

require Exporter;

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD $_debuglevel $_numcroaked );

$VERSION = '0.9.1';

@ISA = qw( Exporter );

@EXPORT = qw(

	EB_EMF EB_25MATRIX EB_25INTER EB_25IND EB_25IATA EB_27 EB_39STD EB_39EXT
	EB_39DUMB EB_93 EB_128SMART EB_128A EB_128B EB_128C EB_128SHFT EB_128EAN
	EB_EAN13 EB_UPCA EB_EAN8 EB_UPCE EB_ISBN EB_ISBN2 EB_ISSN EB_AD2 EB_AD5
	EB_CHK EB_TXT

	LETTER LETTERSMALL TABLOID LEDGER LEGAL STATEMENT EXECUTIVE A3 A4
	A4SMALL A5 B4 B5 FOLIO QUARTO IN_10X14 IN_11X17 NOTE ENV_9 ENV_10
	ENV_11 ENV_12 ENV_14 CSHEET DSHEET ESHEET ENV_DL ENV_C5 ENV_C3 ENV_C4
	ENV_C6 ENV_C65 ENV_B4 ENV_B5 ENV_B6 ENV_ITALY ENV_MONARCH ENV_PERSONAL
	FANFOLD_US FANFOLD_STD_GERMAN FANFOLD_LGL_GERMAN ISO_B4
	JAPANESE_POSTCARD IN_9X11 IN_10X11 IN_15X11 ENV_INVITE RESERVED_48
	RESERVED_49 LETTER_EXTRA LEGAL_EXTRA TABLOID_EXTRA A4_EXTRA
	LETTER_TRANSVERSE A4_TRANSVERSE LETTER_EXTRA_TRANSVERSE A_PLUS B_PLUS
	LETTER_PLUS A4_PLUS A5_TRANSVERSE B5_TRANSVERSE A3_EXTRA A5_EXTRA
	B5_EXTRA A2 A3_TRANSVERSE A3_EXTRA_TRANSVERSE

	PORTRAIT LANDSCAPE VERTICAL HORIZONTAL

	ALLPAGES SELECTION PAGENUMS NOSELECTION NOPAGENUMS PRINTTOFILE
	PRINTSETUP NOWARNING DISABLEPRINTTOFILE HIDEPRINTTOFILE NONETWORKBUTTON

	NOUPDATECP TOP LEFT UPDATECP RIGHT VCENTER BOTTOM WORDBREAK BASELINE
	SINGLELINE EXPANDTABS NOCLIP EXTERNALLEADING CALCRECT INTERNAL
	EDITCONTROL PATH_ELLIPSIS END_ELLIPSIS MODIFYSTRING RTLREADING
	WORD_ELLIPSIS CENTER JUSTIFY UTF8

	PS_SOLID PS_DASH PS_DOT PS_DASHDOT PS_DASHDOTDOT PS_NULL PS_INSIDEFRAME
	PS_JOIN_ROUND PS_ENDCAP_ROUND PS_ENDCAP_SQUARE PS_ENDCAP_FLAT
	PS_JOIN_BEVEL PS_JOIN_MITER

	HS_HORIZONTAL HS_VERTICAL HS_FDIAGONAL HS_BDIAGONAL HS_CROSS
	HS_DIAGCROSS

	ALTERNATE WINDING

	CR_OFF CR_AND CR_OR CR_XOR CR_DIFF CR_COPY

	ANSI DEFAULT SYMBOL SHIFTJIS HANGEUL GB2312 CHINESEBIG5 OEM JOHAB HEBREW
	ARABIC GREEK TURKISH VIETNAMESE THAI EASTEUROPE RUSSIAN MAC BALTIC

	BIN_ONLYONE BIN_LOWER BIN_MIDDLE BIN_MANUAL BIN_ENVELOPE BIN_ENVMANUAL
	BIN_AUTO BIN_TRACTOR BIN_SMALLFMT BIN_LARGEFMT BIN_LARGECAPACITY
	BIN_CASSETTE BIN_FORMSOURCE

	MONOCHROME COLOR

	DRIVERVERSION HORZSIZE VERTSIZE HORZRES VERTRES BITSPIXEL PLANES
	NUMBRUSHES NUMPENS NUMFONTS NUMCOLORS CURVECAPS LINECAPS POLYGONALCAPS
	TEXTCAPS CLIPCAPS RASTERCAPS ASPECTX ASPECTY ASPECTXY LOGPIXELSX
	LOGPIXELSY SIZEPALETTE NUMRESERVED COLORRES PHYSICALWIDTH
	PHYSICALHEIGHT PHYSICALOFFSETX PHYSICALOFFSETY SCALINGFACTORX
	SCALINGFACTORY

        PSI_BEGINSTREAM PSI_PSADOBE PSI_PAGESATEND PSI_PAGES PSI_DOCNEEDEDRES
        PSI_DOCSUPPLIEDRES PSI_PAGEORDER PSI_ORIENTATION PSI_BOUNDINGBOX
        PSI_PROCESSCOLORS PSI_COMMENTS PSI_BEGINDEFAULTS PSI_ENDDEFAULTS
        PSI_BEGINPROLOG PSI_ENDPROLOG PSI_BEGINSETUP PSI_ENDSETUP PSI_TRAILER
        PSI_EOF PSI_ENDSTREAM PSI_PROCESSCOLORSATEND PSI_PAGENUMBER
        PSI_BEGINPAGESETUP PSI_ENDPAGESETUP PSI_PAGETRAILER PSI_PLATECOLOR
        PSI_SHOWPAGE PSI_PAGEBBOX PSI_ENDPAGECOMMENTS PSI_VMSAVE PSI_VMRESTORE

	FIF_BMP FIF_ICO FIF_JPEG FIF_JNG FIF_KOALA FIF_LBM FIF_IFF FIF_MNG
	FIF_PBM FIF_PBMRAW FIF_PCD FIF_PCX FIF_PGM FIF_PGMRAW FIF_PNG FIF_PPM
	FIF_PPMRAW FIF_RAS FIF_TARGA FIF_TIFF FIF_WBMP FIF_PSD FIF_CUT FIF_XBM
	FIF_XPM FIF_DDS FIF_GIF

	BMP_DEFAULT BMP_SAVE_RLE JPEG_DEFAULT JPEG_QUALITYSUPERB
	JPEG_QUALITYGOOD JPEG_QUALITYNORMAL JPEG_QUALITYAVERAGE JPEG_QUALITYBAD
	PNM_DEFAULT PNM_SAVE_RAW PNM_SAVE_ASCII TIFF_DEFAULT TIFF_CMYK
	TIFF_PACKBITS TIFF_DEFLATE TIFF_ADOBE_DEFLATE TIFF_NONE TIFF_CCITTFAX3
	TIFF_CCITTFAX4TIFF_LZW

      );

@EXPORT_OK = qw( );

require XSLoader;
XSLoader::load('Win32::Printer', $VERSION);

#------------------------------------------------------------------------------#

sub _carp {
  if (!defined($_debuglevel)) { $_debuglevel = 0; }
  my $arg = shift;
  if ($_debuglevel == 1) {
    croak $arg, "(Died on warning!)";
  } else {
    carp $arg;
  }
}

sub _croak {
  if (!defined($_debuglevel)) { $_debuglevel = 0; }
  my $arg = shift;
  if ($_debuglevel == 2) {
    carp $arg, "(Warned on error!)";
  } else {
    croak $arg;
  }
}

#------------------------------------------------------------------------------#

sub AUTOLOAD {

  my $constname = $AUTOLOAD;
  $constname =~ s/.*:://;

  _croak "Unknown Win32::Printer macro $constname.\n";
  return undef;

}

#------------------------------------------------------------------------------#

# "ebbl" modes
sub EB_25MATRIX			{ 0x00000001; }
sub EB_25INTER			{ 0x00000002; }
sub EB_25IND			{ 0x00000004; }
sub EB_25IATA			{ 0x00000008; }
sub EB_27			{ 0x00000010; }
sub EB_39STD			{ 0x00000020; }
sub EB_39EXT			{ 0x00000040; }
sub EB_39DUMB			{ 0x00000080; }
sub EB_93			{ 0x00000100; }
sub EB_128SMART			{ 0x00000200; }
sub EB_128A			{ 0x00000400; }
sub EB_128B			{ 0x00000800; }
sub EB_128C			{ 0x00001000; }
sub EB_128SHFT			{ 0x00002000; }
sub EB_128EAN			{ 0x00004000; }
sub EB_EAN13			{ 0x00008000; }
sub EB_UPCA			{ 0x00010000; }
sub EB_EAN8			{ 0x00020000; }
sub EB_UPCE			{ 0x00040000; }
sub EB_ISBN			{ 0x00080000; }
sub EB_ISBN2			{ 0x00100000; }
sub EB_ISSN			{ 0x00200000; }
sub EB_AD2			{ 0x00400000; }
sub EB_AD5			{ 0x00800000; }
sub EB_CHK			{ 0x01000000; }
sub EB_TXT			{ 0x02000000; }

sub EB_EMF			{ 0x80000000; }

sub FIF_UNKNOWN			{ -1; }
sub FIF_BMP			{ 0; }
sub FIF_ICO			{ 1; }
sub FIF_JPEG			{ 2; }
sub FIF_JNG			{ 3; }
sub FIF_KOALA			{ 4; }
sub FIF_LBM			{ 5; }
sub FIF_IFF			{ FIF_LBM; }
sub FIF_MNG			{ 6; }
sub FIF_PBM			{ 7; }
sub FIF_PBMRAW			{ 8; }
sub FIF_PCD			{ 9; }
sub FIF_PCX			{ 10; }
sub FIF_PGM			{ 11; }
sub FIF_PGMRAW			{ 12; }
sub FIF_PNG			{ 13; }
sub FIF_PPM			{ 14; }
sub FIF_PPMRAW			{ 15; }
sub FIF_RAS			{ 16; }
sub FIF_TARGA			{ 17; }
sub FIF_TIFF			{ 18; }
sub FIF_WBMP			{ 19; }
sub FIF_PSD			{ 20; }
sub FIF_CUT			{ 21; }
sub FIF_XBM			{ 22; }
sub FIF_XPM			{ 23; }
sub FIF_DDS			{ 24; }
sub FIF_GIF			{ 25; }

sub BMP_DEFAULT			{ 0; }
sub BMP_SAVE_RLE		{ 1; }
sub CUT_DEFAULT			{ 0; }
sub DDS_DEFAULT			{ 0; }
sub GIF_DEFAULT			{ 0; }
sub ICO_DEFAULT			{ 0; }
sub ICO_MAKEALPHA		{ 1; }
sub IFF_DEFAULT			{ 0; }
sub JPEG_DEFAULT		{ 0; }
sub JPEG_FAST			{ 1; }
sub JPEG_ACCURATE		{ 2; }
sub JPEG_QUALITYSUPERB		{ 0x80; }
sub JPEG_QUALITYGOOD		{ 0x100; }
sub JPEG_QUALITYNORMAL		{ 0x200; }
sub JPEG_QUALITYAVERAGE		{ 0x400; }
sub JPEG_QUALITYBAD		{ 0x800; }
sub KOALA_DEFAULT		{ 0; }
sub LBM_DEFAULT			{ 0; }
sub MNG_DEFAULT			{ 0; }
sub PCD_DEFAULT			{ 0; }
sub PCD_BASE			{ 1; }
sub PCD_BASEDIV4		{ 2; }
sub PCD_BASEDIV16		{ 3; }
sub PCX_DEFAULT			{ 0; }
sub PNG_DEFAULT			{ 0; }
sub PNG_IGNOREGAMMA		{ 1; }
sub PNM_DEFAULT			{ 0; }
sub PNM_SAVE_RAW		{ 0; }
sub PNM_SAVE_ASCII		{ 1; }
sub PSD_DEFAULT			{ 0; }
sub RAS_DEFAULT			{ 0; }
sub TARGA_DEFAULT		{ 0; }
sub TARGA_LOAD_RGB888		{ 1; }
sub TIFF_DEFAULT		{ 0; }
sub TIFF_CMYK			{ 0x0001; }
sub TIFF_PACKBITS		{ 0x0100; }
sub TIFF_DEFLATE		{ 0x0200; }
sub TIFF_ADOBE_DEFLATE		{ 0x0400; }
sub TIFF_NONE			{ 0x0800; }
sub TIFF_CCITTFAX3		{ 0x1000; }
sub TIFF_CCITTFAX4		{ 0x2000; }
sub TIFF_LZW			{ 0x4000; }
sub WBMP_DEFAULT		{ 0; }
sub XBM_DEFAULT			{ 0; }
sub XPM_DEFAULT			{ 0; }

# Print dialog
sub ALLPAGES			{ 0x00000000; }
sub SELECTION			{ 0x00000001; }
sub PAGENUMS			{ 0x00000002; }
sub NOSELECTION			{ 0x00000004; }
sub NOPAGENUMS			{ 0x00000008; }
sub COLLATE			{ 0x00000010; }
sub PRINTTOFILE			{ 0x00000020; }
sub PRINTSETUP			{ 0x00000040; }
sub NOWARNING			{ 0x00000080; }
sub RETURNDC			{ 0x00000100; }
sub RETURNIC			{ 0x00000200; }
sub RETURNDEFAULT		{ 0x00000400; }
sub SHOWHELP			{ 0x00000800; }
sub ENABLEPRINTHOOK		{ 0x00001000; }
sub ENABLESETUPHOOK		{ 0x00002000; }
sub ENABLEPRINTTEMPLATE		{ 0x00004000; }
sub ENABLESETUPTEMPLATE		{ 0x00008000; }
sub ENABLEPRINTTEMPLATEHANDLE	{ 0x00010000; }
sub ENABLESETUPTEMPLATEHANDLE	{ 0x00020000; }
sub USEDEVMODECOPIES		{ 0x00040000; }
sub USEDEVMODECOPIESANDCOLLATE	{ 0x00040000; }
sub DISABLEPRINTTOFILE		{ 0x00080000; }
sub HIDEPRINTTOFILE		{ 0x00100000; }
sub NONETWORKBUTTON		{ 0x00200000; }

# Paper source bin
sub BIN_ONLYONE			{ 1; }
sub BIN_LOWER			{ 2; }
sub BIN_MIDDLE			{ 3; }
sub BIN_MANUAL			{ 4; }
sub BIN_ENVELOPE		{ 5; }
sub BIN_ENVMANUAL		{ 6; }
sub BIN_AUTO			{ 7; }
sub BIN_TRACTOR			{ 8; }
sub BIN_SMALLFMT		{ 9; }
sub BIN_LARGEFMT		{ 10; }
sub BIN_LARGECAPACITY		{ 11; }
sub BIN_CASSETTE		{ 14; }
sub BIN_FORMSOURCE		{ 15; }

# Printer output color setting
sub MONOCHROME 			{ 1; }
sub COLOR			{ 2; }

# Device caps
sub DRIVERVERSION		{ 0; }
sub TECHNOLOGY			{ 2; }
sub HORZSIZE			{ 4; }
sub VERTSIZE			{ 6; }
sub HORZRES			{ 8; }
sub VERTRES			{ 10; }
sub BITSPIXEL			{ 12; }
sub PLANES			{ 14; }
sub NUMBRUSHES			{ 16; }
sub NUMPENS			{ 18; }
sub NUMMARKERS			{ 20; }
sub NUMFONTS			{ 22; }
sub NUMCOLORS			{ 24; }
sub PDEVICESIZE			{ 26; }
sub CURVECAPS			{ 28; }
sub LINECAPS			{ 30; }
sub POLYGONALCAPS		{ 32; }
sub TEXTCAPS			{ 34; }
sub CLIPCAPS			{ 36; }
sub RASTERCAPS			{ 38; }
sub ASPECTX			{ 40; }
sub ASPECTY			{ 42; }
sub ASPECTXY			{ 44; }
sub LOGPIXELSX			{ 88; }
sub LOGPIXELSY			{ 90; }
sub SIZEPALETTE			{ 104; }
sub NUMRESERVED			{ 106; }
sub COLORRES			{ 108; }
sub PHYSICALWIDTH		{ 110; }
sub PHYSICALHEIGHT		{ 111; }
sub PHYSICALOFFSETX		{ 112; }
sub PHYSICALOFFSETY		{ 113; }
sub SCALINGFACTORX		{ 114; }
sub SCALINGFACTORY		{ 115; }

# Text output flags

sub NOUPDATECP			{ 0x00000000; }	#
sub TOP				{ 0x00000000; }	#
sub LEFT			{ 0x00000000; }	#
sub UPDATECP			{ 0x00000001; }	#
sub RIGHT			{ 0x00000002; }	#
sub VCENTER			{ 0x00000004; }
sub BOTTOM			{ 0x00000008; }	#
sub WORDBREAK			{ 0x00000010; }
sub BASELINE			{ 0x00000018; }	#
sub SINGLELINE			{ 0x00000020; }
sub EXPANDTABS			{ 0x00000040; }
sub TABSTOP			{ 0x00000080; }
sub NOCLIP			{ 0x00000100; }
sub EXTERNALLEADING		{ 0x00000200; }
sub CALCRECT			{ 0x00000400; }
sub INTERNAL			{ 0x00001000; }
sub EDITCONTROL			{ 0x00002000; }
sub PATH_ELLIPSIS		{ 0x00004000; }
sub END_ELLIPSIS		{ 0x00008000; }
sub MODIFYSTRING		{ 0x00010000; }
sub RTLREADING			{ 0x00020000; }	# Modify 1
sub WORD_ELLIPSIS		{ 0x00040000; }
sub CENTER			{ 0x00080000; }	# Modify 2

sub UTF8			{ 0x40000000; }
sub JUSTIFY			{ 0x80000000; }

# Pen styles
sub PS_DASH			{ 0x00000001; }
sub PS_DOT			{ 0x00000002; }
sub PS_DASHDOT			{ 0x00000003; }
sub PS_DASHDOTDOT		{ 0x00000004; }
sub PS_NULL			{ 0x00000005; }
sub PS_INSIDEFRAME		{ 0x00000006; }
sub PS_SOLID			{ 0x00010000; }
sub PS_JOIN_ROUND		{ 0x00010000; }
sub PS_ENDCAP_ROUND		{ 0x00010000; }
sub PS_ENDCAP_SQUARE		{ 0x00010100; }
sub PS_ENDCAP_FLAT		{ 0x00010200; }
sub PS_JOIN_BEVEL		{ 0x00011000; }
sub PS_JOIN_MITER		{ 0x00012000; }

# Brush styles
sub BS_SOLID			{ 0; }
sub BS_NULL			{ 1; }
sub BS_HOLLOW			{ 1; }
sub BS_HATCHED			{ 2; }
sub BS_PATTERN			{ 3; }
sub BS_DIBPATTERN		{ 5; }
sub BS_DIBPATTERNPT		{ 6; }
sub BS_PATTERN8X8		{ 7; }
sub BS_DIBPATTERN8X8		{ 8; }

# Brush hatches
sub HS_HORIZONTAL		{ 0; }
sub HS_VERTICAL			{ 1; }
sub HS_FDIAGONAL		{ 2; }
sub HS_BDIAGONAL		{ 3; }
sub HS_CROSS			{ 4; }
sub HS_DIAGCROSS		{ 5; }

# Path modes
sub CR_OFF			{ 0; }
sub CR_AND			{ 1; }
sub CR_OR			{ 2; }
sub CR_XOR			{ 3; }
sub CR_DIFF			{ 4; }
sub CR_COPY			{ 5; }

# Fill modes
sub ALTERNATE			{ 1; }
sub WINDING			{ 2; }

# Duplexing
sub SIMPLEX			{ 1; }
sub VERTICAL 			{ 2; }
sub HORIZONTAL			{ 3; }

# Paper sizes
sub LETTER			{ 1; }
sub LETTERSMALL			{ 2; }
sub TABLOID			{ 3; }
sub LEDGER			{ 4; }
sub LEGAL			{ 5; }
sub STATEMENT			{ 6; }
sub EXECUTIVE			{ 7; }
sub A3				{ 8; }
sub A4				{ 9; }
sub A4SMALL			{ 10; }
sub A5				{ 11; }
sub B4				{ 12; }
sub B5				{ 13; }
sub FOLIO			{ 14; }
sub QUARTO			{ 15; }
sub IN_10X14			{ 16; }
sub IN_11X17			{ 17; }
sub NOTE			{ 18; }
sub ENV_9			{ 19; }
sub ENV_10			{ 20; }
sub ENV_11			{ 21; }
sub ENV_12			{ 22; }
sub ENV_14			{ 23; }
sub CSHEET			{ 24; }
sub DSHEET			{ 25; }
sub ESHEET			{ 26; }
sub ENV_DL			{ 27; }
sub ENV_C5			{ 28; }
sub ENV_C3			{ 29; }
sub ENV_C4			{ 30; }
sub ENV_C6			{ 31; }
sub ENV_C65			{ 32; }
sub ENV_B4			{ 33; }
sub ENV_B5			{ 34; }
sub ENV_B6			{ 35; }
sub ENV_ITALY			{ 36; }
sub ENV_MONARCH			{ 37; }
sub ENV_PERSONAL		{ 38; }
sub FANFOLD_US			{ 39; }
sub FANFOLD_STD_GERMAN		{ 40; }
sub FANFOLD_LGL_GERMAN		{ 41; }
sub ISO_B4			{ 42; }
sub JAPANESE_POSTCARD		{ 43; }
sub IN_9X11			{ 44; }
sub IN_10X11			{ 45; }
sub IN_15X11			{ 46; }
sub ENV_INVITE			{ 47; }
sub RESERVED_48			{ 48; }
sub RESERVED_49			{ 49; }
sub LETTER_EXTRA		{ 50; }
sub LEGAL_EXTRA			{ 51; }
sub TABLOID_EXTRA		{ 52; }
sub A4_EXTRA			{ 53; }
sub LETTER_TRANSVERSE		{ 54; }
sub A4_TRANSVERSE		{ 55; }
sub LETTER_EXTRA_TRANSVERSE	{ 56; }
sub A_PLUS			{ 57; }
sub B_PLUS			{ 58; }
sub LETTER_PLUS			{ 59; }
sub A4_PLUS			{ 60; }
sub A5_TRANSVERSE		{ 61; }
sub B5_TRANSVERSE		{ 62; }
sub A3_EXTRA			{ 63; }
sub A5_EXTRA			{ 64; }
sub B5_EXTRA			{ 65; }
sub A2				{ 66; }
sub A3_TRANSVERSE		{ 67; }
sub A3_EXTRA_TRANSVERSE		{ 68; }

# Paper orientation
sub PORTRAIT			{ 1; }
sub LANDSCAPE			{ 2; }

# Character sets
sub ANSI			{ 0; }
sub DEFAULT			{ 1; }
sub SYMBOL			{ 2; }
sub SHIFTJIS			{ 128; }
sub HANGEUL			{ 129; }
sub GB2312			{ 134; }
sub CHINESEBIG5			{ 136; }
sub OEM				{ 255; }

sub JOHAB			{ 130; }
sub HEBREW			{ 177; }
sub ARABIC			{ 178; }
sub GREEK			{ 161; }
sub TURKISH			{ 162; }
sub VIETNAMESE			{ 163; }
sub THAI			{ 222; }
sub EASTEUROPE			{ 238; }
sub RUSSIAN			{ 204; }

sub MAC				{ 77; }
sub BALTIC			{ 186; }

sub FW_NORMAL			{ 400; }
sub FW_BOLD			{ 700; }

# Injection of PostScript

sub PSI_BEGINSTREAM		{ 1; }
sub PSI_PSADOBE			{ 2; }
sub PSI_PAGESATEND		{ 3; }
sub PSI_PAGES			{ 4; }
sub PSI_DOCNEEDEDRES		{ 5; }
sub PSI_DOCSUPPLIEDRES		{ 6; }
sub PSI_PAGEORDER		{ 7; }
sub PSI_ORIENTATION		{ 8; }
sub PSI_BOUNDINGBOX		{ 9; }
sub PSI_PROCESSCOLORS		{ 10; }
sub PSI_COMMENTS		{ 11; }
sub PSI_BEGINDEFAULTS		{ 12; }
sub PSI_ENDDEFAULTS		{ 13; }
sub PSI_BEGINPROLOG		{ 14; }
sub PSI_ENDPROLOG		{ 15; }
sub PSI_BEGINSETUP		{ 16; }
sub PSI_ENDSETUP		{ 17; }
sub PSI_TRAILER			{ 18; }
sub PSI_EOF			{ 19; }
sub PSI_ENDSTREAM		{ 20; }
sub PSI_PROCESSCOLORSATEND	{ 21; }

sub PSI_PAGENUMBER		{ 100; }
sub PSI_BEGINPAGESETUP		{ 101; }
sub PSI_ENDPAGESETUP		{ 102; }
sub PSI_PAGETRAILER		{ 103; }
sub PSI_PLATECOLOR		{ 104; }
sub PSI_SHOWPAGE		{ 105; }
sub PSI_PAGEBBOX		{ 106; }
sub PSI_ENDPAGECOMMENTS		{ 107; }
sub PSI_VMSAVE			{ 200; }
sub PSI_VMRESTORE		{ 201; }

#------------------------------------------------------------------------------#

sub new {

  my $class = shift;

  my $self = { };

  bless($self, $class);

  if ($self->_init(@_)) {
    return $self;
  } else {
    _croak qq^ERROR: Cannot initialise object!\n^;
    return undef;
  }

}

#------------------------------------------------------------------------------#

sub _init {

  my $self = shift;

  (%{$self->{params}}) = @_;

  for (keys %{$self->{params}}) {
    if ($_ !~ /^debug$|^dc$|^printer$|^dialog$|^file$|^pdf$|^prompt$|^copies$|^collate$|^minp$|^maxp$|^orientation$|^papersize$|^duplex$|^description$|^unit$|^source$|^color$|^height$|^width$/) {
      _carp qq^WARNING: Unknown attribute "$_"!\n^;
    }
  }

  $_numcroaked = 0;

  if ((!_num($self->{params}->{'debug'})) or ($self->{params}->{'debug'} > 2)) {
    $_debuglevel = 0;
  } else {
    $_debuglevel = $self->{params}->{'debug'};
  }

  my $dialog;
  if (_num($self->{params}->{'dialog'})) {
    $dialog = 1;
  } else {
    $dialog = 0;
    $self->{params}->{'dialog'} = 0;
  }

  if (defined($self->{params}->{'file'})) {
    $self->{params}->{'file'} =~ s/\//\\/g;
    my $file = $self->{params}->{'file'};
    $file =~ s/(.*\\)//g;
    my $dir = $1;
    unless ($dir) { $dir = '.\\'; }
    if (($file =~ /[\"\*\/\:\<\>\?\\\|]|[\x00-\x1f]/) or (!(-d $dir))) {
      _croak "ERROR: Cannot create printer object! Invalid filename\n";
      return undef;
    }
  }

  unless (defined $self->{params}->{'printer'})	{ $self->{params}->{'printer'}	 = ""; } else { $self->{params}->{'printer'} =~ s/\//\\/g; }
  unless (_num($self->{params}->{'copies'}))	{ $self->{params}->{'copies'}	 = 1;  }
  unless (_num($self->{params}->{'collate'}))	{ $self->{params}->{'collate'}	 = 1;  }
  unless (_num($self->{params}->{'minp'}))	{ $self->{params}->{'minp'}	 = 0;  }
  unless (_num($self->{params}->{'maxp'}))	{ $self->{params}->{'maxp'}	 = 0;  }
  unless (_num($self->{params}->{'orientation'}))	{ $self->{params}->{'orientation'} = 0;  }
  unless (_num($self->{params}->{'papersize'}))	{ $self->{params}->{'papersize'}	 = 0;  }
  unless (_num($self->{params}->{'duplex'}))	{ $self->{params}->{'duplex'}	 = 0;  }
  unless (_num($self->{params}->{'source'}))	{ $self->{params}->{'source'}	 = 7;  }
  unless (_num($self->{params}->{'color'}))	{ $self->{params}->{'color'}	 = 2;  }
  unless (_num($self->{params}->{'height'}))	{ $self->{params}->{'height'}	 = 0;  }
  unless (_num($self->{params}->{'width'}))	{ $self->{params}->{'width'}	 = 0;  }
  unless (defined($self->{params}->{'unit'}))	{ $self->{params}->{'unit'}	 = 1;  }

  return undef if $_numcroaked;

  if (($self->{params}->{'width'}) and (!$self->{params}->{'height'})) {
    $self->{params}->{'width'} = 0;
    _carp qq^WARNING: width attribute used without height attribute - IGNORED!\n^;
  }
  if ((!$self->{params}->{'width'}) and ($self->{params}->{'height'})) {
    $self->{params}->{'height'} = 0;
    _carp qq^WARNING: height attribute used without width attribute - IGNORED!\n^;
  }

  if (($self->{params}->{'width'} > 0) and ($self->{params}->{'height'} > 0)) {
    if (defined($self->{params}->{'unit'})) {
      if ($self->{params}->{'unit'} eq "mm") {
        $self->{params}->{'width'} *= 10;
        $self->{params}->{'height'} *= 10;
      } elsif ($self->{params}->{'unit'} eq "cm") {
        $self->{params}->{'width'} *= 100;
        $self->{params}->{'height'} *= 100;
      } elsif ($self->{params}->{'unit'} eq "pt") {
        $self->{params}->{'width'} *= 254.09836 / 72;
        $self->{params}->{'height'} *= 254.09836 / 72;
      } elsif ($self->{params}->{'unit'} =~ /^\d+\.*\d*$/i) {
        $self->{params}->{'width'} *= 254.09836 / $self->{params}->{'unit'};
        $self->{params}->{'height'} *= 254.09836 / $self->{params}->{'unit'};
      } else {
        $self->{params}->{'width'} *= 254.09836;
        $self->{params}->{'height'} *= 254.09836;
      }
    } else {
      $self->{params}->{'width'} *= 254.09836;
      $self->{params}->{'height'} *= 254.09836;
    }
  } elsif (($self->{params}->{'width'} < 0) or ($self->{params}->{'height'} < 0)) {
    $self->{params}->{'width'} = 0;
    $self->{params}->{'height'} = 0;
    _carp qq^WARNING: height, width attributes may not have negative values - IGNORED!\n^;
  }

  if (($dialog) and ((defined($self->{params}->{'prompt'})) or (defined($self->{params}->{'file'})))) {
    $self->{params}->{'dialog'} = $self->{params}->{'dialog'} | PRINTTOFILE;
    undef $self->{params}->{'prompt'};
  }

  unless(_IsNT()) {
    _carp qq^WARNING: Windows 95/98/ME detected!\n^;
    _carp qq^WARNING: All "Space" tranformations will be ignored!\n^;
  }

  $self->{dc} = _CreatePrinter($self->{params}->{'printer'}, $dialog, $self->{params}->{'dialog'}, $self->{params}->{'copies'}, $self->{params}->{'collate'}, $self->{params}->{'minp'}, $self->{params}->{'maxp'}, $self->{params}->{'orientation'}, $self->{params}->{'papersize'}, $self->{params}->{'duplex'}, $self->{params}->{'source'}, $self->{params}->{'color'}, $self->{params}->{'height'}, $self->{params}->{'width'});
  unless ($self->{dc}) {
    _croak "ERROR: Cannot create printer object! ${\_GetLastError()}";
    return undef;
  }
  $self->{odc} = $self->{dc};

  unless (defined($self->Unit($self->{params}->{'unit'}))) {
    _croak "ERROR: Cannot set default units!\n";
    return undef;
  }

  $self->{xres} = $self->Caps(LOGPIXELSX);
  $self->{yres} = $self->Caps(LOGPIXELSY);

  $self->{xsize} = $self->_xp2un($self->Caps(PHYSICALWIDTH));
  $self->{ysize} = $self->_yp2un($self->Caps(PHYSICALHEIGHT));

  unless (($self->{xres} > 0) && ($self->{yres} > 0)) {
    _croak "ERROR: Cannot get printer resolution! ${\_GetLastError()}";
    return undef;
  }

  $self->{flags} = $self->{params}->{'dialog'};

  if (($self->{flags} & PRINTTOFILE) || (defined($self->{params}->{'prompt'}))) {
    my ($suggest, $indir) = ("", "");
    if (defined($self->{params}->{'file'})) {
      $suggest = $self->{params}->{'file'};
      $suggest =~ s/(.*\\)//g;
      $indir = $1 || "";
    } elsif ((defined($self->{params}->{'description'})) and ($self->{params}->{'description'} ne "")) {
      $suggest = $self->{params}->{'description'};
      $suggest =~ s/[\"\*\/\:\<\>\?\\\|]|[\x00-\x1f]/-/g;
      $suggest = reverse $suggest;
      $suggest =~ s/^.*?\.//;
      $suggest = reverse $suggest;
      $suggest =~ s/\s\s//g;
    } else {
      $suggest = "Printer";
    }
    if (defined($self->{params}->{'pdf'})) {
      my $ext = $self->{params}->{'file'} ? "" : ".pdf";
      $self->{params}->{'file'} = _SaveAs(2, $suggest.$ext, $indir);
    } else {
      my $ext = $self->{params}->{'file'} ? "" : ".prn";
      $self->{params}->{'file'} = _SaveAs(1, $suggest.$ext, $indir);
    }
    if ($self->{params}->{'file'} eq "") {
      _croak "ERROR: Save to file failed! ${\_GetLastError()}";
      return undef;
    }
  }

  if ((defined($self->{params}->{'pdf'})) and (!defined($self->{params}->{'file'}))) {
    delete $self->{params}->{'pdf'};
    _carp qq^WARNING: pdf attribute used without file attribute - IGNORED!\n^;
  }

  $self->{copies}  = $self->{params}->{'copies'};
  $self->{collate} = $self->{params}->{'collate'};
  $self->{minp}    = $self->{params}->{'minp'};
  $self->{maxp}    = $self->{params}->{'maxp'};

  if (!defined($self->{params}->{'dc'})) {
    unless (defined($self->Start($self->{params}->{description}, $self->{params}->{'file'}))) {
      _croak "ERROR: Cannot start default document!\n";
      return undef;
    }
  }

  unless (defined($self->Pen(1, 0, 0, 0))) {
    _croak "ERROR: Cannot create default pen!\n";
    return undef;
  }
  unless (defined($self->Color(0, 0, 0))) {
    _croak "ERROR: Cannot set default color!\n";
    return undef;
  }
  unless (defined($self->Brush(128, 128, 128))) {
    _croak "ERROR: Cannot create default brush!\n";
    return undef;
  }
  unless (defined($self->Font())) {
    _croak "ERROR: Cannot create default font!\n";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub _num {

  my $val = shift;

  if (defined($val)) {
    if ($val =~ /^\-*\d+\.*\d*$/) {
      return 1;
    } else {
      $_numcroaked = 1;
      _croak qq^ERROR: Argument "$val" isn't numeric!\n^;
      return undef;
    }
  } else {
    return 0;
  }

}

#------------------------------------------------------------------------------#

sub _xun2p {

  my $self = shift;
  my $uval = shift;

  return $uval if $self->{unit} == 0;

  my $pval = $uval * $self->{xres} / $self->{unit};
  return $pval;

}

sub _yun2p {

  my $self = shift;
  my $uval = shift;

  return $uval if $self->{unit} == 0;

  my $pval = $uval * $self->{yres} / $self->{unit};
  return $pval;

}

sub _xp2un {

  my $self = shift;
  my $pval = shift;

  return $pval if $self->{unit} == 0;

  my $uval = ($self->{unit} * $pval) / $self->{xres};
  return $uval;

}

sub _yp2un {

  my $self = shift;
  my $pval = shift;

  return $pval if $self->{unit} == 0;

  my $uval = ($self->{unit} * $pval) / $self->{yres};
  return $uval;

}

sub _pts2p {

  my $self = shift;
  my $ptsval = shift;

  return $ptsval if $self->{unit} == 0;

  my $pval = ($ptsval * $self->{xres}) / 72;
  return $pval;

}

sub _p2pts {

  my $self = shift;
  my $pval = shift;

  return $pval if $self->{unit} == 0;

  my $ptsval = (72 * $pval) / $self->{xres};
  return $ptsval;

}

#------------------------------------------------------------------------------#

sub _pdf {

  my $self = shift;

  if ((defined($self->{params}->{'pdf'})) and (defined($self->{pdfend0}))) {

    if ($self->{params}->{'pdf'} == 0) {
      open OLDERR, ">&STDERR";
      open STDERR, ">nul" or die;
    }
    if ($self->{params}->{'pdf'} == 1) {
      open OLDERR, ">&STDERR" or die;
      open STDERR, ">$self->{pdfend1}.log";
    }

    unless (Win32::Printer::_GhostPDF($self->{pdfend0}, $self->{pdfend1})) {
      if (($self->{params}->{'pdf'} == 0) || ($self->{params}->{'pdf'} == 1)) {
        close STDERR;
        open STDERR, ">&OLDERR";
        close OLDERR;
      }
      return 0;
    }

    if (($self->{params}->{'pdf'} == 0) || ($self->{params}->{'pdf'} == 1)) {
      close STDERR;
      open STDERR, ">&OLDERR";
      close OLDERR;
    }

    unlink $self->{pdfend0};

    undef $self->{pdfend0};
    undef $self->{pdfend1};

  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Unit {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }

  my $unit = shift;

  if (defined($unit)) {
    if ($unit eq "mm") {
      $self->{unit} = 25.409836;
    } elsif ($unit eq "cm") {
      $self->{unit} = 2.5409836;
    } elsif ($unit eq "in") {
      $self->{unit} = 1;
    } elsif ($unit eq "pt") {
      $self->{unit} = 72;
    } elsif ($unit =~ /^\d+\.*\d*$/i) {
      $self->{unit} = $unit;
    } else {
      _carp "WARNING: Invalid unit \"$unit\"! Units set to \"in\".\n";
      $self->{unit} = 1;
    }
  }

  return $self->{unit};

}

#------------------------------------------------------------------------------#

sub Debug {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }

  if ($#_ == 0) {
    $_numcroaked = 0;
    _num($_[0]);
    return undef if $_numcroaked;
    if (($_[0] > -1) and ($_[0] < 3)) {
      $_debuglevel = shift;
    } else {
      _croak "ERROR: Invalid argument!\n";
    }
  }

  return $_debuglevel;

}

#------------------------------------------------------------------------------#

sub Next {

  my $self = shift;

  if ($self->{emfstate}) {

    if ($#_ > -1) { 
      $self->{emfname} = shift;
      $self->{emfw} = shift;
      $self->{emfh} = shift;
    }

    return ($self->MetaEnd, $self->Meta($self->{emfname}, $self->{emfw}, $self->{emfh}));

  } else {

    if ($#_ > 1) { _carp "WARNING: Too many actual parameters!\n"; }

    my $desc = shift;
    my $file = shift;

    my $ret = $self->End();

    unless (defined($ret)) {
      _croak "ERROR: Cannot end previous job!\n";
      return undef;
    }
    unless (defined($self->Start($desc, $file))) {
      _croak "ERROR: Cannot start next job!\n";
      return undef;
    }

    return $ret;
  }

}

#------------------------------------------------------------------------------#

sub Start {

  my $self = shift;

  if ($self->{emfstate}) {
    _croak "ERROR: Starting document not allowed in EMF mode!\n";
    return undef;
  }

  if ($#_ > 1) { _carp "WARNING: Too many actual parameters!\n"; }

  my $desc = shift;
  my $file = shift;

  if ((!defined($file)) and (!defined($self->{params}->{'file'}))) {
    $file = "";
  } else {
    if ((!defined($file)) and (defined($self->{params}->{'file'}))) {
      $file = $self->{params}->{'file'};
    }
    while (-f $file) { 
      if ($file !~ s/(.*\\*)(.*)\((\d+)\)(.*)\./my $i = $3; $i++; "$1$2($i)."/e) {
        $file =~ s/(.*\\*)(.*)\./$1$2(1)\./
      }
      $self->{params}->{'file'} = $file;
    }
  }

  if (($file ne "") and (defined($self->{params}->{'pdf'}))) {
    $self->{pdfend1} = $file;
    my $tmp = Win32::Printer::_GetTempPath();
    $file =~ s/.*\\//;
    my $seed = join('', (0..9, 'A'..'Z', 'a'..'z')[rand 62, rand 62, rand 62, rand 62, rand 62, rand 62, rand 62, rand 62]);
    $file = $tmp.$file.".".$seed;
    $self->{pdfend0} = $file;
  }

  unless (_StartDoc($self->{dc}, $desc || $self->{params}->{'description'} || 'Printer', $file) > 0) {
    _croak "ERROR: Cannot start the document! ${\_GetLastError()}";
    return undef;
  }

  unless (_StartPage($self->{dc}) > 0) {
    _croak "ERROR: Cannot start the page! ${\_GetLastError()}";
    return undef;
  }

  unless (defined($self->Space(1, 0, 0, 1, 0, 0))) {
    _croak "ERROR: Cannot reset the document space!\n";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub End {

  my $self = shift;

  if ($self->{emfstate}) {
    _croak "ERROR: Ending document not allowed in EMF mode!\n";
    return undef;
  }

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_EndPage($self->{dc}) > 0) {
    _croak "ERROR: Cannot end the page! ${\_GetLastError()}";
    return undef;
  }

  unless (_EndDoc($self->{dc})) {
    _croak "ERROR: Cannot end the document! ${\_GetLastError()}";
    return undef;
  }

  unless ($self->_pdf()) {
    _croak "ERROR: Cannot create PDF document! ${\_GetLastError()}";
    return undef;
  }

  if (defined($self->{params}->{'file'})) { return $self->{params}->{'file'}; }
  return 1;

}

#------------------------------------------------------------------------------#

sub Abort {

  my $self = shift;

  if ($self->{emfstate}) {
    _croak "ERROR: Aborting document not allowed in EMF mode!\n";
    return undef;
  }

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_AbortDoc($self->{dc})) {
    _croak "ERROR: Cannot abort the document! ${\_GetLastError()}";
    return undef;
  }

  if (defined($self->{params}->{'file'})) { return $self->{params}->{'file'}; }

  return 1;

}

#------------------------------------------------------------------------------#

sub Page {

  my $self = shift;

  if ($self->{emfstate}) {
    _croak "ERROR: Starting new page not allowed in EMF mode!\n";
    return undef;
  }

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_EndPage($self->{dc}) > 0) {
    _croak "ERROR: Cannot end the page! ${\_GetLastError()}";
    return undef;
  }

  unless (_StartPage($self->{dc}) > 0) {
    _croak "ERROR: Cannot start the page! ${\_GetLastError()}";
    return undef;
  }

  unless (defined($self->Space(1, 0, 0, 1, 0, 0))) {
    _croak "ERROR: Cannot reset the page space!\n";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Space {

  my $self = shift;

  if (_IsNT()) {

    if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
    if ($#_ < 5) {
      _croak "ERROR: Not enough actual parameters!\n";
      return undef;
    }

    $_numcroaked = 0;
    for (@_) { _num($_); }
    return undef if $_numcroaked;

    my ($m11, $m12, $m21, $m22, $dx, $dy) = @_;

    my $xoff = $self->Caps(PHYSICALOFFSETX);
    my $yoff = $self->Caps(PHYSICALOFFSETY);

    unless (defined($xoff) && defined($yoff)) {
      _croak "ERROR: Cannot get the physical offset!\n";
      return undef;
    }

    if (_SetWorldTransform($self->{dc}, $m11, $m12, $m21, $m22, $self->_xun2p($dx) - $xoff, $self->_yun2p($dy) - $yoff) == 0) {
      _croak "ERROR: Cannot transform space! ${\_GetLastError()}";
      return undef;
    }

  }

  return 1;

}

#------------------------------------------------------------------------------#

sub FontSpace {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }

  my $space = shift;

  $_numcroaked = 0;
  $space = 0 unless _num($space);
  return undef if $_numcroaked;

  my $return = _SetTextCharacterExtra($self->{dc}, $self->_pts2p($space));
  if ($return == 0x80000000) {
    _croak "ERROR: Cannot change font spacing! ${\_GetLastError()}";
    return undef;
  }

  return $self->_p2pts($return);

}

#------------------------------------------------------------------------------#

sub Font {

  my $self = shift;

  if ($#_ > 3) { _carp "WARNING: Too many actual parameters!\n"; }

  if (($#_ == 0) and _IsNo($_[0])) {

    my $prefont;
    unless ($prefont = _SelectObject($self->{dc}, $_[0])) {
      _croak "ERROR: Cannot select font! ${\_GetLastError()}";
      return undef;
    }

    return wantarray ? ($_[0], $prefont) : $_[0];

  } else {

    my ($face, $size, $angle, $charset) = @_;
    my ($escape, $orient);
    if (defined $angle) {
      if ($angle =~ /^ARRAY/) {
        $escape = $$angle[0];
        $orient = $$angle[1];
      } else {
        $escape = $angle;
        $orient = $angle;
      }
    }
    $_numcroaked = 0;
    $face = '' if !defined $face;
    $size = 10 unless _num($size);
    $escape = 0 unless _num($escape);
    $orient = 0 unless _num($orient);
    $charset = 1 unless _num($charset);
    return undef if $_numcroaked;

    my $fontid = "$face\_$size\_$escape\_$orient\_$charset";

    if (!$self->{obj}->{$fontid}) {

      $escape *= 10;
      $orient *= 10;
    
      my ($opt1, $opt2, $opt3, $opt4) = (FW_NORMAL, 0, 0, 0);
      if ($face =~ s/ bold//i ) {
        $opt1 = FW_BOLD;
      }
      if ( $face =~ s/ italic//i ){
        $opt2 = 1;
      }
      if ( $face =~ s/ underline//i ){
        $opt3 = 1;
      }
      if ( $face =~ s/ strike//i ){
        $opt4 = 1;
      }

      $face =~ s/^\s*//;
      $face =~ s/\s*$//;

      $self->{obj}->{$fontid} = _CreateFont($self->_pts2p($size), $escape, $orient, $opt1, $opt2, $opt3,
                                            $opt4, $charset, $face);

      if ($self->{obj}->{$fontid}) {

        my $prefont;
        unless ($prefont = _SelectObject($self->{dc}, $self->{obj}->{$fontid})) {
          _croak "ERROR: Cannot select font! ${\_GetLastError()}";
          return undef;
        }

        my $realface = _GetTextFace($self->{dc});
        if (($face) && ($realface !~ /^$face$/)) {
          _carp "WARNING: Cannot select desired font face - \"$realface\" selected!\n";
        }

        return wantarray ? ($self->{obj}->{$fontid}, $prefont) : $self->{obj}->{$fontid};

      } else {
        _croak "ERROR: Cannot create font! ${\_GetLastError()}";
        return undef;
      }

    } else {	# Fix by Sandor Patocs;

      my $prefont;
      unless ($prefont = _SelectObject($self->{dc}, $self->{obj}->{$fontid})) {
        _croak "ERROR: Cannot select font! ${\_GetLastError()}";
        return undef;
      }
      return wantarray ? ($self->{obj}->{$fontid}, $prefont) : $self->{obj}->{$fontid};

    }

  }

}

#------------------------------------------------------------------------------#

sub FontEnum {

  my $self = shift;

  if ($#_ > 1) { _carp "WARNING: Too many actual parameters!\n"; }

  my ($face, $charset) = @_;

  $face = '' if !defined $face;
  $charset = 1 unless _num($charset);

  my $return = _FontEnum($self->{dc}, $face, $charset);

  if (wantarray) {
    my @return;
    my @lines = split(/\n/, $return);
    for my $i (0..$#lines) {
      (
        $return[$i]{Face},
        $return[$i]{Charset},
        $return[$i]{Style},
        $return[$i]{Type}
      ) = split(/\t/, $lines[$i]);
    }
    return @return;
  } else {
    return $return;
  }

}

#------------------------------------------------------------------------------#

sub Fit {

  my $self = shift;

  if ($#_ > 2) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 0) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  my $string = shift;
  my $ext = shift;
  my $vers = shift;

  $_numcroaked = 0;
  _num($ext);
  $vers = 0 unless _num($vers);
  return undef if $_numcroaked;

  if ($vers & 0x40000000) {
    $vers = 1;
  }

  $ext = $self->_xun2p($ext);
  my ($fit, $cx, $cy) = (0, 0, 0);

  unless (_GetTextExtentPoint($vers, $self->{dc}, $string, $ext, $fit, $cx, $cy)) {
    _croak "ERROR: Cannot get text extent! ${\_GetLastError()}";
    return undef;
  }

  return wantarray ? ($fit, $self->_xp2un($cx), $self->_yp2un($cy)) : $fit;

}

#------------------------------------------------------------------------------#

sub Write {

  my $self = shift;

  if ($#_ > 6) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 2) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  if (!defined($_[0]) || ($_[0] eq '')) {
    return wantarray ? (0, 0, 0, '') : 0;
  }

  if ((($#_ > 1) and ($#_ < 4)) or (($_[3] & 0x80000000) and ($#_ == 4))) {

    my ($string, $x, $y, $align) = @_;

    unless (defined($string)) { $string = ''; }

    $_numcroaked = 0;
    for ($x, $y, $align) {
      _num($_);
    }
    return undef if $_numcroaked;

    unless ($align) { $align = LEFT; }

    if ($align & 0x00020000) { $align = $align & ~0x00020000 | 0x00000100; }
    if ($align & 0x00080000) { $align = $align & ~0x00080000 | 0x00000006; }

    my $vers = 0;
    if ($align & 0x40000000) {
      $align &= ~0x40000000;
      $vers = 1;
    }

    if ($align & 0x80000000) {
      unless(_num($_[4])) {
        _croak "ERROR: Cannot set text justification! Wrong justification width\n";
        return undef;
      }
      my $width = $self->_xun2p($_[4]);

      unless (_SetJustify($vers, $self->{dc}, $string, $width)) {
        _croak "ERROR: Cannot set text justification! ${\_GetLastError()}";
        return undef;
      }
    }

    my ($retval, $retw, $reth);
    unless ($retval = _TextOut($vers, $self->{dc}, $self->_xun2p($x), $self->_yun2p($y), $string, $align & ~0x80000000)) {
      _croak "ERROR: Cannot write text! ${\_GetLastError()}";
      return undef;
    }
    $retw = 0x0000FFFF & $retval;
    $reth = (0xFFFF0000 & $retval) >> 16;

    if ($align & 0x80000000) {
      unless (_SetJustify($vers, $self->{dc}, "", -1)) {
        _croak "ERROR: Cannot unset text justification! ${\_GetLastError()}";
        return undef;
      }
    }

    return wantarray ? ($self->_xp2un($retw), $self->_yp2un($reth)) : $self->_yp2un($reth);

  } else {

    my ($string, $x, $y, $w, $h, $f, $tab) = @_;

    unless (defined($string)) { $string = ''; }

    $_numcroaked = 0;
    for ($x, $y, $w, $h, $f, $tab) {
      _num($_);
    }
    $f = 0 unless _num($f);
    $tab = 8 unless _num($tab);
    return undef if $_numcroaked;

    my $height;
    my $len = 0;
    my $width = $self->_xun2p($x + $w);

    if ($f & 0x00080000) { $f = $f & ~0x00080000 | 0x00000001; }

    my $vers = 0;
    if ($f & 0x40000000) {
      $f &= ~0x40000000;
      $vers = 1;
    }
    $height = _DrawText($vers, $self->{dc}, $string,
			$self->_xun2p($x), $self->_yun2p($y),
			$width, $self->_yun2p($y + $h),
			$f, $len, $tab);

    unless ($height) {
      _croak "ERROR: Cannot draw text! ${\_GetLastError()}";
      return undef;
    }

    return wantarray ? ($self->_xp2un($width), $self->_yp2un($height), $len, $string) : $self->_yp2un($height);

  }

}

#------------------------------------------------------------------------------#

sub Write2 {

  my $self = shift;

  if ($#_ > 8) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 3) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  my $text = shift;
  my ($x, $y, $w, $flags, $indento, $hspace, $vspace) = @_;

  unless (defined($text)) { $text = ''; }

  $_numcroaked = 0;
  for ($x, $y, $w) {
    _num($_);
  }
  $flags = 0 unless _num($flags);
  $indento = 0 unless _num($indento);
  $hspace = 0 unless _num($hspace);
  $vspace = 0 unless _num($vspace);
  return undef if $_numcroaked;

  my @rows = split(/\n/, $text);

  my ($lf, $proctext) = (0, '');

  my ($vers, $len, $wi, $he) = (0, 0, 0, 0);
  if ($flags & 0x40000000) {
    $flags &= ~0x40000000;
    $vers = 1;
  }
  unless (_GetTextExtentPoint($vers, $self->{dc}, 'W', 1, $len, $wi, $he)) {
    _croak "ERROR: Cannot get text extent! ${\_GetLastError()}";
    return undef;
  }

  my $return = _SetTextCharacterExtra($self->{dc}, $self->_pts2p($hspace));
  if ($return == 0x80000000) {
    _croak "ERROR: Cannot change font spacing! ${\_GetLastError()}";
    return undef;
  }

  if ($flags & 0x00080000) {
    $x += $w / 2;
    $indento = 0;
  } elsif ($flags & 0x00000002) {
    $x += $w;
    $indento = 0;
  }

  my $out_wi = 0;

  for my $row (@rows) {

    my $indent = $indento;

    if ($row eq '') {
      $lf += $he;
      $proctext .= "\n";
      next;
    }

    while (length($row)) {

      unless (_GetTextExtentPoint($vers, $self->{dc}, $row, $self->_xun2p($w - $indent), $len, $wi, $he)) {
        _croak "ERROR: Cannot get text extent! ${\_GetLastError()}";
        return undef;
      }

      if ($out_wi < $wi) {
        $out_wi = $wi;
      }

      my $corr = 0;

      my $rowenta = substr($row, 0, $len);
      if ($len < length($row)) {
        $rowenta =~ s/\s$//;
        $rowenta = reverse($rowenta);
        $rowenta =~ s/^\S+?([\s\-])/defi($1, \$corr)/e;
        $rowenta = reverse($rowenta);
        if ($flags & 0x80000000) {
          unless (_SetJustify($vers, $self->{dc}, $rowenta, $self->_xun2p($w))) {
            _croak "ERROR: Cannot set text justification! ${\_GetLastError()}";
            return undef;
          }
        }
      }

      unless (_TextOut($vers, $self->{dc}, $self->_xun2p($x + $indent), $self->_yun2p($y) + $lf, $rowenta, $flags & ~0x80000000)) {
        _croak "ERROR: Cannot write text! ${\_GetLastError()}";
        return undef;
      }
      $lf += $he + $self->_yun2p($vspace);

      if ($flags & 0x80000000) {
        unless (_SetJustify($vers, $self->{dc}, "", -1)) {
          _croak "ERROR: Cannot unset text justification! ${\_GetLastError()}";
          return undef;
        }
        $out_wi = $self->_xun2p($w);
      }

      $proctext .= $rowenta."\n";
      $row = substr($row, length($rowenta) + $corr);
      $indent = 0;
    }
  }

  return wantarray ? ($self->_xp2un($out_wi), $self->_yp2un($lf), $proctext) : $self->_yp2un($lf);

  #--------------------

  sub defi {
    if ($_[0] eq "-") {
      ${$_[1]} = 0;
      return "-";
    } else {
      ${$_[1]} = 1;
      return "";
    }
  }
  #--------------------
}

#------------------------------------------------------------------------------#

sub Pen {

  my $self = shift;

  if (($#_ == 0) and _IsNo($_[0])) {

    my $handle = shift;

    my $prepen = _SelectObject($self->{dc}, $handle);
    unless ($prepen) {
      _croak "ERROR: Cannot select pen! ${\_GetLastError()}";
      return undef;
    }

    return $prepen;

  } else {

    my $penid = "pen";

    if ($#_ == -1) {

      if (!$self->{obj}->{$penid}) {

        $self->{obj}->{$penid} = _CreatePen(PS_NULL, 0, 0, 0, 0);

        unless ($self->{obj}->{$penid}) {
          _croak "ERROR: Cannot create pen! ${\_GetLastError()}";
          return undef;
        }

      }

    } else {

      if ($#_ > 4) { _carp "WARNING: Too many actual parameters!\n"; }
      if ($#_ < 3) {
        _croak "ERROR: Not enough actual parameters!\n";
        return undef;
      }

      my ($w, $r, $g, $b, $s) = @_;

      $_numcroaked = 0;
      for ($w, $r, $g, $b, $s) {
        _num($_);
      }
      return undef if $_numcroaked;

      if (!defined($s)) { $s = PS_SOLID; }

      if (0x00010000 & $s) {
        $w = $self->_pts2p($w);
      } else {
        $w = 1;
      }

      $penid = "$w\_$r\_$g\_$b\_$s";

      if (!$self->{obj}->{$penid}) {

        $self->{obj}->{$penid} = _CreatePen($s, $w, $r, $g, $b);

        unless ($self->{obj}->{$penid}) {
          _croak "ERROR: Cannot create pen! ${\_GetLastError()}";
          return undef;
        }

      }

    }

    my $prepen = _SelectObject($self->{dc}, $self->{obj}->{$penid});
    unless ($prepen) {
      _croak "ERROR: Cannot select pen! ${\_GetLastError()}";
      return undef;
    }

    return wantarray ? ($self->{obj}->{$penid}, $prepen) : $self->{obj}->{$penid};

  }

}

#------------------------------------------------------------------------------#

sub Color {

  my $self = shift;

  if (($#_ != 0) && ($#_ != 2)) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my $thecolor;
  if ($#_ == 0) {
    $thecolor = shift;
  } else {
    my ($r, $g, $b) = @_;
    $thecolor = ((($b << 8) | $g) << 8) | $r;
  }
  my $coloref = _SetTextColor($self->{dc}, $thecolor);

  if ($coloref =~ /-/) {
    _croak "ERROR: Cannot select color! ${\_GetLastError()}";
    return undef;
  }

  return $coloref;

}

#------------------------------------------------------------------------------#

sub Brush {

  my $self = shift;

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  if (($#_ == 0) and _IsNo($_[0])) {

    my $handle = shift;

    my $prebrush = _SelectObject($self->{dc}, $handle);
    unless ($prebrush) {
      _croak "ERROR: Cannot select brush! ${\_GetLastError()}";
      return undef;
    }

    return $prebrush;

  } else {

    my ($r, $g, $b, $hs) = @_;

    my ($bs, $brushid);

    $brushid = "brush";

    if (!defined($r)) {

      if (!$self->{obj}->{$brushid}) {

        $self->{obj}->{$brushid} = _CreateBrushIndirect(BS_NULL, 0, 255, 255, 255);

        unless ($self->{obj}->{$brushid}) {
          _croak "ERROR: Cannot create brush! ${\_GetLastError()}";
          return undef;
        }

      }

    } else {

      if ($#_ > 3) { _carp "WARNING: Too many actual parameters!\n"; }
      if ($#_ < 2) {
        _croak "ERROR: Not enough actual parameters!\n";
        return undef;
      }

      if (defined($hs)) {
        $bs = BS_HATCHED;
      } else {
        $bs = BS_SOLID;
        $hs = 0;
      }

      $brushid = "$r\_$g\_$b\_$hs";

      if (!$self->{obj}->{$brushid}) {

        $self->{obj}->{$brushid} = _CreateBrushIndirect($bs, $hs, $r, $g, $b);

        unless ($self->{obj}->{$brushid}) {
          _croak "ERROR: Cannot create brush! ${\_GetLastError()}";
          return undef;
        }

      }

    }

    my $prebrush = _SelectObject($self->{dc}, $self->{obj}->{$brushid});
    unless ($prebrush) {
      _croak "ERROR: Cannot select brush! ${\_GetLastError()}";
      return undef;
    }

    return wantarray ? ($self->{obj}->{$brushid}, $prebrush) : $self->{obj}->{$brushid};

  }

}

#------------------------------------------------------------------------------#

sub Fill {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 0) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  my $fmode = shift;
  $_numcroaked = 0;
  _num($fmode);
  return undef if $_numcroaked;

  unless (_SetPolyFillMode($self->{dc}, $fmode)) {
    _croak "ERROR: Cannot select brush! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Rect {

  my $self = shift;

  if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 3) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h, $ew, $eh) = @_;

  if ($ew) {

    if (!$eh) { $eh = $ew; }

    unless (_RoundRect($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
			     $self->_xun2p($x + $w), $self->_yun2p($y + $h),
			     $self->_xun2p($ew), $self->_yun2p($eh))) {
      _croak "ERROR: Cannot draw rectangular! ${\_GetLastError()}";
      return undef;
    }

  } else {

    unless (_Rectangle($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
			     $self->_xun2p($x + $w), $self->_yun2p($y + $h))) {
      _croak "ERROR: Cannot draw rectangular! ${\_GetLastError()}";
      return undef;
    }

  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Ellipse {

  my $self = shift;

  if ($#_ > 3) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 3) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h) = @_;

  unless (_Ellipse($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
			 $self->_xun2p($x + $w), $self->_yun2p($y + $h))) {
    _croak "ERROR: Cannot draw ellipse! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Chord {

  my $self = shift;

  if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h, $a1, $a2) = @_;

  my $r1 = $w / 2;
  my $r2 = $h / 2;
  my $xc = $x + $r1;
  my $yc = $y + $r2;

  my $pi = 3.1415926535;

  my $rm1 = sqrt(abs(($r1 * $r1 * $r2 * $r2) / ($r1 * $r1 * sin($a1 * $pi / 180) + $r2 * $r2 * cos($a1 * $pi / 180))));
  my $rm2 = sqrt(abs(($r1 * $r1 * $r2 * $r2) / ($r1 * $r1 * sin($a2 * $pi / 180) + $r2 * $r2 * cos($a2 * $pi / 180))));

  my $xr1 = $xc + cos($a1 * $pi / 180) * $rm1;
  my $yr1 = $yc - sin($a1 * $pi / 180) * $rm1;
  my $xr2 = $xc + cos($a2 * $pi / 180) * $rm2;
  my $yr2 = $yc - sin($a2 * $pi / 180) * $rm2;

  unless (_Chord($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
		       $self->_xun2p($x + $w), $self->_yun2p($y + $h),
		       $self->_xun2p($xr1), $self->_yun2p($yr1),
		       $self->_xun2p($xr2), $self->_yun2p($yr2))) {
    _croak "ERROR: Cannot draw chord! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Pie {

  my $self = shift;

  if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h, $a1, $a2) = @_;

  my $xc = $x + $w / 2;
  my $yc = $y + $h / 2;

  my $pi=3.1415926535;

  my $xr1 = $xc + int(100 * cos($a1 * $pi / 180));
  my $yr1 = $yc - int(100 * sin($a1 * $pi / 180));
  my $xr2 = $xc + int(100 * cos($a2 * $pi / 180));
  my $yr2 = $yc - int(100 * sin($a2 * $pi / 180));

  unless (_Pie($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
		     $self->_xun2p($x + $w), $self->_yun2p($y + $h),
		     $self->_xun2p($xr1), $self->_yun2p($yr1),
		     $self->_xun2p($xr2), $self->_yun2p($yr2))) {
    _croak "ERROR: Cannot draw pie! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Move {

  my $self = shift;

  if ($#_ > 1) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 1) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y) = @_;

  $x = $self->_xun2p($x);
  $y = $self->_yun2p($y);

  unless (_MoveTo($self->{dc}, $x, $y)) {
    _croak "ERROR: Cannot Move! ${\_GetLastError()}";
    return undef;
  }

  return ($self->_xp2un($x), $self->_yp2un($y));

}

#------------------------------------------------------------------------------#

sub Arc {

  my $self = shift;

  if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h, $a1, $a2) = @_;

  my $xc = $x + $w / 2;
  my $yc = $y + $h / 2;

  my $pi = 3.1415926535;

  my $xr1 = $xc + int(100 * cos($a1 * $pi / 180));
  my $yr1 = $yc - int(100 * sin($a1 * $pi / 180));
  my $xr2 = $xc + int(100 * cos($a2 * $pi / 180));
  my $yr2 = $yc - int(100 * sin($a2 * $pi / 180));

  unless (_Arc($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
		     $self->_xun2p($x + $w), $self->_yun2p($y + $h),
		     $self->_xun2p($xr1), $self->_yun2p($yr1),
		     $self->_xun2p($xr2), $self->_yun2p($yr2))) {
    _croak "ERROR: Cannot draw arc! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub ArcTo {

  my $self = shift;

  if ($#_ > 5) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my ($x, $y, $w, $h, $a1, $a2) = @_;

  my $xc = $x + $w / 2;
  my $yc = $y + $h / 2;

  my $pi=3.1415926535;

  my $xr1 = $xc + int(100 * cos($a1*$pi/180));
  my $yr1 = $yc - int(100 * sin($a1*$pi/180));
  my $xr2 = $xc + int(100 * cos($a2*$pi/180));
  my $yr2 = $yc - int(100 * sin($a2*$pi/180));

  unless (_ArcTo($self->{dc}, $self->_xun2p($x), $self->_yun2p($y),
		     $self->_xun2p($x + $w), $self->_yun2p($y + $h),
		     $self->_xun2p($xr1), $self->_yun2p($yr1),
		     $self->_xun2p($xr2), $self->_yun2p($yr2))) {
    _croak "ERROR: Cannot draw arc! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Line {

  my $self = shift;

  if ($#_ < 3) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my (@args) = @_;
  my $cnt = 1;

  @args = map { $cnt++%2 ? $self->_yun2p($_) : $self->_xun2p($_) } @args;

  unless (_Polyline($self->{dc}, @args)) {
    _croak "ERROR: Cannot draw line! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub LineTo {

  my $self = shift;

  if ($#_ < 1) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my (@args) = @_;
  my ($cnt) = 1;

  @args = map { $cnt++%2 ? $self->_yun2p($_) : $self->_xun2p($_) } @args;

  unless (_PolylineTo($self->{dc}, @args)) {
    _croak "ERROR: Cannot draw line! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Poly {

  my $self = shift;

  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my (@args) = @_;
  my ($cnt) = 1;

  @args = map { $cnt++%2 ? $self->_yun2p($_) : $self->_xun2p($_) } @args;

  unless (_Polygon($self->{dc}, @args)) {
    _croak "ERROR: Cannot draw polygon! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Bezier {

  my $self = shift;

  if ($#_ < 7) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my (@args) = @_;
  my ($cnt) = 1;

  @args = map { $cnt++%2 ? $self->_yun2p($_) : $self->_xun2p($_) } @args;

  unless (_PolyBezier($self->{dc}, @args)) {
    _croak "ERROR: Cannot draw polybezier! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub BezierTo {

  my $self = shift;

  if ($#_ < 5) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  $_numcroaked = 0;
  for (@_) { _num($_); }
  return undef if $_numcroaked;

  my (@args) = @_;
  my ($cnt) = 1;

  @args = map { $cnt++%2 ? $self->_yun2p($_) : $self->_xun2p($_) } @args;

  unless (_PolyBezierTo($self->{dc}, @args)) {
    _croak "ERROR: Cannot draw polybezier! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub PBegin {

  my $self = shift;

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_BeginPath($self->{dc})) {
    _croak "ERROR: Cannot begin path! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub PAbort {

  my $self = shift;

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_AbortPath($self->{dc})) {
    _croak "ERROR: Cannot abort path! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}


#------------------------------------------------------------------------------#

sub PEnd {

  my $self = shift;

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_EndPath($self->{dc})) {
    _croak "ERROR: Cannot end path! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub PDraw {

  my $self = shift;

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  unless (_StrokeAndFillPath($self->{dc})) {
    _croak "ERROR: Cannot draw path! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub PClip {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }
  if ($#_ < 0) {
    _croak "ERROR: Not enough actual parameters!\n";
  }

  my $mode = shift;
  $_numcroaked = 0;
  _num($mode);
  return undef if $_numcroaked;

  if ($mode == CR_OFF) {
    unless (_DeleteClipPath($self->{dc})) {
      _croak "ERROR: Cannot remove clip path! ${\_GetLastError()}";
      return undef;
    }
    return 1;
  }

  unless (_SelectClipPath($self->{dc}, $mode)) {
    _croak "ERROR: Cannot create clip path! ${\_GetLastError()}";
    return undef;
  }

  return 1;

}

#------------------------------------------------------------------------------#

sub EBbl {

  my $self = shift;

  if ($#_ < 0) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }

  if ($#_ > 5) {
    _carp "WARNING: Too many actual parameters!\n"; 
  }

  my ($string, $x, $y, $flags, $baw, $bah) = @_;

  $_numcroaked = 0;
  unless(_num($x)) { $x = 0; }
  unless(_num($y)) { $y = 0; }
  unless(_num($flags)) { $flags = EB_128SMART | EB_TXT; }
  unless(_num($baw)) { $baw = 0.54; }
  unless(_num($bah)) { $bah = 20; }
  return undef if $_numcroaked;

  my $emf = ($flags & EB_EMF) ? 1 : 0;

  my $error = _EBbl($self->{dc}, $emf, $string, $self->_xun2p($x), $self->_yun2p($y), $flags & ~EB_EMF, $self->_pts2p($baw), $self->_pts2p($bah));
  unless ($error == 0) {
    my @errmessage;
    $errmessage[1]  = "Select barcode standard!\n";
    $errmessage[2]  = "Unsupported character in barcode string!\n";
    $errmessage[4]  = "Wrong barcode string size!\n";
    $errmessage[8]  = "GDI error!\n";
    $errmessage[16] = "Memory allocation error!\n";
    $errmessage[32] = "Unknown error!\n";
    $errmessage[64] = "Could not load ebbl!\n";
    _croak "ERROR: ".$errmessage[$error];
    return undef;
  }

  if ($flags & EB_EMF) {
    if ($emf == 0) {
      _croak "ERROR: Cannot draw barcode! ${\_GetLastError()}";
      return undef;
    }
    $self->{imager}->{$emf} = 0;
  }

  return $emf;

}

#------------------------------------------------------------------------------#

sub Image {

  my $self = shift;

  if (($#_ != 0) and ($#_ != 2) and ($#_ != 4)) {
    _croak "ERROR: Wrong number of parameters!\n";
    return undef;
  }

  my ($width, $height) = (0, 0);

  if (($#_ == 2) or ($#_ == 4)) {

    my ($fileorref, $x, $y, $w, $h) = @_;

    if (!_IsNo($fileorref)) {
      $fileorref = $self->Image($fileorref);
      unless (defined($fileorref)) { return undef; }
    }

    _GetEnhSize($self->{dc}, $fileorref, $width, $height, $self->{unit});
    $width = $self->_xp2un($width);
    $height = $self->_yp2un($height);

    if ((!defined($w)) or ($w == 0)) { $w = $width; }
    if ((!defined($h)) or ($h == 0)) { $h = $height; }

    unless (_PlayEnhMetaFile($self->{dc}, $fileorref, $self->_xun2p($x), $self->_yun2p($y), $self->_xun2p($x + $w), $self->_yun2p($y + $h))) {
      _croak "ERROR: Cannot display metafile! ${\_GetLastError()}";
      return undef;
    }

    return wantarray ? ($fileorref, $width, $height) : $fileorref;

  } else {

    my $file = shift;

    if (_IsNo($file)) {
      _GetEnhSize($self->{dc}, $file, $width, $height, $self->{unit});
      $width = $self->_xp2un($width);
      $height = $self->_yp2un($height);
      return ($width, $height);
    }

    if (defined($self->{imagef}->{$file})) {
      _GetEnhSize($self->{dc}, $self->{imagef}->{$file}, $width, $height, $self->{unit});
      $width = $self->_xp2un($width);
      $height = $self->_yp2un($height);
      return wantarray ? ($self->{imagef}->{$file}, $width, $height) : $self->{imagef}->{$file};
    }

    my $fref;

    if ($file =~ /.emf$/) {
      $fref = _GetEnhMetaFile($file);
      unless ($fref) {
        _croak "ERROR: Cannot load metafile! ${\_GetLastError()}";
        return undef;
      }
    } elsif ($file =~ /.wmf$/) {
      $fref = _GetWinMetaFile($self->{dc}, $file);
      unless ($fref) {
        _croak "ERROR: Cannot load metafile! ${\_GetLastError()}";
        return undef;
      }
    } else {

      $fref = _LoadBitmap($self->{dc}, $file, -1, $self->{unit});

      unless ($fref) {
        _croak "ERROR: Cannot load bitmap! ${\_GetLastError()}";
        return undef;
      }

    }

    $self->{imager}->{$fref} = $file;
    $self->{imagef}->{$file} = $fref;

    _GetEnhSize($self->{dc}, $fref, $width, $height, $self->{unit});
    $width = $self->_xp2un($width);
    $height = $self->_yp2un($height);
    return wantarray ? ($fref, $width, $height) : $fref;

  }

}

#------------------------------------------------------------------------------#

sub Meta {

  my $self = shift;

  if ($#_ > 2) { _carp "WARNING: Too many actual parameters!\n"; }

  if ($self->{emfstate}) {
    _croak qq^ERROR: There is allready started EMF!\n^;
  }

  my $fname = shift;
  my $width = shift;
  my $height = shift;

  if ($fname) {
    my $prompt;
    if ($fname =~ s/^FILE://i) { $prompt = 1; }

    $fname =~ s/\//\\/g;
    while (-f $fname) { 
      if ($fname !~ s/(.*\\*)(.*)\((\d+)\)(.*)\./my $i = $3; $i++; "$1$2($i)."/e) {
        $fname =~ s/(.*\\*)(.*)\./$1$2(1)\./
      }
    }
    my $file = $fname;
    $file =~ s/(.*\\)//g;
    my $dir = $1;
    unless ($dir) { $dir = '.\\'; }
    if ($prompt) {
      $fname = _SaveAs(3, $file, $dir);
    }
    if (($file =~ /[\"\*\/\:\<\>\?\\\|]|[\x00-\x1f]/) or (!(-d $dir))) {
      _croak "ERROR: Cannot create printer object! Invalid filename\n";
      return undef;
    }
  } else {
    $fname = "";
  }

  $_numcroaked = 0;
  _num($width);
  _num($height);
  return undef if $_numcroaked;

  if (!defined($width) or !defined($height)) {
    $width = 0;
    $height = 0;
  } else {
    $self->{emfw} = $width;
    $self->{emfh} = $height;
  }

  if (($width > 0) and ($height > 0)) {
    if (defined($self->{params}->{'unit'})) {
      if ($self->{params}->{'unit'} eq "mm") {
        $width *= 100;
        $height *= 100;
      } elsif ($self->{params}->{'unit'} eq "cm") {
        $width *= 1000;
        $height *= 1000;
      } elsif ($self->{params}->{'unit'} eq "pt") {
        $width *= 2540.9836 / 72;
        $height *= 2540.9836 / 72;
      } elsif ($self->{params}->{'unit'} =~ /^\d+\.*\d*$/i) {
        $width *= 2540.9836 / $self->{params}->{'unit'};
        $height *= 2540.9836 / $self->{params}->{'unit'};
      } else {
        $width *= 2540.9836;
        $height *= 2540.9836;
      }
    } else {
      $width *= 2540.9836;
      $height *= 2540.9836;
    }
  } elsif (($width < 0) and ($height < 0)) {
    _croak qq^ERROR: height, width must be positive values!\n^;
  }

  my $meta = _CreateMeta($self->{dc}, $fname, $width, $height);
  if ($meta) {
    $self->{emfstate} = 1;
    $self->{dc} = $meta;
  } else {
    _croak "ERROR: Cannot begin EMF! ${\_GetLastError()}";
    return undef;
  }

  if (_CopyTextColor($self->{odc}, $self->{dc}) =~ /-/) {
    _croak "ERROR: Cannot set default color!\n";
    return undef;
  }
  unless (_CopyObject($self->{odc}, $self->{dc}, 1)) {
    _croak "ERROR: Cannot select pen!\n";
    return undef;
  }
  unless (_CopyObject($self->{odc}, $self->{dc}, 2)) {
    _croak "ERROR: Cannot select brush!\n";
    return undef;
  }
  unless (_CopyObject($self->{odc}, $self->{dc}, 6)) {
    _croak "ERROR: Cannot select font!\n";
    return undef;
  }

  $self->{emfname} = $fname;
  return $fname;

}

#------------------------------------------------------------------------------#

sub MetaEnd {

  my $self = shift;

  if ($#_ > -1) { _carp "WARNING: Too many actual parameters!\n"; }

  if (!$self->{emfstate}) {
    _croak qq^ERROR: There is no beginning of the EMF!\n^;
  }

  my $return = _CloseMeta($self->{dc});
  if ($return) {
    $self->{emfstate} = 0;
    $self->{dc} = $self->{odc};
    $self->{imager}->{$return} = 0;

    my ($width, $height) = (0, 0);
    _GetEnhSize($self->{dc}, $return, $width, $height, $self->{unit});
    $width = $self->_xp2un($width);
    $height = $self->_yp2un($height);

    return wantarray ? ($return, $width, $height) : $return;

  } else {
    _croak "ERROR: Cannot end EMF! ${\_GetLastError()}";
    return undef;
  }

}

#------------------------------------------------------------------------------#

sub Caps {

  my $self = shift;

  if ($#_ < 0) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }
  if ($#_ > 0) {
    _carp "WARNING: Too many actual parameters!\n";
    return undef;
  }

  my $index = shift;
  $_numcroaked = 0;
  _num($index);
  return undef if $_numcroaked;

  return _GetDeviceCaps($self->{dc}, $index);

}

#------------------------------------------------------------------------------#

sub Close {

  my $self = shift;

  if ($#_ > 0) { _carp "WARNING: Too many actual parameters!\n"; }

  if ($#_ == 0) {
    if (_IsNo($_[0])) {
      if (_DeleteEnhMetaFile($_[0])) {
        delete $self->{imagef}->{$self->{imager}->{$_[0]}};
        delete $self->{imager}->{$_[0]};
      }
    } else {
      if (my $file = _DeleteEnhMetaFile($self->{imagef}->{$_[0]})) {
        delete $self->{imagef}->{$_[0]};
        delete $self->{imager}->{$file};
      }
    }
  } else {

    $self->MetaEnd() if $self->{emfstate};

    for (keys %{$self->{obj}}) {
     _DeleteObject($self->{obj}->{$_});
    } 

    for (keys %{$self->{imager}}) {
      _DeleteEnhMetaFile($_);
    }

    if ($self->{dc}) {
      _EndPage($self->{dc});
      if (_EndDoc($self->{dc}) > 0) {
        unless($self->_pdf()) {
          _croak "ERROR: Cannot create PDF document! ${\_GetLastError()}";
          return undef;
        }
      }
      _DeleteDC($self->{dc});
    }

    undef $self->{dc};
    if (defined($self->{params}->{'file'})) { return $self->{params}->{'file'}; }

  }

  return 1;

}

#------------------------------------------------------------------------------#

sub Inject {

  my $self = shift;

  if ($#_ != 2) {
    _croak "ERROR: Wrong number of parameters!\n";
    return undef;
  }

  my ($point, $page, $data) = @_;

  $_numcroaked = 0;
  _num($point);
  _num($page);
  return undef if $_numcroaked;

  _Inject($self->{dc}, $point, $page, $data);

  return 1;

}

#------------------------------------------------------------------------------#

sub ImageSave {

  my $self = shift;

  if ($#_ < 1) {
    _croak "ERROR: Not enough actual parameters!\n";
    return undef;
  }
  if ($#_ > 6) {
    _carp "WARNING: Too many actual parameters!\n";
    return undef;
  }

  my ($handle, $fname, $bpp, $width, $height, $format, $flag) = @_;

  $_numcroaked = 0;
  _num($handle);
  _num($format);
  $bpp = 24 unless _num($bpp);
  $flag= 0 unless _num($flag);
  $format= -1 unless _num($format);

  if (!_num($width) || !_num($height) || ($width <= 0) || ($height <= 0)) {
    $width = 0;
    $height = 0;
    _GetEnhSize($self->{dc}, $handle, $width, $height, $self->{unit});
  }

  return undef if $_numcroaked;

  my $prompt;
  if ($fname =~ s/^FILE://i) { $prompt = 1; }

  $fname =~ s/\//\\/g;
  while (-f $fname) { 
    if ($fname !~ s/(.*\\*)(.*)\((\d+)\)(.*)\./my $i = $3; $i++; "$1$2($i)."/e) {
      $fname =~ s/(.*\\*)(.*)\./$1$2(1)\./
    }
  }
  my $file = $fname;
  $file =~ s/(.*\\)//g;
  my $dir = $1;
  unless ($dir) { $dir = '.\\'; }
  if ($prompt) {
    $fname = _SaveAs(4, $file, $dir);
  }
  if (($file =~ /[\"\*\/\:\<\>\?\\\|]|[\x00-\x1f]/) or (!(-d $dir))) {
    _croak "ERROR: Cannot create printer object! Invalid filename\n";
    return undef;
  }

  my $rerr = _EmfH2BMP($self->{dc}, $handle, $fname, $width, $height, $format, $flag, $bpp);
  if ($rerr == 1) {
    return $fname;
  } elsif ($rerr ==  0) {
    _croak "ERROR: Cannot save image! ${\_GetLastError()}";
  } elsif ($rerr == -1) {
    _croak "ERROR: Cannot save image! (Unable to guess filetype)\n";
  } elsif ($rerr == -2) {
    _croak "ERROR: Cannot save image! (Bits not supported)\n";
  } elsif ($rerr == -3) {
    _croak "ERROR: Cannot save image! (Image format not supported)\n";
  }

  return undef;

}

#------------------------------------------------------------------------------#

sub DESTROY {

  my $self = shift;

  if ($self->{dc}) {
    _AbortDoc($self->{dc});
    $self->Close();
  }

  return 1;

}

#------------------------------------------------------------------------------#

1;

__END__

#line 4807
