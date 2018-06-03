#line 1 "Bio/Root/Utilities.pm"
#-----------------------------------------------------------------------------
# PACKAGE : Bio::Root::Utilities.pm
# PURPOSE : Provides general-purpose utilities of potential interest to any Perl script.
# AUTHOR  : Steve Chervitz (sac@bioperl.org)
# CREATED : Feb 1996
# REVISION: $Id: Utilities.pm,v 1.21 2002/10/22 07:38:37 lapp Exp $
# STATUS  : Alpha
#
# This module manages file compression and uncompression using gzip or
# the UNIX compress programs (see the compress() and uncompress() methods).
# Also, it can create filehandles from gzipped files. If you want to use a
# different compression utility (such as zip, pkzip, stuffit, etc.) you
# are on your own.
#
# If you manage to incorporate an alternate compression utility into this
# module, please post a note to the bio.perl.org mailing list
# bioperl-l@bioperl.org
#
# TODO    : Configure $GNU_PATH during installation.
#           Improve documentation (POD).
#           Make use of Date::Manip and/or Date::DateCalc as appropriate.
#
# MODIFICATIONS: See bottom of file.
#
# Copyright (c) 1996-2000 Steve Chervitz. All Rights Reserved.
#          This module is free software; you can redistribute it and/or 
#          modify it under the same terms as Perl itself.
#
#-----------------------------------------------------------------------------

package	Bio::Root::Utilities;
use strict;

BEGIN {
    use vars qw($Loaded_POSIX $Loaded_IOScalar);
    $Loaded_POSIX = 1;
    unless( eval "require POSIX" ) {
	$Loaded_POSIX = 0;
    }
}

use Bio::Root::Global  qw(:data :std $TIMEOUT_SECS);
use Bio::Root::Object  ();
use Exporter           ();
#use AutoLoader;
#*AUTOLOAD = \&AutoLoader::AUTOLOAD;

use vars qw( @ISA @EXPORT_OK %EXPORT_TAGS );
@ISA         = qw( Bio::Root::Root Exporter);
@EXPORT_OK   = qw($Util);
%EXPORT_TAGS = ( obj => [qw($Util)],
		 std => [qw($Util)],);

use vars qw($ID $VERSION $Util $GNU_PATH $DEFAULT_NEWLINE);

$ID        = 'Bio::Root::Utilities';
$VERSION   = 0.05;

# $GNU_PATH points to the directory containing the gzip and gunzip 
# executables. It may be required for executing gzip/gunzip 
# in some situations (e.g., when $ENV{PATH} doesn't contain this dir.
# Customize $GNU_PATH for your site if the compress() or
# uncompress() functions are generating exceptions.
$GNU_PATH  = ''; 
#$GNU_PATH  = '/tools/gnu/bin/'; 

$DEFAULT_NEWLINE = "\012";  # \n  (used if get_newline() fails for some reason)

## Static UTIL object.
$Util = {};
bless $Util, $ID;
$Util->{'_name'} = 'Static Utilities object';

## POD Documentation:

#line 175

#
##
###
#### END of main POD documentation.
###
##
#'


#line 193


############################################################################
##                 INSTANCE METHODS                                       ##
############################################################################

#line 252

