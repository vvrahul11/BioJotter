#line 1 "Bio/Root/IO.pm"
# $Id: IO.pm,v 1.37.2.3 2003/06/28 21:57:04 jason Exp $
#
# BioPerl module for Bio::Root::IO
#
# Cared for by Hilmar Lapp <hlapp@gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

#line 96


# Let the code begin...


package Bio::Root::IO;
use vars qw(@ISA $FILESPECLOADED $FILETEMPLOADED $FILEPATHLOADED
	    $TEMPDIR $PATHSEP $ROOTDIR $OPENFLAGS $VERBOSE);
use strict;

use Symbol;
use POSIX qw(dup);
use IO::Handle;
use Bio::Root::Root;

@ISA = qw(Bio::Root::Root);

my $TEMPCOUNTER;
my $HAS_WIN32 = 0;

BEGIN {
    $TEMPCOUNTER = 0;
    $FILESPECLOADED = 0;
    $FILETEMPLOADED = 0;
    $FILEPATHLOADED = 0;
    $VERBOSE = 1;

    # try to load those modules that may cause trouble on some systems
    eval { 
	require File::Path;
	$FILEPATHLOADED = 1;
    }; 
    if( $@ ) {
	print STDERR "Cannot load File::Path: $@" if( $VERBOSE > 0 );
	# do nothing
    }


    # If on Win32, attempt to find Win32 package

    if($^O =~ /mswin/i) {
	eval {
	    require Win32;
	    $HAS_WIN32 = 1;
	};
    }

    # Try to provide a path separator. Why doesn't File::Spec export this,
    # or did I miss it?
    if($^O =~ /mswin/i) {
	$PATHSEP = "\\";
    } elsif($^O =~ /macos/i) {
	$PATHSEP = ":";
    } else { # unix
	$PATHSEP = "/";
    }
    eval {
	require File::Spec;
	$FILESPECLOADED = 1;
	$TEMPDIR = File::Spec->tmpdir();
	$ROOTDIR = File::Spec->rootdir();
	require File::Temp; # tempfile creation
	$FILETEMPLOADED = 1;
    };
    if( $@ ) { 
	if(! defined($TEMPDIR)) { # File::Spec failed
	    # determine tempdir
	    if (defined $ENV{'TEMPDIR'} && -d $ENV{'TEMPDIR'} ) {
		$TEMPDIR = $ENV{'TEMPDIR'};
	    } elsif( defined $ENV{'TMPDIR'} && -d $ENV{'TMPDIR'} ) {
		$TEMPDIR = $ENV{'TMPDIR'};
	    }
	    if($^O =~ /mswin/i) {
		$TEMPDIR = 'C:\TEMP' unless $TEMPDIR;
		$ROOTDIR = 'C:';
	    } elsif($^O =~ /macos/i) {
		$TEMPDIR = "" unless $TEMPDIR; # what is a reasonable default on Macs?
		$ROOTDIR = ""; # what is reasonable??
	    } else { # unix
		$TEMPDIR = "/tmp" unless $TEMPDIR;
		$ROOTDIR = "/";
	    }
	    if (!( -d $TEMPDIR && -w $TEMPDIR )) {
		$TEMPDIR = '.'; # last resort
	    }
	}
	# File::Temp failed (alone, or File::Spec already failed)
	#
	# determine open flags for tempfile creation -- we'll have to do this
	# ourselves
	use Fcntl;
	use Symbol;
	$OPENFLAGS = O_CREAT | O_EXCL | O_RDWR;
	for my $oflag (qw/FOLLOW BINARY LARGEFILE EXLOCK NOINHERIT TEMPORARY/){
	    my ($bit, $func) = (0, "Fcntl::O_" . $oflag);
	    no strict 'refs';
	    $OPENFLAGS |= $bit if eval { $bit = &$func(); 1 };
	}
    }
}

#line 208

sub new {
    my ($caller, @args) = @_;
    my $self = $caller->SUPER::new(@args);

    $self->_initialize_io(@args);
    return $self;
}

#line 235

