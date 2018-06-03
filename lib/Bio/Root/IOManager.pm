#line 1 "Bio/Root/IOManager.pm"
#-----------------------------------------------------------------------------
# PACKAGE : Bio::Root::IOManager.pm
# AUTHOR  : Steve Chervitz (sac@bioperl.org)
# CREATED : 26 Mar 1997
# REVISION: $Id: IOManager.pm,v 1.13 2002/10/22 07:38:37 lapp Exp $
# STATUS  : Alpha
#
# For documentation, run this module through pod2html
# (preferably from Perl v5.004 or better).
#
# MODIFICATION NOTES: See bottom of file.
#
# Copyright (c) 1997-2000 Steve Chervitz. All Rights Reserved.
#           This module is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
#-----------------------------------------------------------------------------

package Bio::Root::IOManager;

use Bio::Root::Global     qw(:devel $CGI $TIMEOUT_SECS);
use Bio::Root::Object     ();
use Bio::Root::Utilities  qw(:obj);
use FileHandle            ();

@ISA   = qw(Bio::Root::Object);

use strict;
use vars qw($ID $VERSION $revision);
$ID = 'Bio::Root::IOManager';
$VERSION = 0.043;

## POD Documentation:

#line 174

#
##
###
#### END of main POD documentation.
###
##
#'


#line 192



#####################################################################################
##                                 CONSTRUCTOR                                     ##
#####################################################################################


## Using default constructor and destructor inherited from Bio::Root::Object.pm

## Could perhaps set the file data member.


#####################################################################################
##                                 ACCESSORS                                       ##
#####################################################################################


#line 224

#--------
sub file {
#--------
    my $self = shift;
    if($_[0]) {
	my $file = $_[0];
	if(not ref $file and not -s $file) {
	    $self->throw("File is empty or non-existent: $file");
	}	
	$self->{'_file'} = $file;
    }
    $self->{'_file'};
}



#line 269

#-----------
sub set_fh {
#-----------
    my( $self, %param) = @_;

    no strict 'subs';
    my( $path, $prefix, $postfix, $which) =
	$self->_rearrange([PATH,PRE,POST,WHICH],%param);
    use strict 'subs';
    $prefix  ||= '';
    $postfix ||= '';
    $which   ||= '';
    my $fullpath = "$prefix$path$postfix";
    my($fh);

    $DEBUG and print STDERR "set_fh($fullpath) for ${\$self->name()}\n";

    if($which eq 'err') {
	if(ref($path) =~ /FileHandle|GLOB/ ) {
	    $fh = $path;
	} else {
	    if(defined $self->{'_fherr'}) { $self->_close_fh('err');}
	    if( not $fh = $self->_open_fh("$fullpath")) {
		$fh = $self->_open_fh("errors.$$");
		$fh || return;
		$self->warn("Couldn't set error output to $fullpath",
			    "Set to file errors.$$");
	    }
	}
	$self->{'_fherr_name'} = $fullpath;
	$self->{'_fherr'} = $fh;

    } else {
	if(ref($path) =~ /FileHandle|GLOB/ ) {
	    $fh = $path;
	} else {
	    if(defined $self->{'_fh'}) { $self->_close_fh();}
	    if( not $fh = $self->_open_fh("$fullpath")) {
		$fh = $self->_open_fh("out.$$");
		$fh || return;
		$self->warn("Couldn't set output to $fullpath",
			    "Set to file out.$$");
	    }
	}
	$self->{'_fh_name'} = $fullpath;
	$self->{'_fh'} = $fh;
	$DEBUG && print STDERR "$ID: set fh to: $fh";
    }
}



#=head2 _open_fh
#
# Purpose   : Creates a new FileHandle object and returns it.
#           : This method can be used when you need to
#           : pass FileHandles between objects.
# Returns   : The new FileHandle object.
# Throws    : Exception: if the call to new FileHandle fails.
# Examples  : $self->_open_fh();            # Create anonymous FileHandle object
#           : $self->_open_fh('fileName');  # Open for reading
#           : $self->_open_fh('>fileName'); # Open for writing
# Status    : Experimental
#
#See also   : L<set_fh()|set_fh>, L<fh()|fh>, L<set_read()|set_read>, L<set_display()|set_display>
#
#=cut