#---------------'
sub date_format {
#---------------
    my $self   = shift;
    my $option = shift;
    my $date   = shift;  # optional date to be converted.

    my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);

    $option ||= 'yyyy-mm-dd';

    my ($month_txt, $day_txt, $month_num, $fullYear);
    my (@date);

    # Load a supplied date for conversion:
    if(defined($date) && ($date =~ /[\D-]+/)) {
	if( $date =~ /\//) {
	    ($mon,$mday,$year) = split(/\//, $date); 
	} elsif($date =~ /(\d{4})-(\d{1,2})-(\d{1,2})/) {
	    ($year,$mon,$mday) = ($1, $2, $3);
	} elsif($date =~ /(\d{4})-(\w{3,})-(\d{1,2})/) {
	    ($year,$mon,$mday) = ($1, $2, $3);
	    $mon = $self->month2num($2);
	} else {
	    print STDERR "\n*** Unsupported input date format: $date\n";
	}
	if(length($year) == 4) { $year = substr $year, 2; }
	$mon -= 1;
    } else {
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = @date =
	    localtime(($date ? $date : time()));
	return @date if $option =~ /list/i;
    }
    $month_txt = $MONTHS[$mon];
    $day_txt   = $DAYS[$wday] if defined $wday;
    $month_num = $mon+1;
    $fullYear = $BASE_YEAR+$year; 

#    print "sec: $sec, min: $min, hour: $hour, month: $mon, m-day: $mday, year: $year\nwday: $wday, yday: $yday, dst: $isdst";<STDIN>;

    if( $option =~ /yyyy-mm-dd/i ) {
	$date = sprintf "%4d-%02d-%02d",$fullYear,$month_num,$mday;
    } elsif( $option =~ /yyyy-dd-mm/i ) {
	$date = sprintf "%4d-%02d-%02d",$fullYear,$mday,$month_num;
    } elsif( $option =~ /yyyy-mmm-dd/i ) {
	$date = sprintf "%4d-%3s-%02d",$fullYear,$month_txt,$mday;
    } elsif( $option =~ /full|unix/i ) {
	$date = sprintf "%3s %3s %2d %02d:%02d:%02d %d",$day_txt, $month_txt, $mday, $hour, $min, $sec, $fullYear;
    } elsif( $option =~ /mdy/i ) {
	$date = "$month_txt $mday, $fullYear";
    } elsif( $option =~ /ymd/i ) {
	$date = $year."\l$month_txt$mday";
    } elsif( $option =~ /dmy/i ) {
	$date = $mday."\l$month_txt$year";
    } elsif( $option =~ /md/i ) {
	$date = "\l$month_txt$mday";
    } elsif( $option =~ /d-m-y/i ) {
	$date = "$mday-$month_txt-$fullYear";
    } elsif( $option =~ /d m y/i ) {
	$date = "$mday $month_txt $fullYear";
    } elsif( $option =~ /year/i ) {
	$date = $fullYear;
    } elsif( $option =~ /dmy/i ) {
	$date = $mday.'-'.$month_txt.'-'.$fullYear;
    } elsif($option and $option !~ /hms/i) {
	print STDERR "\n*** Unrecognized date format request: $option\n";
    }
    
    if( $option =~ /hms/i) {
	$date .= " $hour:$min:$sec" if $date;
	$date ||= "$hour:$min:$sec";
    }

    return $date || join(" ", @date);
}


#line 341

#--------------'
sub month2num {
#--------------

    my ($self, $str) = @_;

    # Get string in proper format for conversion.
    $str = substr($str, 0, 3);
    for(0..$#MONTHS) {
	return $_+1 if $str =~ /$MONTHS[$_]/i;
    } 
    $self->throw("Invalid month name: $str");
}

#line 365

#-------------
sub num2month {
#-------------
    my ($self, $num) = @_;

    $self->throw("Month out of range: $num") if $num < 1 or $num > 12;
    return $MONTHS[$num];
}

#line 404