sub _initialize_io {
    my($self, @args) = @_;

    $self->_register_for_cleanup(\&_io_cleanup);

    my ($input, $noclose, $file, $fh, $flush) = $self->_rearrange([qw(INPUT 
							    NOCLOSE
							    FILE FH 
							    FLUSH)], @args);
    
    delete $self->{'_readbuffer'};
    delete $self->{'_filehandle'};
    $self->noclose( $noclose) if defined $noclose;
    # determine whether the input is a file(name) or a stream
    if($input) {
	if(ref(\$input) eq "SCALAR") {
	    # we assume that a scalar is a filename
	    if($file && ($file ne $input)) {
		$self->throw("input file given twice: $file and $input disagree");
	    }
	    $file = $input;
	} elsif(ref($input) &&
		((ref($input) eq "GLOB") || $input->isa('IO::Handle'))) {
	    # input is a stream
	    $fh = $input;
	} else {
	    # let's be strict for now
	    $self->throw("unable to determine type of input $input: ".
			 "not string and not GLOB");
	}
    }
    if(defined($file) && defined($fh)) {
	$self->throw("Providing both a file and a filehandle for reading - only one please!");
    }

    if(defined($file) && ($file ne '')) {
	$fh = Symbol::gensym();
	open ($fh,$file) ||
	    $self->throw("Could not open $file: $!");
	$self->file($file);
    }
    $self->_fh($fh) if $fh; # if not provided, defaults to STDIN and STDOUT

    $self->_flush_on_write(defined $flush ? $flush : 1);

    return 1;
}

#line 294

sub _fh {
    my ($obj, $value) = @_;
    if ( defined $value) {
	$obj->{'_filehandle'} = $value;
    }
    return $obj->{'_filehandle'};
}

#line 320

sub mode {
    my ($obj, @arg) = @_;
	my %param = @arg;
    return $obj->{'_mode'} if defined $obj->{'_mode'} and !$param{-force};

    print STDERR "testing mode... " if $obj->verbose;

    # we need to dup() the original filehandle because
    # doing fdopen() calls on an already open handle causes
    # the handle to go stale. is this going to work for non-unix
    # filehandles? -allen

    my $fh = Symbol::gensym();

    my $iotest = new IO::Handle;

    #test for a readable filehandle;
    $iotest->fdopen( dup(fileno($obj->_fh)) , 'r' );
    if($iotest->error == 0){

      # note the hack here, we actually have to try to read the line
      # and if we get something, pushback() it into the readbuffer.
      # this is because solaris and windows xp (others?) don't set
      # IO::Handle::error.  for non-linux the r/w testing is done
      # inside this read-test, instead of the write test below.  ugh.

      if($^O eq 'linux'){
        $obj->{'_mode'} = 'r';
        my $line = $iotest->getline;
        $obj->_pushback($line) if defined $line;
        $obj->{'_mode'} = defined $line ? 'r' : 'w';
        return $obj->{'_mode'};
      } else {
        my $line = $iotest->getline;
        $obj->_pushback($line) if defined $line;
        $obj->{'_mode'} = defined $line ? 'r' : 'w';
	return $obj->{'_mode'};
      }
    }
    $iotest->clearerr;

    #test for a writeable filehandle;
    $iotest->fdopen( dup(fileno($obj->_fh)) , 'w' );
    if($iotest->error == 0){
      $obj->{'_mode'} = 'w';
#      return $obj->{'_mode'};
    }

    #wtf type of filehandle is this?
#    $obj->{'_mode'} = '?';
    return $obj->{'_mode'};
}

#line 385

sub file {
    my ($obj, $value) = @_;
    if ( defined $value) {
	$obj->{'_file'} = $value;
    }
    return $obj->{'_file'};
}

#line 403

sub _print {
    my $self = shift;
    my $fh = $self->_fh() || \*STDOUT;
    print $fh @_;
}

#line 431

sub _readline {
    my $self = shift;
    my %param =@_;
    my $fh = $self->_fh || \*ARGV;
    my $line;

    # if the buffer been filled by _pushback then return the buffer
    # contents, rather than read from the filehandle
    $line = shift @{$self->{'_readbuffer'}} || <$fh>;

    #don't strip line endings if -raw is specified
    $line =~ s/\r\n/\n/g if( (!$param{-raw}) && (defined $line) );

    return $line;
}

#line 459

sub _pushback {
    my ($obj, $value) = @_;

	$obj->{'_readbuffer'} ||= [];
	push @{$obj->{'_readbuffer'}}, $value;
}

#line 477

sub close {
   my ($self) = @_;
   return if $self->noclose; # don't close if we explictly asked not to
   if( defined $self->{'_filehandle'} ) {
       $self->flush;
       return if( \*STDOUT == $self->_fh ||
		  \*STDERR == $self->_fh ||
		  \*STDIN == $self->_fh
		  ); # don't close STDOUT fh
       if( ! ref($self->{'_filehandle'}) ||
	   ! $self->{'_filehandle'}->isa('IO::String') ) {
	   close($self->{'_filehandle'});
       }
   }
   $self->{'_filehandle'} = undef;
   delete $self->{'_readbuffer'};
}


#line 506

sub flush {
  my ($self) = shift;
  
  if( !defined $self->{'_filehandle'} ) {
    $self->throw("Attempting to call flush but no filehandle active");
  }

  if( ref($self->{'_filehandle'}) =~ /GLOB/ ) {
    my $oldh = select($self->{'_filehandle'});
    $| = 1;
    select($oldh);
  } else {
    $self->{'_filehandle'}->flush();
  }
}
  