#-------------
sub _open_fh {
#-------------
    my( $self, $arg) = @_;
    my( $filehandle);

    $DEBUG and print STDERR "_open_fh() $arg\n";

    $filehandle = new FileHandle $arg;

#    if($arg =~ /STD[IO]/) {
#	$filehandle = new FileHandle;
#	$filehandle = *$arg;
#    } else {
#	 $filehandle = new FileHandle $arg;
#    }

    (ref $filehandle) || $self->throw("Can't create new FileHandle $arg",
				      "Cause: $!");
    return $filehandle;
}



#=head2 _close_fh
#
# Purpose   : Destroy a FileHandle object.
# Returns   : n/a
# Status    : Experimental
#
#See also   : L<_open_fh()|_open_fh>, L<set_fh()|set_fh>
#
#=cut

#--------------
sub _close_fh {
#--------------
    my( $self, $arg) = @_;
    $arg ||= '';
    if($arg eq 'err') {
	close $self->{'_fherr'};
	undef $self->{'_fherr'};
    } else {
	close $self->{'_fh'};
	undef $self->{'_fh'};
    }
}	


#line 426

#----------------'
sub set_display {
#----------------
    my( $self, @param ) = @_;
    my ($show, $where, $mode) = $self->_rearrange([qw(SHOW WHERE MODE)], @param);

    ## Default mode: overwrite any existing file.
    $mode  ||= '>';
    $where ||= 'STDOUT';

    $self->{'_show'} = ($show || 'default');

    $DEBUG and print STDERR "$ID set_display() show: $self->{'_show'}\twhere: -->$where<--\n";

    if( defined $where and $where !~ /STDOUT/) {
#	print "setting file handle object\n";
	$self->set_fh(-PATH =>$where,
		      -PRE  =>$mode);
    } elsif( not defined $self->{'_fh'} or $where =~ /STDOUT/)  {	
	return \*STDOUT;
    } else  {
#	print STDERR "filehandle already set for this object: ${\$self->fh('name')}\n";
    }

    return $self->{'_fh'};
}



#line 477

#-------------
sub set_read {
#-------------
    my( $self, @param ) = @_;
    my ($where, $mode) = $self->_rearrange([qw(WHERE MODE)], @param);

    ## Default mode: read only.
    $mode  ||= '<';
    $where ||= 'STDIN';

    if( ref($where) and $where !~ /STDIN/) {
#	print "setting file handle object\n";
	$self->set_fh(-PATH =>$where,
		      -PRE  =>$mode);
    } elsif( not defined $self->{'_fh'} or $where =~ /STDIN/)  {	
	return \*STDIN;
    } else  {
#	print STDERR "filehandle already set for this object: ${\$self->fh('name')}\n";
    }

    return $self->{'_fh'};
}



#line 515

#--------------------
sub set_display_err {
#--------------------
    my( $self, @param ) = @_;
    my ($where, $mode) = $self->_rearrange([qw(WHERE MODE)], @param);

    ## Default mode: read only.
    $mode  ||= '>>';
    $where ||= 'STDERR';

    $DEBUG and print STDERR "set_display_err() object: ${\$self->name()}\n";

    if( ref($where) and $where !~ /STDERR/) {
#	print "setting file handle object\n";
	$self->set_fh(-PATH =>$where,
		      -PRE  =>$mode);
    } elsif( not defined $self->{'_fherr'} or $where =~ /STDERR/)  {	
	return \*STDERR;
    } else  {
#	print STDERR "filehandle already set for this object: ${\$self->fh('name')}\n";
    }

    return $self->{'_fherr'};
}


#####################################
#    GET ACCESSORS
#####################################


#line 558

#----------
sub show { my $self= shift; $self->{'_show'}; }
#----------



#line 583

