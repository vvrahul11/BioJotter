#line 1 "Win32/WebBrowser.pm"
package Win32::WebBrowser;

our %reg;

use Win32::TieRegistry(TiedHash => \%reg, Delimiter  => '/');
use Win32::Process;
use base qw(Exporter);

our @EXPORT = qw(open_browser);

use strict;
use warnings;

our $VERSION = '1.02';

#
#	open a web browser with our file
#	NOTE: this only works on Win32!!!
#
sub open_browser {
	my $url = shift;
#
# open the registry to find the path to the default browser
#
	my $cmdkey = $reg{ 'HKEY_CLASSES_ROOT/' . 
		$reg{'HKEY_CLASSES_ROOT/.htm//'} . 
			'/shell/open/command'};

	my $sysstr = $cmdkey->{'/'};
#
# replace the argument PH with our URL
#
	$url=~tr/\\/\//;
#	$url = "file://C:$url"
#		unless (substr($url, 0, 7) eq 'http://') ||
#			(substr($url, 0, 7) eq 'file://');

	$sysstr=~s/\-nohome//;
	
	if ($sysstr=~/%1/) {
		$sysstr =~ s!%1!$url!;
	}
	else {
		$sysstr .= " $url";
	}
	my $exe = $sysstr;
#
#	in case we get a fancy pathname, strip the
#	quotes
#
	if ($sysstr=~/^"/) {
		$exe=~s/^"([^"]+)"\s+.+$/$1/;
	}
	else {
		$exe=~s/^(\S+)\s+.+$/$1/;
	}
# start the browser...
	my $browser;
	return 1
		if Win32::Process::Create($browser,
    	   $exe,
    	   $sysstr,
    	   0,
    	   NORMAL_PRIORITY_CLASS|DETACHED_PROCESS,
    	   '.'
    	   );
	$@ = Win32::FormatMessage(Win32::GetLastError());
	return undef;
}

1;

#line 111