#line 536

sub noclose{
    my $self = shift;

    return $self->{'_noclose'} = shift if @_;
    return $self->{'_noclose'};
}

sub _io_cleanup {
    my ($self) = @_;

    $self->close();
    my $v = $self->verbose;

    # we are planning to cleanup temp files no matter what    
    if( exists($self->{'_rootio_tempfiles'}) &&
	ref($self->{'_rootio_tempfiles'}) =~ /array/i) { 
	if( $v > 0 ) {
	    print STDERR "going to remove files ", 
	    join(",",  @{$self->{'_rootio_tempfiles'}}), "\n";
	}
	unlink  (@{$self->{'_rootio_tempfiles'}} );
    }
    # cleanup if we are not using File::Temp
    if( $self->{'_cleanuptempdir'} &&
	exists($self->{'_rootio_tempdirs'}) &&
	ref($self->{'_rootio_tempdirs'}) =~ /array/i) {	

	if( $v > 0 ) {
	    print STDERR "going to remove dirs ", 
	    join(",",  @{$self->{'_rootio_tempdirs'}}), "\n";
	}
	$self->rmtree( $self->{'_rootio_tempdirs'});
    }
}

#line 588

sub exists_exe {
    my ($self, $exe) = @_;
    $exe = $self if(!(ref($self) || $exe));
    $exe .= '.exe' if(($^O =~ /mswin/i) && ($exe !~ /\.(exe|com|bat|cmd)$/i));
    return $exe if(-e $exe); # full path and exists

    # Ewan's comment. I don't think we need this. People should not be
    # asking for a program with a pathseparator starting it
    
    # $exe =~ s/^$PATHSEP//;

    # Not a full path, or does not exist. Let's see whether it's in the path.
    if($FILESPECLOADED) {
	foreach my $dir (File::Spec->path()) {
	    my $f = Bio::Root::IO->catfile($dir, $exe);	    
	    return $f if(-e $f && -x $f );
	}
    }    
    return 0;
}

#line 626

#'
sub tempfile {
    my ($self, @args) = @_;
    my ($tfh, $file);
    my %params = @args;

    # map between naming with and without dash
    foreach my $key (keys(%params)) {
	if( $key =~ /^-/  ) {
	    my $v = $params{$key};
	    delete $params{$key};
	    $params{uc(substr($key,1))} = $v;
	} else { 
	    # this is to upper case
	    my $v = $params{$key};
	    delete $params{$key};	    
	    $params{uc($key)} = $v;
	}
    }
    $params{'DIR'} = $TEMPDIR if(! exists($params{'DIR'}));
    unless (exists $params{'UNLINK'} && 
	    defined $params{'UNLINK'} &&
	    ! $params{'UNLINK'} ) {
	$params{'UNLINK'} = 1;
    } else { $params{'UNLINK'} = 0 }
	    
    if($FILETEMPLOADED) {
	if(exists($params{'TEMPLATE'})) {
	    my $template = $params{'TEMPLATE'};
	    delete $params{'TEMPLATE'};
	    ($tfh, $file) = File::Temp::tempfile($template, %params);
	} else {
	    ($tfh, $file) = File::Temp::tempfile(%params);
	}
    } else {
	my $dir = $params{'DIR'};
	$file = $self->catfile($dir,
			       (exists($params{'TEMPLATE'}) ?
				$params{'TEMPLATE'} :
				sprintf( "%s.%s.%s",  
					 $ENV{USER} || 'unknown', $$, 
					 $TEMPCOUNTER++)));

	# sneakiness for getting around long filenames on Win32?
	if( $HAS_WIN32 ) {
	    $file = Win32::GetShortPathName($file);
	}

	# taken from File::Temp
	if ($] < 5.006) {
	    $tfh = &Symbol::gensym;
	}    
	# Try to make sure this will be marked close-on-exec
	# XXX: Win32 doesn't respect this, nor the proper fcntl,
	#      but may have O_NOINHERIT. This may or may not be in Fcntl.
	local $^F = 2; 
	# Store callers umask
	my $umask = umask();
	# Set a known umaskr
	umask(066);
	# Attempt to open the file
	if ( sysopen($tfh, $file, $OPENFLAGS, 0600) ) {
	    # Reset umask
	    umask($umask); 
	} else { 
	    $self->throw("Could not open tempfile $file: $!\n");
	}
    }

    if(  $params{'UNLINK'} ) {
	push @{$self->{'_rootio_tempfiles'}}, $file;
    } 


    return wantarray ? ($tfh,$file) : $tfh;
}

#line 719