#------------'
sub compress {
#------------
    my $self = shift;
    my $fileName = shift;  
    my $tmp = shift || 0;  

    if($fileName =~ /(\.gz|\.Z)$/) { $fileName =~ s/$1$//; };
    $DEBUG && print STDERR "gzipping file $fileName";

    my ($compressed, @args);

    if($tmp or not -o $fileName) {
	if($Loaded_POSIX) {
	    $compressed = POSIX::tmpnam;
	} else {
	    $compressed = _get_pseudo_tmpnam();
	}
	$compressed .= ".tmp.bioperl";
	$compressed .= '.gz';
	@args = ($GNU_PATH."gzip -f < $fileName > $compressed");
	not $tmp and 
	    $self->warn("Not owner of file $fileName\nCompressing to tmp file $compressed.");
	$tmp = 1;
    } else {
	$compressed = "$fileName.gz";
	@args = ($GNU_PATH.'gzip', '-f', $fileName);
    }

    if(system(@args) != 0) {
	# gzip may not be present. Try compress.
	$compressed = "$fileName.Z";
	if($tmp) {
	    @args = ("/usr/bin/compress -f < $fileName > $compressed");
	} else {
	    @args = ('/usr/bin/compress', '-f', $fileName);
	}	    
	system(@args) == 0 or 
	    $self->throw("Failed to gzip/compress file $fileName: $!",
			 "Confirm current \$GNU_PATH: $GNU_PATH",
			 "Edit \$GNU_PATH in Bio::Root::Utilities.pm if necessary.");
    }

    return $compressed;
}


#line 481

#---------------
sub uncompress {
#---------------
    my $self = shift;
    my $fileName = shift;  
    my $tmp = shift || 0;  

    if(not $fileName =~ /(\.gz|\.Z)$/) { $fileName .= '.gz'; }
    $DEBUG && print STDERR "gunzipping file $fileName";

    my($uncompressed, @args);

    if($tmp or not -o $fileName) {
	if($Loaded_POSIX) {
	    $uncompressed = POSIX::tmpnam;
	} else {
	    $uncompressed = _get_pseudo_tmpnam();
	}
	$uncompressed .= ".tmp.bioperl";
	@args = ($GNU_PATH."gunzip -f < $fileName > $uncompressed");
	not $tmp and $self->verbose > 0 and
	    $self->warn("Not owner of file $fileName\nUncompressing to tmp file $uncompressed.");
	$tmp = 1;
    } else {
	@args = ($GNU_PATH.'gunzip', '-f', $fileName);
	($uncompressed = $fileName) =~ s/(\.gz|\.Z)$//;
    }

#    $ENV{'PATH'} = '/tools/gnu/bin';

    if(system(@args) != 0) {
	# gunzip may not be present. Try uncompress.
	($uncompressed = $fileName) =~ s/(\.gz|\.Z)$//;
	if($tmp) {
	    @args = ("/usr/bin/uncompress -f < $fileName > $uncompressed");
	} else {
	    @args = ('/usr/bin/uncompress', '-f', $fileName);
	}	    
	system(@args) == 0 or
	    $self->throw("Failed to gunzip/uncompress file $fileName: $!",
			 "Confirm current \$GNU_PATH: $GNU_PATH",
			 "Edit \$GNU_PATH in Bio::Root::Utilities.pm if necessary."); 
    }
    
    return $uncompressed;
}


#line 544

#--------------
sub file_date {
#--------------
    my ($self, $file, $fmt) = @_;

    $self->throw("No such file: $file") if not $file or not -e $file;

    $fmt ||= 'yyyy-mm-dd';

    my @file_data = stat($file);
    return $self->date_format($fmt, $file_data[9]); # mtime field
}


#line 581

#------------`
sub untaint {
#------------	
    my($self,$value,$relax) = @_;
    $relax ||= 0;
    my $untainted;

    $DEBUG and print STDERR "\nUNTAINT: $value\n";
    
    defined $value || return;

    if( $relax ) {
	$value =~ /([-\w.\', ()\/=%:^<>*]+)/;
	$untainted = $1
#    } elsif( $relax == 2 ) {  # Could have several degrees of relax.
#	$value =~ /([-\w.\', ()\/=%:^<>*]+)/;
#	$untainted = $1
    } else {
	$value =~ /([-\w.\', ()]+)/;
	$untainted = $1
    }

    $DEBUG and print STDERR "UNTAINTED: $untainted\n";

    $untainted;
}


#line 620

#---------------
sub mean_stdev {
#---------------
    my ($self, @data) = @_;
    my $mean = 0;
    foreach (@data) { $mean += $_; }
    $mean /= scalar @data;
    my $sum_diff_sqd = 0;
    foreach (@data) { $sum_diff_sqd += ($mean - $_) * ($mean - $_); }
    my $stdev = sqrt(abs($sum_diff_sqd/(scalar @data)-1));
    return ($mean, $stdev);
}


#line 656

#----------------
sub count_files {
#----------------
    my $self = shift;
    my $href = shift;   # Reference to an empty hash.
    my( $name, @fileLine);
    my $dir = $$href{-DIR} || './';
    my $print = $$href{-PRINT} || 0;
    
    ### Make sure $dir ends with /
    $dir !~ /\/$/ and do{ $dir .=  '/'; $$href{-DIR} = $dir; };
    
    open ( PIPE, "ls -1 $dir |" ) || $self->throw("Can't open input pipe: $!");

    ### Initialize the hash data.
    $$href{-TOTAL} = 0;
    $$href{-NUM_TEXT_FILES} = $$href{-NUM_BINARY_FILES} = $$href{-NUM_DIRS} = 0;
    $$href{-T_FILE_NAMES} = [];
    $$href{-B_FILE_NAMES} = [];
    $$href{-DIR_NAMES} = [];
    while( <PIPE> ) {
	chomp();
	$$href{-TOTAL}++;
	if( -T $dir.$_ ) {
	    $$href{-NUM_TEXT_FILES}++; push @{$$href{-T_FILE_NAMES}}, $_; }
	if( -B $dir.$_ and not -d $dir.$_) {
	    $$href{-NUM_BINARY_FILES}++; push @{$$href{-B_FILE_NAMES}}, $_; }
	if( -d $dir.$_ ) {
	    $$href{-NUM_DIRS}++; push @{$$href{-DIR_NAMES}}, $_; }
    }
    close PIPE;
    
    if( $print) {
	printf( "\n%4d %s\n", $$href{-TOTAL}, "total files+dirs in $dir");
	printf( "%4d %s\n", $$href{-NUM_TEXT_FILES}, "text files");
	printf( "%4d %s\n", $$href{-NUM_BINARY_FILES}, "binary files");
	printf( "%4d %s\n", $$href{-NUM_DIRS}, "directories");
    }
}


#=head2 file_info
#
# Title   : file_info 
# Purpose : Obtains a variety of date for a given file.
#	  : Provides an interface to Perl's stat().
# Status  : Under development. Not ready. Don't use!
#
#=cut

#--------------
sub file_info {
#--------------
    my ($self, %param) = @_;
    my ($file, $get, $fmt) = $self->_rearrange([qw(FILE GET FMT)], %param);
    $get ||= 'all';
    $fmt ||= 'yyyy-mm-dd';

    my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size,
       $atime, $mtime, $ctime, $blksize, $blocks) = stat $file;

    if($get =~ /date/i) {
	## I can  get the elapsed time since the file was modified but
	## it's not so straightforward to get the date in a nice format...
        ## Think about using a standard CPAN module for this, like
        ## Date::Manip or Date::DateCalc.

	my $date = $mtime;
	my $elsec = time - $mtime;
	printf "\nFile age: %.0f sec %.0f hrs %.0f days", $elsec, $elsec/3600, $elsec/(3600*24);<STDIN>;
	my $days = sprintf "%.0f", $elsec/(3600*24);
    } elsif($get eq 'all') {
	return stat $file;
    }
}


#------------
sub delete { 
#------------
  my $self = shift; 
  my $fileName = shift;
  if(not -e $fileName) {
    $self->throw("Can't delete file $fileName: Does not exist."); 
  } elsif(not -o $fileName) {
    $self->throw("Can't delete file $fileName: Not owner."); 
  } 
  my $ulval = unlink($fileName) > 0 or
    $self->throw("Failed to delete file $fileName: $!"); 
}


#line 777

#---------------------
sub create_filehandle {
#---------------------
    my($self, @param) = @_;
    my($client, $file, $handle) =
	$self->_rearrange([qw( CLIENT FILE HANDLE )], @param);

    if(not ref $client) {  $client = $self; }
    $file ||= $handle;
    if( $client->can('file')) {
	$file = $client->file($file);
    }

    my $FH; # = new FileHandle;

    my ($handle_ref);
    
    if($handle_ref = ref($file)) {
      if($handle_ref eq 'FileHandle') {
	$FH = $file;
	$client->{'_input_type'} = "FileHandle";
      } elsif($handle_ref eq 'GLOB') {
	$FH = $file;
	$client->{'_input_type'} = "Glob";
      } else {
	$self->throw("Can't read from $file: Not a FileHandle or GLOB ref.");
      }
      $self->verbose > 0 and printf STDERR "$ID: reading data from FileHandle\n";

    } elsif($file) {
      $client->{'_input_type'} = "FileHandle for $file";

      # Use gzip -cd to access compressed data.
      if( -B $file ) {
	$client->{'_input_type'} .= " (compressed)";
	$file = "${GNU_PATH}gzip -cd $file |"
      }
      
      $FH = new FileHandle;
      open ($FH, $file) || $self->throw("Can't access data file: $file",
					"$!");
      $self->verbose > 0 and printf STDERR "$ID: reading data from file $file\n";

    } else {
      # Read from STDIN.
      $FH = \*STDIN;
      $self->verbose > 0 and printf STDERR "$ID: reading data from STDIN\n";
      $client->{'_input_type'} = "STDIN";
    }
    
    return $FH;
  }

#line 845

#-----------------
sub get_newline {
#-----------------
    my($self, @param) = @_;

    return $NEWLINE if defined $NEWLINE;

    my($client ) =
	$self->_rearrange([qw( CLIENT )], @param);

    my $FH = $self->create_filehandle(@param);

    if(not ref $client) {  $client = $self;   }

    if($client->{'_input_type'} =~ /STDIN|Glob|compressed/) {
      # Can't taste from STDIN since we can't seek 0 on it.
      # Are other non special Glob refs seek-able? 
      # Attempt to guess newline based on platform.
      # Not robust since we could be reading Unix files on a Mac, e.g.
      if(defined $ENV{'MACPERL'}) {
	$NEWLINE = "\015";  # \r
      } else {
	$NEWLINE = "\012";  # \n
      }	
    } else {
      $NEWLINE = $self->taste_file($FH);
    }

    close ($FH) unless ($client->{'_input_type'} eq 'STDIN' || 
                        $client->{'_input_type'} eq 'FileHandle' ||
                        $client->{'_input_type'} eq 'Glob' );
    
    delete $client->{'_input_type'};

    return $NEWLINE || $DEFAULT_NEWLINE;
  }


#line 903

#---------------
sub taste_file {
#---------------
  my ($self, $FH) = @_; 
  my $BUFSIZ = 256;   # Number of bytes read from the file handle.
  my ($buffer, $octal, $str, $irs, $i);
  my $wait = $TIMEOUT_SECS;
  
  ref($FH) eq 'FileHandle' or $self->throw("Can't taste file: not a FileHandle ref");

  $buffer = '';

  # this is a quick hack to check for availability of alarm(); just copied
  # from Bio/Root/IOManager.pm HL 02/19/01
  my $alarm_available = 1;
  eval {
      alarm(0);
  };
  if($@) {
      # alarm() not available (ActiveState perl for win32 doesn't have it.
      # See jitterbug PR#98)
      $alarm_available = 0;
  }
  $SIG{ALRM} = sub { die "Timed out!"; };
  my $result;
  eval {
    $alarm_available && alarm( $wait );
    $result = read($FH, $buffer, $BUFSIZ); # read the $BUFSIZ characters of file
    $alarm_available && alarm(0);
  };
  if($@ =~ /Timed out!/) {
    $self->throw("Timed out while waiting for input.", 
		 "Timeout period = $wait seconds.\nFor longer time before timing out, edit \$TIMEOUT_SECS in Bio::Root::Global.pm.");	

  } elsif(not $result) {
    my $err = $@;
    $self->throw("read taste failed to read from FileHandle.", $err);

  } elsif($@ =~ /\S/) {
    my $err = $@;
    $self->throw("Unexpected error during read: $err");
  }

  seek($FH, 0, 0) or $self->throw("seek failed to seek 0 on FileHandle.");

  my @chars = split(//, $buffer);

  for ($i = 0; $i <$BUFSIZ; $i++) {
    if (($chars[$i] eq "\012")) {
      unless ($chars[$i-1] eq "\015") {
	# Unix
	$octal = "\012";
	$str = '\n';
	$irs = "^J";
	last;
      }
    } elsif (($chars[$i] eq "\015") && ($chars[$i+1] eq "\012")) {
      # DOS
      $octal = "\015\012";
      $str = '\r\n';
      $irs = "^M^J";
      last;
    } elsif (($chars[$i] eq "\015")) {
      # Mac
      $octal = "\015";
      $str = '\r';
      $irs = "^M";
      last;
    }
  }
  if (not $octal) {
    $self->warn("Could not determine newline char. Using '\012'");
    $octal = "\012";
  } else {
#    print STDERR "NEWLINE CHAR = $irs\n";
  }
  return($octal);
}

######################################
#####     Mail Functions      ########
######################################

#line 996

sub mail_authority {
    
    my( $self, $message ) = @_;
    my $script = $self->untaint($0,1);

    send_mail( -TO=>$AUTHORITY, -SUBJ=>$script, -MSG=>$message);

}


#line 1032


#-------------'
sub send_mail {
#-------------
    my( $self, @param) = @_;
    my($recipient,$subj,$message,$cc) = $self->_rearrange([qw(TO SUBJ MSG CC)],@param);

    $self->throw("Invalid or missing e-mail address: $recipient") 
	if not $recipient =~ /\S+\@\S+/;

    $cc ||= ''; $subj ||= ''; $message ||= '';

    open (SENDMAIL, "|/usr/lib/sendmail -oi -t") || 
	$self->throw("Can't send mail: sendmail cannot fork: $!");

print SENDMAIL <<QQ_EOF_QQ;
To: $recipient
Subject: $subj
Cc: $cc

$message

QQ_EOF_QQ

    close(SENDMAIL);
    if ($?) { warn "sendmail didn't exit nicely: $?" }
}


######################################
###   Interactive Functions      #####
######################################


#line 1080

#-------------
sub yes_reply {
#-------------
    my $self = shift;
    my $query = shift;
    my $reply;
    $query ||= 'Yes or no';
    print "\n$query? (y/n) [n] ";
    chomp( $reply = <STDIN> );
    $reply =~ /^y/i;
}



#line 1108

#----------------
sub request_data {
#----------------
    my $self = shift;
    my $data = shift || 'data';
    print "Enter $data: ";
    # Remove the terminal newline char.
    chomp($data = <STDIN>);
    $data;
}

sub quit_reply {
# Not much used since you can use request_data() 
# and test for an empty string.
    my $self = shift;
    my $reply;
    chop( $reply = <STDIN> );
    $reply =~ /^q.*/i;
}


#line 1137

#------------------
sub verify_version {
#------------------
    my $self = shift;
    my $reqVersion  = shift;
    
    $] < $reqVersion and do { 
	printf STDERR ( "\a\n%s %0.3f.\n", "** Sorry. This Perl script requires at least version", $reqVersion);
	printf STDERR ( "%s %0.3f %s\n\n", "You are running Perl version", $], "Please update your Perl!\n\n" );
	exit(1);
    }
}

# Purpose : Returns a string that can be used as a temporary file name.
#           Based on localtime.
#           This is used if POSIX is not available.

sub _get_pseudo_tmpnam {

    my $date = localtime(time());
    
    my $tmpnam = 'tmpnam'; 

    if( $date =~ /([\d:]+)\s+(\d+)\s*$/ ) {
    	$tmpnam = $2. '_' . $1;
    	$tmpnam =~ s/:/_/g;
    }
    return $tmpnam;
}


1;
__END__

MODIFICATION NOTES:
---------------------

17 Feb 1999, sac:
  * Using global $TIMEOUT_SECS in taste_file().

13 Feb 1999, sac:
  * Renamed get_newline_char() to get_newline() since it could be >1 char.

3 Feb 1999, sac:
  * Added three new methods: create_filehandle, get_newline_char, taste_file.
    create_filehandle represents functionality that was formerly buried
    within Bio::Root::IOManager::read().

2 Dec 1998, sac:
  * Removed autoloading code.
  * Modified compress(), uncompress(), and delete() to properly
    deal with file ownership issues.

3 Jun 1998, sac: 
    * Improved file_date() to be less reliant on the output of ls.
      (Note the word 'less'; it still relies on ls).

5 Jul 1998, sac:
    * compress() & uncompress() will write files to a temporary location
      if the first attempt to compress/uncompress fails.
      This allows users to access compressed files in directories in which they
      lack write permission.