#--------'
sub fh {
#--------
    my( $self, $type, $stream) = @_;
    $stream ||= 'out';
    $stream = ($stream eq 'in') ? \*STDIN : \*STDOUT;

    ## Problem: Without named parameters, how do you know if
    ## a single argument is to be assigned to $type or $stream?
    ## Function prototypes could be used, or separate methods:
    ## fh_out(), fh_in(), fh_err().
    $type or return ($self->{'_fh'} || $stream);

    if( $type =~ /name/){
	if($type =~ /err/ ) { return $self->{'_fherr_name'}; }
	else                { return $self->{'_fh_name'}; }

    } else {
	if($type =~ /err/ ) { return ($self->{'_fherr'} || \*STDERR); }
	else                { return ($self->{'_fh'}    || $stream); }
    }
}


#####################################################################################
##                             INSTANCE METHODS                                    ##
#####################################################################################


##
##  INPUT METHODS:
##


#line 694

#----------'
sub read {
#----------
    my($self, @param) = @_;
    my( $rec_sep, $func_ref, $wait ) =
	$self->_rearrange([qw( REC_SEP FUNC WAIT)], @param);

    my $fmt = (wantarray ? 'list' : 'string');
    $wait ||= $TIMEOUT_SECS;  # seconds to wait before timing out.

    my $FH = $Util->create_filehandle( -client => $self, @param);

    # Set the record separator (if necessary) using dynamic scope.
    my $prev_rec_sep;
    $prev_rec_sep = $/  if scalar $rec_sep;  # save the previous rec_sep
    local $/ = $rec_sep if scalar $rec_sep;

    # Verify that we have a proper reference to a function.
    if($func_ref) {
	if(not ref($func_ref) =~ /CODE/) {
	    $self->throw("Not a function reference: $func_ref, ${\ref $func_ref}");
	}
    }

    $DEBUG && printf STDERR "$ID: read(): rec_sep = %s; func = %s\n",$/, ($func_ref?'defined':'none');

    my($data, $lines, $alarm_available);

    $alarm_available = 1;

    eval {
        alarm(0);
    };
    if($@) {
        # alarm() not available (ActiveState perl for win32 doesn't have it.
        # See jitterbug PR#98)
        $alarm_available = 0;
    }

    $SIG{ALRM} = sub { die "Timed out!"; };

    eval {
        $alarm_available and alarm($wait);

      READ_LOOP:
	while(<$FH>) {
	    # Default behavior: read all lines.
	    # If &$func_ref returns false, exit this while loop.
	    # Uncomment to skip lines with only white space or record separators
#	    next if m@^(\s*|$/*)$@;
	
	    $lines++;
            $alarm_available and alarm(0);  # Deactivate the alarm as soon as we start reading.
	    my($result);
	    if($func_ref) {
		# Need to reset $/ for any called function.
		local $/ = $prev_rec_sep if defined $prev_rec_sep;
		$result = &$func_ref($_) or last READ_LOOP;
	    } else {
		$data .= $_;
	    }
	}
    };
    if($@ =~ /Timed out!/) {
	 $self->throw("Timed out while waiting for input from $self->{'_input_type'}.", "Timeout period = $wait seconds.\nFor a longer time out period, supply a -wait => <seconds> parameter\n".
		     "or edit \$TIMEOUT_SECS in Bio::Root::Global.pm.");
    } elsif($@ =~ /\S/) {
        my $err = $@;
        $self->throw("Unexpected error during read: $err");
    }

    close ($FH) unless $self->{'_input_type'} eq 'STDIN';

    if($data) {
	$DEBUG && do{
	    print STDERR "$ID: $lines records read.\nReturning $fmt.\n" };

	return ($fmt eq 'list') ? split("$/", $data) : $data;

    } elsif(not $func_ref) {
	$self->throw("No data input from $self->{'_input_type'}");
    }
    delete $self->{'_input_type'};
    undef;
}


##
##  OUTPUT METHODS:
##


#line 801