sub tempdir {
    my ( $self, @args ) = @_;
    if($FILETEMPLOADED && File::Temp->can('tempdir') ) {
	return File::Temp::tempdir(@args);
    }

    # we have to do this ourselves, not good
    #
    # we are planning to cleanup temp files no matter what
    my %params = @args;
    $self->{'_cleanuptempdir'} = ( defined $params{CLEANUP} && 
				   $params{CLEANUP} == 1);
    my $tdir = $self->catfile($TEMPDIR,
			      sprintf("dir_%s-%s-%s", 
				      $ENV{USER} || 'unknown', $$, 
				      $TEMPCOUNTER++));
    mkdir($tdir, 0755);
    push @{$self->{'_rootio_tempdirs'}}, $tdir; 
    return $tdir;
}

#line 761

sub catfile {
    my ($self, @args) = @_;

    return File::Spec->catfile(@args) if($FILESPECLOADED);
    # this is clumsy and not very appealing, but how do we specify the
    # root directory?
    if($args[0] eq '/') {
	$args[0] = $ROOTDIR;
    }
    return join($PATHSEP, @args);
}

#line 807

# taken straight from File::Path VERSION = "1.0403"
sub rmtree {
    my($self,$roots, $verbose, $safe) = @_;
    if( $FILEPATHLOADED ) { 
	return File::Path::rmtree ($roots, $verbose, $safe); 
    }				
    
    my $force_writeable = ($^O eq 'os2' || $^O eq 'dos' || $^O eq 'MSWin32'
		       || $^O eq 'amigaos');
    my $Is_VMS = $^O eq 'VMS';

    my(@files);
    my($count) = 0;
    $verbose ||= 0;
    $safe ||= 0;
    if ( defined($roots) && length($roots) ) {
	$roots = [$roots] unless ref $roots;
    } else {
	$self->warn("No root path(s) specified\n");
	return 0;
    }

    my($root);
    foreach $root (@{$roots}) {
	$root =~ s#/\z##;
	(undef, undef, my $rp) = lstat $root or next;
	$rp &= 07777;	# don't forget setuid, setgid, sticky bits
	if ( -d _ ) {
	    # notabene: 0777 is for making readable in the first place,
	    # it's also intended to change it to writable in case we have
	    # to recurse in which case we are better than rm -rf for 
	    # subtrees with strange permissions
	    chmod(0777, ($Is_VMS ? VMS::Filespec::fileify($root) : $root))
	      or $self->warn("Can't make directory $root read+writeable: $!")
		unless $safe;
	    if (opendir(DIR, $root) ){
		@files = readdir DIR;
		closedir(DIR);
	    } else {
	        $self->warn( "Can't read $root: $!");
		@files = ();
	    }

	    # Deleting large numbers of files from VMS Files-11 filesystems
	    # is faster if done in reverse ASCIIbetical order 
	    @files = reverse @files if $Is_VMS;
	    ($root = VMS::Filespec::unixify($root)) =~ s#\.dir\z## if $Is_VMS;
	    @files = map("$root/$_", grep $_!~/^\.{1,2}\z/s,@files);
	    $count += $self->rmtree([@files],$verbose,$safe);
	    if ($safe &&
		($Is_VMS ? !&VMS::Filespec::candelete($root) : !-w $root)) {
		print "skipped $root\n" if $verbose;
		next;
	    }
	    chmod 0777, $root
	      or $self->warn( "Can't make directory $root writeable: $!")
		if $force_writeable;
	    print "rmdir $root\n" if $verbose;
	    if (rmdir $root) {
		++$count;
	    }
	    else {
		$self->warn( "Can't remove directory $root: $!");
		chmod($rp, ($Is_VMS ? VMS::Filespec::fileify($root) : $root))
		    or $self->warn("and can't restore permissions to "
		            . sprintf("0%o",$rp) . "\n");
	    }
	}
	else {

	    if ($safe &&
		($Is_VMS ? !&VMS::Filespec::candelete($root)
		         : !(-l $root || -w $root)))
	    {
		print "skipped $root\n" if $verbose;
		next;
	    }
	    chmod 0666, $root
	      or $self->warn( "Can't make file $root writeable: $!")
		if $force_writeable;
	    print "unlink $root\n" if $verbose;
	    # delete all versions under VMS
	    for (;;) {
		unless (unlink $root) {
		    $self->warn( "Can't unlink file $root: $!");
		    if ($force_writeable) {
			chmod $rp, $root
			    or $self->warn("and can't restore permissions to "
			            . sprintf("0%o",$rp) . "\n");
		    }
		    last;
		}
		++$count;
		last unless $Is_VMS && lstat $root;
	    }
	}
    }

    $count;
}

#line 921

sub _flush_on_write {
    my ($self,$value) = @_;
    if( defined $value) {
	$self->{'_flush_on_write'} = $value;
    }
    return $self->{'_flush_on_write'};
}

1;