#-------------
sub display {
#-------------
    my( $self, %param ) = @_;

    $DEBUG && print STDERR "$ID display for ${\ref($self)}\n";

    my $OUT = $self->set_display(%param);
#    my $OUT = $self->set_display( %param );
#    print "$ID: OUT = $OUT";<STDIN>;

    $DEBUG && do{ print STDERR "display(): WHERE = $OUT;\nSHOW = $self->{'_show'}";<STDIN>;};

    if($self->{'_show'} =~ /stats|default/i) {
	if($param{-HEADER}) {
	    $self->_print_stats_header($OUT);
	}
	$self->parent->_display_stats($OUT);
    }
    1;
}



#line 836

#------------------------
sub _print_stats_header {
#------------------------
    my($self, $OUT) = @_;

    printf $OUT "\nSTATS FOR %s \"%s\"\n",ref($self->parent),$self->parent->name();
    printf $OUT "%s\n", '-'x60;
}




##
##  FILE MANIPULATION METHODS:
##



#line 875

#---------------
sub file_date {
#---------------
    my ($self, @param) = @_;
    my ($file, $fmt) = $self->_rearrange([qw(FILE FMT)], @param);

    if(not $file ||= $self->{'_file'}) {
	$self->throw("Can't get file date: no file specified");
    }
    $fmt ||= '';
    $Util->file_date($file, $fmt);
}



#line 932

#-----------------
sub compress_file {
#-----------------
    my ($self, $file) = @_;
    my $myfile = 0;

    if(!$file) {
	$file = $self->{'_file'};
	$myfile = 1;
    }

    $file or $self->throw("Can't compress data file: no file specified");

    #printf STDERR "$ID: Compressing data file for %s\n  $file\n",$self->name();

    my ($newfile);
    if (-T $file) {
	$newfile = -o $file ? $Util->compress($file) : $Util->compress($file, 1);
	# set the current file to the new name.
	$self->file($newfile) if $myfile;
    }
    $newfile;
}



#line 987

#--------------------
sub uncompress_file {
#--------------------
    my ($self, $file) = @_;
    my $myfile = 0;

    if(!$file) {
	$file = $self->{'_file'};
	$myfile = 1;
    }

    $file or $self->throw("Can't compress file: no file specified");

    #printf STDERR "$ID: Uncompressing data file for %s\n  $file",$self->name();

    my ($newfile);
    if (-B $file) {
	$newfile = -o $file ? $Util->uncompress($file) : $Util->uncompress($file, 1);
	# set the current file to the new name & return it.
	$self->file($newfile) if $myfile;
    }
    $newfile;
}


#line 1036

#-----------------
sub delete_file {
#-----------------
    my ($self, $file) = @_;
    my $myfile = 0;

    if(!$file) {
	$file = $self->{'_file'};
	$myfile = 1;
    }
    return undef unless -e $file;

    -o $file or
	$self->throw("Can't delete file $file: Not owner.");

#    $DEBUG and print STDERR "$ID: Deleting data file for ",$self->name();

    eval{ $Util->delete($file); };

    if(!$@ and $myfile) {
	$self->{'_file'} = undef;
    }
    $file;
}



1;
__END__

#####################################################################################
#                                  END OF CLASS                                     #
#####################################################################################

#line 1113


MODIFICATION NOTES:
-------------------

17 Feb 1999, sac:
   * Using $Global::TIMEOUT_SECS

3 Feb 1999, sac:
   * Added timeout support to read().
   * Moved the FileHandle creation code out of read() and into
     Bio::Root::Utilties since it's of more general use.

 24 Nov 1998, sac:
   * Modified read(), compress(), and uncompress() to properly
     deal with file ownership issues.

 19 Aug 1998, sac:
   * Fixed bug in display(), which wasn't returning true (1).

 0.023, 20 Jul 1998, sac:
   * read() can now use a supplied FileHandle or GLOB ref (\*IN).
   * A few other touch-ups in read().

 0.022, 16 Jun 1998, sac:
   * read() now terminates reading when a supplied &$func_ref
     returns false.

 0.021, May 1998, sac:
   * Refined documentation to use 5.004 pod2html.
   * Properly using typglob refs as necessary
     (e.g., set_display(), set_fh()).

0.031, 2 Sep 1998, sac:
   * Doc changes only


